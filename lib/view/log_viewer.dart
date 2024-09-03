import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../controller/log_file_controller.dart';
import '../controller/system_trey_controller.dart';

class LogViewer extends StatefulWidget {
  const LogViewer({super.key});

  @override
  _LogViewerState createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> with WindowListener {
  final LogFileController _logFileController = LogFileController();
  final SystemTrayController _systemTrayController = SystemTrayController();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _systemTrayController.initializeTray();
    _logFileController.readLogFile();
    _logFileController.startFileWatcher();
  }

  @override
  void dispose() {
    _logFileController.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Future<void> onWindowClose() async {
    await windowManager.setPreventClose(true);
    await windowManager.hide();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Viewer'),
        actions: [
          IconButton(
            onPressed: () {
              _systemTrayController.minimizeToTray();
            },
            icon: const Icon(Icons.minimize),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<String>>(
        valueListenable: _logFileController.logLines,
        builder: (context, logLines, child) {
          return ListView.builder(
            itemCount: logLines.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(logLines[index]),
              );
            },
          );
        },
      ),
    );
  }
}
