import 'dart:convert';
import 'dart:io';
import 'package:border_player/src/rust/api/system_theme.dart';
import 'package:border_player/utils.dart';
import 'package:flutter/material.dart';
import 'package:github/github.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';
import 'package:border_player/window_geometry.dart';
import 'package:border_player/windows_window_placement.dart';

/// 把旧的 app data 目录（如果存在）移到新的目录
/// 只在新 app data 目录没有数据时进行
/// 从 C:\Users\$username\AppData\Roaming\com.example\border_player 移到 C:\Users\$username\Documents\border_player
Future<void> migrateAppData() async {
  try {
    final newAppDataDir = await getAppDataDir();
    if (newAppDataDir.listSync().isNotEmpty) return;

    final oldAppDataDir = await getApplicationSupportDirectory();
    final oldDocumentsDir = Directory(
      path.join(
        (await getApplicationDocumentsDirectory()).path,
        "border_player",
      ),
    );
    final sourceDir =
        oldDocumentsDir.existsSync() ? oldDocumentsDir : oldAppDataDir;

    if (sourceDir.existsSync()) {
      final datas = sourceDir.listSync();
      for (var item in datas) {
        final oldDataFile = File(item.path);
        oldDataFile.copySync(
          path.join(newAppDataDir.path, path.basename(item.path)),
        );
      }
    }
  } catch (err, trace) {
    LOGGER.e(err, stackTrace: trace);
  }
}

Future<Directory> getAppDataDir() async {
  final dir = await getApplicationDocumentsDirectory();
  return Directory(
    path.join(dir.path, "Border Player"),
  ).create(recursive: true);
}

List<double>? _parseFiniteValues(String? value, int expectedLength) {
  if (value == null) return null;
  final parts = value.split(',').map(double.tryParse).toList();
  if (parts.length != expectedLength ||
      parts.any((part) => part == null || !part.isFinite)) {
    return null;
  }
  return parts.cast<double>();
}

Size? _parseSize(String? value) {
  final parts = _parseFiniteValues(value, 2);
  if (parts == null || parts[0] <= 0 || parts[1] <= 0) return null;
  return Size(parts[0], parts[1]);
}

Offset? _parseOffset(String? value) {
  final parts = _parseFiniteValues(value, 2);
  if (parts == null) return null;
  return Offset(parts[0], parts[1]);
}

Rect? _parseRect(String? value) {
  final parts = _parseFiniteValues(value, 4);
  if (parts == null || parts[2] <= 0 || parts[3] <= 0) return null;
  return Rect.fromLTWH(parts[0], parts[1], parts[2], parts[3]);
}

String _rectToString(Rect rect) =>
    "${rect.left.toStringAsFixed(1)},${rect.top.toStringAsFixed(1)},${rect.width.toStringAsFixed(1)},${rect.height.toStringAsFixed(1)}";

class AppSettings {
  static final github = GitHub();
  static const String version = "2.0.5";

  /// 主题模式：亮 / 暗
  ThemeMode themeMode = ThemeMode.light;

  /// 启动时 / 封面主题色不适合当主题时的主题
  int defaultTheme = const Color(0xFFE7C94E).toARGB32();

  /// 跟随歌曲封面的动态主题
  bool dynamicTheme = true;
  bool homeCoverBackdrop = true;

  /// 跟随系统主题色
  bool useSystemTheme = false;

  /// 跟随系统主题模式
  bool useSystemThemeMode = false;

  List artistSeparator = ["/", "、"];

  /// 歌词来源：true，本地优先；false，在线优先
  bool localLyricFirst = true;
  Size windowSize = const Size(1280, 756);
  Offset? windowPosition;
  String? windowDisplayId;
  String? windowDisplayName;
  Rect? windowDisplayWorkArea;
  Rect? windowPhysicalBounds;
  Rect? windowPhysicalWorkArea;
  String? windowPhysicalMonitorName;
  bool windowPhysicalBoundsAreVisible = false;
  bool isWindowMaximized = false;
  Future<void> _saveQueue = Future<void>.value();

  String? fontFamily = "Microsoft YaHei";
  String? fontPath;

  late String artistSplitPattern = artistSeparator.join("|");

  static final AppSettings _instance = AppSettings._();

  static AppSettings get instance => _instance;

  static ThemeMode getWindowsThemeMode() {
    final systemTheme = SystemTheme.getSystemTheme();

    final isDarkMode = (((5 * systemTheme.fore.$3) +
            (2 * systemTheme.fore.$2) +
            systemTheme.fore.$4) >
        (8 * 128));
    return isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  static int getWindowsTheme() {
    final systemTheme = SystemTheme.getSystemTheme();
    return Color.fromARGB(
      systemTheme.accent.$1,
      systemTheme.accent.$2,
      systemTheme.accent.$3,
      systemTheme.accent.$4,
    ).toARGB32();
  }

  AppSettings._();

  static Future<void> _readFromJsonOld(Map settingsMap) async {
    final ust = settingsMap["UseSystemTheme"];
    if (ust != null) {
      _instance.useSystemTheme = ust == 1 ? true : false;
    }

    final ustm = settingsMap["UseSystemThemeMode"];
    if (ustm != null) {
      _instance.useSystemThemeMode = ustm == 1 ? true : false;
    }

    if (!_instance.useSystemTheme) {
      _instance.defaultTheme = settingsMap["DefaultTheme"];
    }
    if (!_instance.useSystemThemeMode) {
      _instance.themeMode =
          settingsMap["ThemeMode"] == 0 ? ThemeMode.light : ThemeMode.dark;
    }

    _instance.dynamicTheme = settingsMap["DynamicTheme"] == 1 ? true : false;
    _instance.homeCoverBackdrop =
        settingsMap["HomeCoverBackdrop"] == 1 ? true : false;
    _instance.artistSeparator = settingsMap["ArtistSeparator"];
    _instance.artistSplitPattern = _instance.artistSeparator.join("|");

    final llf = settingsMap["LocalLyricFirst"];
    if (llf != null) {
      _instance.localLyricFirst = llf == 1 ? true : false;
    }

    final windowSize = _parseSize(settingsMap["WindowSize"]?.toString());
    if (windowSize != null) _instance.windowSize = windowSize;

    final isMaximized = settingsMap["IsWindowMaximized"];
    if (isMaximized != null) {
      _instance.isWindowMaximized = isMaximized == 1;
    }
  }

  static Future<void> readFromJson() async {
    try {
      final supportPath = (await getAppDataDir()).path;
      final settingsPath = "$supportPath\\settings.json";

      final settingsStr = File(settingsPath).readAsStringSync();
      Map settingsMap = json.decode(settingsStr);

      if (settingsMap["Version"] == null) {
        return _readFromJsonOld(settingsMap);
      }

      final ust = settingsMap["UseSystemTheme"];
      if (ust != null) {
        _instance.useSystemTheme = ust;
      }

      final ustm = settingsMap["UseSystemThemeMode"];
      if (ustm != null) {
        _instance.useSystemThemeMode = ustm;
      }

      if (!_instance.useSystemTheme) {
        _instance.defaultTheme = settingsMap["DefaultTheme"];
      }
      if (!_instance.useSystemThemeMode) {
        _instance.themeMode = (settingsMap["ThemeMode"] ?? false)
            ? ThemeMode.dark
            : ThemeMode.light;
      }

      final dt = settingsMap["DynamicTheme"];
      if (dt != null) {
        _instance.dynamicTheme = dt;
      }

      final hcb = settingsMap["HomeCoverBackdrop"];
      if (hcb != null) {
        _instance.homeCoverBackdrop = hcb;
      }

      final as = settingsMap["ArtistSeparator"];
      if (as != null) {
        _instance.artistSeparator = as;
        _instance.artistSplitPattern = _instance.artistSeparator.join("|");
      }

      final llf = settingsMap["LocalLyricFirst"];
      if (llf != null) {
        _instance.localLyricFirst = llf;
      }

      final windowSize = _parseSize(settingsMap["WindowSize"]?.toString());
      if (windowSize != null) _instance.windowSize = windowSize;

      final isMaximized = settingsMap["IsWindowMaximized"];
      if (isMaximized != null) {
        _instance.isWindowMaximized = isMaximized;
      }

      _instance.windowPosition =
          _parseOffset(settingsMap["WindowPosition"]?.toString());
      _instance.windowDisplayId = settingsMap["WindowDisplayId"]?.toString();
      _instance.windowDisplayName = settingsMap["WindowDisplayName"] as String?;
      _instance.windowDisplayWorkArea =
          _parseRect(settingsMap["WindowDisplayWorkArea"]?.toString());

      final physicalBoundsStr = settingsMap["WindowPhysicalBounds"] as String?;
      final physicalWorkAreaStr =
          settingsMap["WindowPhysicalWorkArea"] as String?;
      _instance.windowPhysicalBounds = _parseRect(physicalBoundsStr);
      _instance.windowPhysicalWorkArea = _parseRect(physicalWorkAreaStr);
      _instance.windowPhysicalMonitorName =
          settingsMap["WindowPhysicalMonitorName"] as String?;
      _instance.windowPhysicalBoundsAreVisible =
          settingsMap["WindowPhysicalBoundsAreVisible"] == true;

      final ff = settingsMap["FontFamily"];
      final fp = settingsMap["FontPath"];
      if (ff != null) {
        _instance.fontFamily = ff;
        _instance.fontPath = fp;
      }
    } catch (err, trace) {
      LOGGER.e(err, stackTrace: trace);
    }
  }

  Future<void> captureWindowGeometry() async {
    try {
      if (await windowManager.isMaximized() ||
          await windowManager.isFullScreen() ||
          await windowManager.isMinimized()) {
        return;
      }
      final bounds = await windowManager.getBounds();
      final displays = await screenRetriever.getAllDisplays();
      if (displays.isEmpty ||
          !hasMeaningfulVisibleArea(
            bounds,
            displays.map(displayWorkArea),
          )) {
        return;
      }
      windowSize = bounds.size;
      windowPosition = bounds.topLeft;

      final physicalPlacement = await captureWindowsWindowPlacement();
      if (physicalPlacement != null) {
        windowPhysicalBounds = physicalPlacement.bounds;
        windowPhysicalWorkArea = physicalPlacement.workArea;
        windowPhysicalMonitorName = physicalPlacement.monitorName;
        windowPhysicalBoundsAreVisible = physicalPlacement.usesVisibleBounds;
      }

      try {
        final display = displayForWindow(bounds, displays);
        if (display != null) {
          windowDisplayId = display.id.toString();
          windowDisplayName = display.name;
          windowDisplayWorkArea = displayWorkArea(display);
        }
      } catch (err, trace) {
        LOGGER.e(err, stackTrace: trace);
      }
    } catch (err, trace) {
      LOGGER.e(err, stackTrace: trace);
    }
  }

  Future<void> saveSettings() {
    final save = _saveQueue.then((_) => _saveSettingsNow());
    _saveQueue = save;
    return save;
  }

  Future<void> _saveSettingsNow() async {
    try {
      await captureWindowGeometry();
      final isMaximized = await windowManager.isMaximized();
      final settingsMap = {
        "Version": version,
        "ThemeMode": themeMode == ThemeMode.dark,
        "DynamicTheme": dynamicTheme,
        "HomeCoverBackdrop": homeCoverBackdrop,
        "UseSystemTheme": useSystemTheme,
        "UseSystemThemeMode": useSystemThemeMode,
        "DefaultTheme": defaultTheme,
        "ArtistSeparator": artistSeparator,
        "LocalLyricFirst": localLyricFirst,
        "IsWindowMaximized": isMaximized,
        "FontFamily": fontFamily,
        "FontPath": fontPath,
      };

      // 只有在窗口不是最大化且不是全屏时才保存窗口尺寸
      // 这样windowSize始终保存的是窗口化时的尺寸
      final sizeToSave = windowSize;
      settingsMap["WindowSize"] =
          "${sizeToSave.width.toStringAsFixed(1)},${sizeToSave.height.toStringAsFixed(1)}";
      final positionToSave = windowPosition;
      if (positionToSave != null) {
        settingsMap["WindowPosition"] =
            "${positionToSave.dx.toStringAsFixed(1)},${positionToSave.dy.toStringAsFixed(1)}";
      }
      settingsMap["WindowDisplayId"] = windowDisplayId;
      settingsMap["WindowDisplayName"] = windowDisplayName;
      final workArea = windowDisplayWorkArea;
      if (workArea != null) {
        settingsMap["WindowDisplayWorkArea"] =
            "${workArea.left.toStringAsFixed(1)},${workArea.top.toStringAsFixed(1)},${workArea.width.toStringAsFixed(1)},${workArea.height.toStringAsFixed(1)}";
      }
      final physicalBounds = windowPhysicalBounds;
      final physicalWorkArea = windowPhysicalWorkArea;
      if (physicalBounds != null) {
        settingsMap["WindowPhysicalBounds"] = _rectToString(physicalBounds);
      }
      if (physicalWorkArea != null) {
        settingsMap["WindowPhysicalWorkArea"] = _rectToString(physicalWorkArea);
      }
      settingsMap["WindowPhysicalMonitorName"] = windowPhysicalMonitorName;
      settingsMap["WindowPhysicalBoundsAreVisible"] =
          windowPhysicalBoundsAreVisible;

      final settingsStr = json.encode(settingsMap);
      final supportPath = (await getAppDataDir()).path;
      final settingsPath = "$supportPath\\settings.json";
      final output = await File(settingsPath).create(recursive: true);
      await output.writeAsString(settingsStr, flush: true);
    } catch (err, trace) {
      LOGGER.e(err, stackTrace: trace);
    }
  }
}
