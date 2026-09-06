import 'dart:io';

import 'package:border_player/app_lifecycle.dart';
import 'package:border_player/app_preference.dart';
import 'package:border_player/app_settings.dart';
import 'package:border_player/entry.dart';
import 'package:border_player/hotkeys_helper.dart';
import 'package:border_player/src/rust/api/logger.dart';
import 'package:border_player/src/rust/frb_generated.dart';
import 'package:border_player/theme_provider.dart';
import 'package:border_player/utils.dart';
import 'package:border_player/window_geometry.dart';
import 'package:border_player/windows_window_placement.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

Future<void> initWindow() async {
  await windowManager.ensureInitialized();

  final settings = AppSettings.instance;
  var initialWindowSize = settings.windowSize;
  try {
    final primaryDisplay = await screenRetriever.getPrimaryDisplay();
    initialWindowSize = constrainWindowSizeToWorkArea(
      initialWindowSize,
      displayWorkArea(primaryDisplay),
    );
  } catch (err, trace) {
    LOGGER.e(err, stackTrace: trace);
  }

  WindowOptions windowOptions = WindowOptions(
    minimumSize: minimumAppWindowSize,
    size: initialWindowSize,
    center: AppSettings.instance.windowPosition == null &&
        AppSettings.instance.windowPhysicalBounds == null,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    var restored = false;
    final physicalBounds = settings.windowPhysicalBounds;
    final physicalWorkArea = settings.windowPhysicalWorkArea;
    final physicalMonitorName = settings.windowPhysicalMonitorName;
    if (physicalBounds != null &&
        physicalWorkArea != null &&
        physicalMonitorName != null) {
      try {
        restored = await restoreWindowsWindowPlacement(
          savedBounds: physicalBounds,
          savedWorkArea: physicalWorkArea,
          savedMonitorName: physicalMonitorName,
          savedBoundsAreVisible: settings.windowPhysicalBoundsAreVisible,
        );
      } catch (err, trace) {
        LOGGER.e(err, stackTrace: trace);
      }
    }

    final savedPosition = settings.windowPosition;
    if (!restored && savedPosition != null) {
      try {
        final displays = await screenRetriever.getAllDisplays();
        final primaryDisplay = await screenRetriever.getPrimaryDisplay();
        final restoredBounds = safeRestoredWindowBounds(
          savedBounds: savedPosition & settings.windowSize,
          displays: displays,
          primaryDisplay: primaryDisplay,
          savedDisplayId: settings.windowDisplayId,
          savedDisplayName: settings.windowDisplayName,
          savedDisplayWorkArea: settings.windowDisplayWorkArea,
        );
        await windowManager.setBounds(restoredBounds);
        restored = true;
      } catch (err, trace) {
        LOGGER.e(err, stackTrace: trace);
      }
    }
    if (!restored &&
        (physicalBounds != null || settings.windowPosition != null)) {
      await windowManager.center();
    }
    await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
    final isMaximized = AppSettings.instance.isWindowMaximized;
    if (isMaximized) {
      await windowManager.maximize();
    }
    await windowManager.show();

    // Moving an initially hidden window between monitors can trigger a final
    // WM_DPICHANGED adjustment when it becomes visible. Wait for that native
    // transition, then reapply the saved physical rectangle exactly once.
    if (!isMaximized &&
        physicalBounds != null &&
        physicalWorkArea != null &&
        physicalMonitorName != null) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      try {
        await restoreWindowsWindowPlacement(
          savedBounds: physicalBounds,
          savedWorkArea: physicalWorkArea,
          savedMonitorName: physicalMonitorName,
          savedBoundsAreVisible: settings.windowPhysicalBoundsAreVisible,
        );
      } catch (err, trace) {
        LOGGER.e(err, stackTrace: trace);
      }
    }

    // Start move/resize persistence only after startup placement is final, so
    // transient DPI coordinates cannot overwrite the saved geometry.
    await AppLifecycle.instance.init();
    await windowManager.focus();
  });
}

Future<void> loadPrefFont() async {
  final settings = AppSettings.instance;
  if (settings.fontFamily != null) {
    if (settings.fontPath == null) {
      ThemeProvider.instance.changeFontFamily(settings.fontFamily);
      return;
    }
    try {
      final fontLoader = FontLoader(settings.fontFamily!);

      fontLoader.addFont(
        File(settings.fontPath!).readAsBytes().then((value) {
          return ByteData.sublistView(value);
        }),
      );
      await fontLoader.load();
      ThemeProvider.instance.changeFontFamily(settings.fontFamily!);
    } catch (err, trace) {
      LOGGER.e(err, stackTrace: trace);
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RustLib.init();

  initRustLogger().listen((msg) {
    LOGGER.i("[rs]: $msg");
  });

  // For hot reload, `unregisterAll()` needs to be called.
  await HotkeysHelper.unregisterAll();
  await HotkeysHelper.registerHotKeys();

  await migrateAppData();

  final supportPath = (await getAppDataDir()).path;
  if (File("$supportPath\\settings.json").existsSync()) {
    await AppSettings.readFromJson();
    await loadPrefFont();
  }
  if (File("$supportPath\\app_preference.json").existsSync()) {
    await AppPreference.read();
  }
  final welcome = !File("$supportPath\\index.json").existsSync();

  await initWindow();

  runApp(Entry(welcome: welcome));
}
