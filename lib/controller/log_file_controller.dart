import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:watcher/watcher.dart';
import 'package:ntp/ntp.dart';
import '../model/log_entry_model.dart';
import '../service/firebase_service.dart';
import '../utility/file_utils.dart';

class LogFileController {
  static const int maxFileSize = 30 * 1024 * 1024;
  StreamSubscription? _fileWatcherSubscription;
  final ValueNotifier<List<String>> logLines = ValueNotifier([]);
  late String logFilePath;
  late String jsonDirectoryPath;
  late String jsonFilePath;
  late String userId;
  String? currentLogDate;
  int fileIndex = 1;
  final FirebaseService _firebaseService = FirebaseService();

  LogFileController() {
    userId = Platform.localHostname;
    logFilePath = FileUtils.determineLogFilePath();
    jsonDirectoryPath = FileUtils.determineJsonDirectoryPath(userId);
    _createLogDirectory();
    currentLogDate = _getCurrentDateStringSync();
    _initializeJsonFile();
  }

  void _initializeJsonFile() {
    final existingFiles = Directory(jsonDirectoryPath)
        .listSync()
        .where((entity) => entity is File && entity.path.contains(currentLogDate!))
        .toList();
    
    if (existingFiles.isNotEmpty) {
      existingFiles.sort((a, b) => a.path.compareTo(b.path));
      final lastFile = existingFiles.last;
      fileIndex = _getFileIndexFromName(lastFile.path) + 1;
      jsonFilePath = lastFile.path;

      if (File(jsonFilePath).lengthSync() >= maxFileSize) {
        fileIndex++;
        jsonFilePath = FileUtils.determineJsonFilePath(jsonDirectoryPath, currentLogDate, fileIndex);
      }
    } else {
      jsonFilePath = FileUtils.determineJsonFilePath(jsonDirectoryPath, currentLogDate, fileIndex);
      File(jsonFilePath).createSync(recursive: true);
    }
  }

  int _getFileIndexFromName(String filePath) {
    final regex = RegExp(r'_(\d+)\.json$');
    final match = regex.firstMatch(filePath);
    return match != null ? int.parse(match.group(1)!) : 1;
  }

  String _getCurrentDateStringSync() {
    final now = DateTime.now();
    return '${now.day}-${now.month}-${now.year}';
  }

  void _createLogDirectory() {
    final directory = Directory(jsonDirectoryPath);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
  }

  Future<void> readLogFile() async {
    try {
      final file = File(logFilePath);
      if (await file.exists()) {
        final List<int> fileBytes = await file.readAsBytes();

        if (fileBytes.isNotEmpty && fileBytes.any((byte) => byte != 0)) {
          String fileContent = utf8.decode(fileBytes, allowMalformed: true);

          final lines = fileContent
              .split('\n')
              .where((line) => line.trim().isNotEmpty && !line.contains('\u0000'))
              .toList();

          logLines.value = lines.reversed.toList();

          final newLogDate = _getCurrentDateStringSync();
          final jsonFile = File(jsonFilePath);
          if (currentLogDate != newLogDate || await jsonFile.length() >= maxFileSize) {
            if (currentLogDate != newLogDate) {
              fileIndex = 1;
            } else {
              fileIndex++;
            }
            await _manageLogFileTransition(newLogDate);
            currentLogDate = newLogDate;
            jsonFilePath = FileUtils.determineJsonFilePath(jsonDirectoryPath, currentLogDate, fileIndex);
          }

          await _appendLogEntriesToJson(lines);
          await _uploadLogEntriesToFirebase(lines);
        } else {
          logLines.value = ['Log file is empty or contains only null characters.'];
        }
      } else {
        await file.create(recursive: true);
        logLines.value = ['Log file created.'];
      }
    } catch (e) {
      logLines.value = ['Error reading log file: $e'];
    }
  }

  Future<void> _clearLogFile() async {
    final file = File(logFilePath);
    await file.writeAsString('');
  }

  Future<void> _appendLogEntriesToJson(List<String> lines) async {
    try {
      final file = File(jsonFilePath);
      List<LogEntry> entries = [];
      final timestamp = await _fetchServerTimestamp();
      final formattedTimestamp = _formatTimestamp(timestamp);

      if (!await file.exists()) {
        await file.create(recursive: true);
      }

      if (await file.exists()) {
        final contents = await file.readAsString();

        if (contents.trim().isNotEmpty) {
          try {
            List<dynamic> jsonData = jsonDecode(contents);
            entries = jsonData.map((data) => LogEntry.fromJson(data)).toList();
          } catch (e) {
            print('Error decoding JSON: $e');
          }
        }
      }

      final existingLogLines = entries.map((entry) => entry.line).toSet();
      final newLogLines = lines.where((line) => !existingLogLines.contains(line)).toList();

      for (var line in newLogLines) {
        entries.add(LogEntry(line: line, timestamp: formattedTimestamp, userId: userId));
      }

      final jsonString = jsonEncode(entries.map((entry) => entry.toJson()).toList());
      await file.writeAsString(jsonString);
    } catch (e) {
      print('Error writing to JSON file: $e');
    }
  }

  Future<void> _uploadLogEntriesToFirebase(List<String> lines) async {
    final timestamp = await _fetchServerTimestamp();
    final formattedTimestamp = _formatTimestamp(timestamp);
    final logDate = currentLogDate ?? _getCurrentDateStringSync();
    List<LogEntry> entries = lines.map((line) => LogEntry(line: line, timestamp: formattedTimestamp, userId: userId)).toList();

    await _firebaseService.uploadLogEntries(userId, logDate, entries);

    // Remove uploaded entries from the JSON file
    await _removeUploadedEntriesFromJson(entries);
  }

  Future<void> _removeUploadedEntriesFromJson(List<LogEntry> uploadedEntries) async {
    final file = File(jsonFilePath);
    if (!await file.exists()) return;

    final contents = await file.readAsString();
    if (contents.trim().isEmpty) return;

    List<dynamic> jsonData = jsonDecode(contents);
    List<LogEntry> allEntries = jsonData.map((data) => LogEntry.fromJson(data)).toList();

    // Remove uploaded entries
    allEntries.removeWhere((entry) => uploadedEntries.any((uploaded) => uploaded.line == entry.line));

    final jsonString = jsonEncode(allEntries.map((entry) => entry.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  Future<void> _manageLogFileTransition(String newLogDate) async {
    final previousJsonFilePath = FileUtils.determineJsonFilePath(jsonDirectoryPath, currentLogDate, fileIndex);
    final currentFile = File(logFilePath);

    if (await File(previousJsonFilePath).exists()) {
      final previousEntries = await _loadLogEntriesFromJson(previousJsonFilePath);

      if (await currentFile.exists()) {
        final lines = await currentFile.readAsLines();
        final existingLogLines = previousEntries.map((entry) => entry.line).toSet();

        final isLogDataAlreadyInJson = lines.every((line) => existingLogLines.contains(line));

        if (isLogDataAlreadyInJson) {
          await _clearLogFile();
        } else {
          final splitIndex = lines.indexWhere((line) => !_isLogFromDate(line, newLogDate));

          if (splitIndex > 0) {
            final previousDayLogs = lines.sublist(0, splitIndex);
            final currentDayLogs = lines.sublist(splitIndex);

            await _appendLogEntriesToJson(previousDayLogs);
            await _uploadLogEntriesToFirebase(previousDayLogs);

            await _clearLogFile();
            await File(logFilePath).writeAsString(currentDayLogs.join('\n'));
          }
        }
      }
    }
  }

  bool _isLogFromDate(String logLine, String date) {
    return logLine.contains(date);
  }

  Future<List<LogEntry>> _loadLogEntriesFromJson(String jsonFilePath) async {
    try {
      final file = File(jsonFilePath);
      if (await file.exists()) {
        final contents = await file.readAsString();
        List<dynamic> jsonData = jsonDecode(contents);
        return jsonData.map((data) => LogEntry.fromJson(data)).toList();
      }
    } catch (e) {
      print('Error loading JSON entries: $e');
    }
    return [];
  }

  Future<int> _fetchServerTimestamp() async {
    try {
      DateTime now = await NTP.now();
      return now.millisecondsSinceEpoch;
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch;
    }
  }

  String _formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }

  void startFileWatcher() {
    final fileWatcher = FileWatcher(logFilePath);

    _fileWatcherSubscription = fileWatcher.events.listen((event) {
      if (event.type == ChangeType.MODIFY) {
        readLogFile();
      }
    });
  }

  void dispose() {
    _fileWatcherSubscription?.cancel();
  }
}
