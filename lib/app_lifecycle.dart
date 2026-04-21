import 'dart:io';

import 'package:border_player/app_preference.dart';
import 'package:border_player/app_settings.dart';
import 'package:border_player/hotkeys_helper.dart';
import 'package:border_player/library/playlist.dart';
import 'package:border_player/lyric/lyric_source.dart';
import 'package:border_player/play_service/play_service.dart';
import 'package:window_manager/window_manager.dart';

class AppLifecycle with WindowListener {
  AppLifecycle._();

  static final instance = AppLifecycle._();

  bool _isClosing = false;

  Future<void> init() async {
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);
  }

  Future<void> close() async {
    if (_isClosing) return;
    _isClosing = true;

    PlayService.instance.close();
    await AppSettings.instance.saveSettings();
    await AppPreference.instance.save();

    await Future.wait([
      savePlaylists(),
      saveLyricSources(),
      HotkeysHelper.unregisterAll(),
    ]);

    windowManager.removeListener(this);
    await windowManager.setPreventClose(false);
    exit(0);
  }

  @override
  Future<void> onWindowClose() => close();
}
