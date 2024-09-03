import 'dart:io';

import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

class SystemTrayController {
  final SystemTray systemTray = SystemTray();

  Future<void> initializeTray() async {
    String path = Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png';

    try {
      await systemTray.initSystemTray(
        title: "Log Viewer",
        iconPath: path,
      );

      final Menu menu = Menu();
      await menu.buildFrom([
        MenuItemLabel(label: 'Show', onClicked: (menuItem) => _showWindow()),
        MenuItemLabel(label: 'Exit', onClicked: (menuItem) => _exitApp()),
      ]);

      await systemTray.setContextMenu(menu);

      systemTray.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick) {
          _showWindow();
        }
      });
    } catch (e) {
      print('Error initializing system tray: $e');
    }
  }

  void _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  void minimizeToTray() async {
    await windowManager.hide();
  }

  void _exitApp() async {
    await windowManager.destroy();
  }
}
