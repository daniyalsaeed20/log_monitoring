import 'dart:io';

class FileUtils {
  static String determineLogFilePath() {
    final homeDirectory = Platform.environment['USERPROFILE'];
    if (homeDirectory != null) {
      return '$homeDirectory\\AppData\\Local\\MicroSIP\\MicroSIP_log.txt';
    } else {
      throw Exception('Unable to determine the user profile path.');
    }
  }

  static String determineJsonDirectoryPath(String userId) {
    final homeDirectory = Platform.environment['USERPROFILE'];
    if (homeDirectory != null) {
      return '$homeDirectory\\AppData\\Local\\$userId-Logs';
    } else {
      throw Exception('Unable to determine the user profile path.');
    }
  }

  static String determineJsonFilePath(
      String jsonDirectoryPath, String? date, int index) {
    return '$jsonDirectoryPath\\${date ?? ""}_File_$index.json';
  }
}
