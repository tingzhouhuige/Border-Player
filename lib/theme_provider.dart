import 'package:border_player/app_settings.dart';
import 'package:border_player/library/audio_library.dart';
import 'package:border_player/page/now_playing_page/page.dart';
import 'package:border_player/play_service/play_service.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class ThemeProvider extends ChangeNotifier {
  ColorScheme lightScheme = _baseLightScheme(
    Color(AppSettings.instance.defaultTheme),
  );

  ColorScheme darkScheme = _baseDarkScheme(
    Color(AppSettings.instance.defaultTheme),
  );

  String? fontFamily = AppSettings.instance.fontFamily;

  ColorScheme get currScheme =>
      themeMode == ThemeMode.dark ? darkScheme : lightScheme;

  ThemeMode themeMode = AppSettings.instance.themeMode;
  int _audioAccentRequestId = 0;
  String? _audioAccentPath;
  Brightness? _audioAccentBrightness;
  bool _pendingThemeNotification = false;

  static ThemeProvider? _instance;

  ThemeProvider._();

  static ThemeProvider get instance {
    _instance ??= ThemeProvider._();
    return _instance!;
  }

  static ColorScheme _baseLightScheme(Color seedColor) {
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      primary: const Color(0xFFE6AE22),
      onPrimary: const Color(0xFF302600),
      surface: const Color(0xFFFFFEFA),
      surfaceContainer: const Color(0xFFFFFBF4),
      secondaryContainer: const Color(0xFFFFF8DF),
      onSurface: const Color(0xFF2E2A22),
      onSurfaceVariant: const Color(0xFF6F695D),
      onSecondaryContainer: const Color(0xFF3C3727),
    );
  }

  static ColorScheme _baseDarkScheme(Color seedColor) {
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
  }

  ColorScheme _baseSchemeFor(Brightness brightness) {
    final seedColor = Color(AppSettings.instance.defaultTheme);
    return brightness == Brightness.dark
        ? _baseDarkScheme(seedColor)
        : _baseLightScheme(seedColor);
  }

  ColorScheme _copyAccentOnly({
    required ColorScheme base,
    required ColorScheme accent,
  }) {
    final isLight = base.brightness == Brightness.light;
    final primaryBlend = isLight ? 0.82 : 0.72;
    final secondaryBlend = isLight ? 0.58 : 0.58;
    final primaryContainerBlend = isLight ? 0.68 : 0.48;
    final secondaryContainerBlend = isLight ? 0.58 : 0.38;
    final tertiaryContainerBlend = isLight ? 0.42 : 0.42;
    final brightener = isLight ? Colors.white : Colors.black;
    final primaryContainer = Color.lerp(
      base.secondaryContainer,
      accent.primaryContainer,
      primaryContainerBlend,
    )!;
    final controlSurface = Color.lerp(
      base.surfaceContainer,
      accent.primaryContainer,
      isLight ? 0.08 : 0.18,
    )!;
    final secondaryContainer = Color.lerp(
      base.surfaceContainer,
      accent.primaryContainer,
      secondaryContainerBlend,
    )!;
    final tertiaryContainer = Color.lerp(
      base.tertiaryContainer,
      accent.tertiaryContainer,
      tertiaryContainerBlend,
    )!;

    return base.copyWith(
      primary: Color.lerp(base.primary, accent.primary, primaryBlend)!,
      onPrimary: base.onPrimary,
      surfaceContainer: Color.lerp(
        controlSurface,
        brightener,
        isLight ? 0.30 : 0.08,
      )!,
      primaryContainer: Color.lerp(
        primaryContainer,
        brightener,
        isLight ? 0.16 : 0.08,
      )!,
      onPrimaryContainer: base.onPrimaryContainer,
      secondary: Color.lerp(base.secondary, accent.secondary, secondaryBlend)!,
      onSecondary: base.onSecondary,
      secondaryContainer: Color.lerp(
        secondaryContainer,
        brightener,
        isLight ? 0.14 : 0.08,
      )!,
      onSecondaryContainer: base.onSecondaryContainer,
      tertiary: Color.lerp(base.tertiary, accent.tertiary, secondaryBlend)!,
      onTertiary: base.onTertiary,
      tertiaryContainer: Color.lerp(
        tertiaryContainer,
        brightener,
        isLight ? 0.14 : 0.08,
      )!,
      onTertiaryContainer: base.onTertiaryContainer,
      outline: Color.lerp(base.outline, accent.outline, isLight ? 0.20 : 0.32)!,
      outlineVariant: Color.lerp(
        base.outlineVariant,
        accent.outlineVariant,
        isLight ? 0.16 : 0.28,
      )!,
    );
  }

  void _notifyThemeChanged() {
    notifyListeners();

    PlayService.instance.desktopLyricService.canSendMessage.then((canSend) {
      if (!canSend) return;

      PlayService.instance.desktopLyricService.sendThemeMessage(currScheme);
    });
  }

  void notifyShellChanged() {
    notifyListeners();
  }

  void applyTheme({required Color seedColor}) {
    _audioAccentPath = null;
    _audioAccentBrightness = null;
    lightScheme = _baseLightScheme(seedColor);
    darkScheme = _baseDarkScheme(seedColor);
    if (AppSettings.instance.dynamicTheme &&
        PlayService.instance.playbackService.nowPlaying != null) {
      applyThemeFromAudio(PlayService.instance.playbackService.nowPlaying!);
      return;
    }
    _notifyThemeChanged();
  }

  /// 应用从 image 生成的主题。只在 themeMode == this.themeMode 时通知改变。
  void applyThemeFromImage(ImageProvider image, ThemeMode themeMode) {
    final brightness = switch (themeMode) {
      ThemeMode.system => Brightness.light,
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
    };

    ColorScheme.fromImageProvider(
      provider: image,
      brightness: brightness,
    ).then(
      (value) {
        switch (brightness) {
          case Brightness.light:
            lightScheme = value;
            break;
          case Brightness.dark:
            darkScheme = value;
            break;
        }

        if (themeMode == this.themeMode) {
          notifyListeners();
          PlayService.instance.desktopLyricService.canSendMessage
              .then((canSend) {
            if (!canSend) return;

            PlayService.instance.desktopLyricService
                .sendThemeMessage(currScheme);
          });
        }
      },
    );
  }

  void applyThemeMode(ThemeMode themeMode) {
    this.themeMode = themeMode;
    notifyListeners();
    _updateWindowBackground();
    PlayService.instance.desktopLyricService.canSendMessage.then((canSend) {
      if (!canSend) return;

      PlayService.instance.desktopLyricService.sendThemeMessage(currScheme);
      PlayService.instance.desktopLyricService.sendThemeModeMessage(
        themeMode == ThemeMode.dark,
      );
    });

    if (AppSettings.instance.dynamicTheme &&
        PlayService.instance.playbackService.nowPlaying != null) {
      applyThemeFromAudio(PlayService.instance.playbackService.nowPlaying!);
    }
  }

  void _updateWindowBackground() {
    final color = currScheme.surface;
    windowManager.setBackgroundColor(color);
  }

  void resetAudioAccentTheme() {
    _audioAccentRequestId++;
    _audioAccentPath = null;
    _audioAccentBrightness = null;
    lightScheme = _baseLightScheme(Color(AppSettings.instance.defaultTheme));
    darkScheme = _baseDarkScheme(Color(AppSettings.instance.defaultTheme));
    _notifyThemeChanged();
  }

  void setDynamicAudioAccentEnabled(bool enabled) {
    if (enabled) {
      final audio = PlayService.instance.playbackService.nowPlaying;
      if (audio != null) {
        applyThemeFromAudio(audio);
      }
      return;
    }

    resetAudioAccentTheme();
  }

  void applyThemeFromAudio(Audio audio) {
    if (!AppSettings.instance.dynamicTheme) return;

    final brightness = switch (themeMode) {
      ThemeMode.system => Brightness.light,
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
    };
    if (_audioAccentPath == audio.path &&
        _audioAccentBrightness == brightness) {
      return;
    }

    final requestId = ++_audioAccentRequestId;
    _audioAccentPath = audio.path;
    _audioAccentBrightness = brightness;
    audio.coverScheme(brightness).then((accentScheme) {
      if (requestId != _audioAccentRequestId) return;
      if (accentScheme == null) {
        resetAudioAccentTheme();
        return;
      }

      final base = _baseSchemeFor(brightness);
      final merged = _copyAccentOnly(
        base: base,
        accent: accentScheme,
      );

      switch (brightness) {
        case Brightness.light:
          lightScheme = merged;
          break;
        case Brightness.dark:
          darkScheme = merged;
          break;
      }

      if (NowPlayingPage.isVisible) {
        _pendingThemeNotification = true;
        return;
      }
      _notifyThemeChanged();
    });
  }

  void flushPendingThemeNotification() {
    if (!_pendingThemeNotification) return;
    _pendingThemeNotification = false;
    _notifyThemeChanged();
  }

  void changeFontFamily(String? fontFamily) {
    this.fontFamily = fontFamily;
    notifyListeners();
  }
}
