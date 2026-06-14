// ignore_for_file: camel_case_types

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:border_player/app_preference.dart';
import 'package:border_player/app_motion.dart';
import 'package:border_player/component/title_bar.dart';
import 'package:border_player/utils.dart';
import 'package:border_player/library/audio_library.dart';
import 'package:border_player/component/responsive_builder.dart';
import 'package:border_player/page/now_playing_page/component/current_playlist_view.dart';
import 'package:border_player/page/now_playing_page/component/filled_icon_button_style.dart';
import 'package:border_player/page/now_playing_page/component/now_playing_popup.dart';
import 'package:border_player/page/now_playing_page/component/vertical_lyric_view.dart';
import 'package:border_player/page/now_playing_page/now_playing_render_phase.dart';
import 'package:border_player/app_paths.dart' as app_paths;
import 'package:border_player/play_service/play_service.dart';
import 'package:border_player/play_service/playback_service.dart';
import 'package:border_player/src/bass/bass_player.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

part 'small_page.dart';
part 'large_page.dart';

const double _largeTitleBlockHeight = 50.0;
const double _largePageTopGap = 76.0;

enum NowPlayingViewMode {
  onlyMain,
  withLyric,
  withPlaylist;

  static NowPlayingViewMode? fromString(String nowPlayingViewMode) {
    for (var value in NowPlayingViewMode.values) {
      if (value.name == nowPlayingViewMode) return value;
    }
    return null;
  }
}

final NOW_PLAYING_VIEW_MODE = ValueNotifier(
  AppPreference.instance.nowPlayingPagePref.nowPlayingViewMode,
);

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({super.key});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  final playbackService = PlayService.instance.playbackService;
  ImageProvider<Object>? nowPlayingCover;
  ColorScheme? nowPlayingScheme;
  int _coverRequestId = 0;
  bool _didRequestInitialCover = false;
  String? _coverPath;
  Brightness? _coverBrightness;
  int _visualPrecacheRequestId = 0;
  late final Timer _cacheCleanupTimer;

  void updateCover() async {
    final audio = playbackService.nowPlaying;
    final brightness = Theme.of(context).brightness;
    if (_coverPath == audio?.path && _coverBrightness == brightness) return;

    final requestId = ++_coverRequestId;
    _coverPath = audio?.path;
    _coverBrightness = brightness;

    if (audio == null) {
      setState(() {
        nowPlayingCover = null;
        nowPlayingScheme = null;
      });
      return;
    }

    final cover = await audio.cover;
    final scheme = cover == null ? null : await audio.coverScheme(brightness);
    if (!mounted || requestId != _coverRequestId) return;

    setState(() {
      nowPlayingCover = cover;
      nowPlayingScheme = scheme;
    });
    _scheduleNextVisualPrecache();
  }

  void _scheduleNextVisualPrecache() {
    final requestId = ++_visualPrecacheRequestId;

    Future<void>.delayed(const Duration(milliseconds: 300), () async {
      if (!mounted || requestId != _visualPrecacheRequestId) return;

      final audio = playbackService.nextAudioForPreload;
      if (audio == null) return;

      try {
        final cover = await audio.largeCover;
        if (!mounted ||
            requestId != _visualPrecacheRequestId ||
            cover == null) {
          return;
        }

        playbackService.retainPreloadedLargeCover(audio);
        await precacheImage(cover, context);
      } catch (_) {
        audio.evictLargeCover();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    playbackService.addListener(updateCover);
    _cacheCleanupTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      imageCache.clearLiveImages();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRequestInitialCover) return;
    _didRequestInitialCover = true;
    updateCover();
  }

  @override
  void dispose() {
    _cacheCleanupTimer.cancel();
    _visualPrecacheRequestId++;
    playbackService.removeListener(updateCover);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final scheme = theme.colorScheme;
    final contentTheme = theme.copyWith(
      colorScheme: nowPlayingScheme ?? scheme,
    );

    return NowPlayingRenderPhase(
      heavyVisualsReady: true,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: AnimatedTheme(
            data: contentTheme,
            duration: const Duration(milliseconds: 360),
            curve: AppMotion.enter,
            child: const _NowPlayingTopBar(),
          ),
        ),
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          alignment: AlignmentDirectional.center,
          children: [
            _NowPlayingBackdrop(
              cover: nowPlayingCover,
              scheme: nowPlayingScheme ?? scheme,
              brightness: brightness,
            ),
            ChangeNotifierProvider.value(
              value: PlayService.instance.playbackService,
              builder: (context, _) {
                return AnimatedTheme(
                  data: contentTheme,
                  duration: const Duration(milliseconds: 360),
                  curve: AppMotion.enter,
                  child: ResponsiveBuilder2(builder: (context, screenType) {
                    switch (screenType) {
                      case ScreenType.small:
                        return const _NowPlayingPage_Small();
                      case ScreenType.medium:
                      case ScreenType.large:
                        return const _NowPlayingPage_Large();
                    }
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NowPlayingTopBar extends StatelessWidget {
  const _NowPlayingTopBar();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              NavBackBtn(),
              Expanded(child: DragToMoveArea(child: SizedBox.expand())),
              WindowControlls(),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 8,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeUpDown,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) => windowManager.startResizing(ResizeEdge.top),
            ),
          ),
        ),
      ],
    );
  }
}

class _CachedBackdropLayer extends StatefulWidget {
  const _CachedBackdropLayer({
    required this.imageProvider,
    required this.sigma,
    required this.scale,
  });

  final ImageProvider<Object>? imageProvider;
  final double sigma;
  final double scale;

  @override
  State<_CachedBackdropLayer> createState() => _CachedBackdropLayerState();
}

class _CachedBackdropLayerState extends State<_CachedBackdropLayer> {
  ui.Image? _cachedBlur;
  ImageProvider<Object>? _currentProvider;

  @override
  void didUpdateWidget(_CachedBackdropLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageProvider != _currentProvider) {
      _currentProvider = widget.imageProvider;
      _rebuildCache();
    }
  }

  Future<void> _rebuildCache() async {
    final provider = widget.imageProvider;
    if (provider == null) {
      setState(() {
        _cachedBlur?.dispose();
        _cachedBlur = null;
      });
      return;
    }

    final imageStream = provider.resolve(const ImageConfiguration());
    final completer = Completer<ui.Image>();
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!completer.isCompleted) completer.complete(info.image);
        imageStream.removeListener(listener);
      },
      onError: (_, __) {
        if (!completer.isCompleted) completer.completeError('failed');
        imageStream.removeListener(listener);
      },
    );
    imageStream.addListener(listener);

    ui.Image sourceImage;
    try {
      sourceImage = await completer.future;
    } catch (_) {
      return;
    }

    if (_currentProvider != provider || !mounted) {
      sourceImage.dispose();
      return;
    }

    final cached = await _preBlur(sourceImage, widget.sigma, widget.scale);
    sourceImage.dispose();

    if (_currentProvider != provider || !mounted) {
      cached?.dispose();
      return;
    }

    setState(() {
      _cachedBlur?.dispose();
      _cachedBlur = cached;
    });
  }

  static Future<ui.Image?> _preBlur(
      ui.Image source, double sigma, double scale) async {
    const targetWidth = 480;
    final aspectRatio = source.height / source.width;
    final targetHeight = (targetWidth * aspectRatio).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
    );

    final sx = targetWidth / source.width;
    final sy = targetHeight / source.height;
    canvas.scale(sx, sy);
    canvas.scale(scale);

    final paint = Paint()
      ..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
    canvas.drawImage(source, Offset.zero, paint);

    final picture = recorder.endRecording();
    return picture.toImage(targetWidth, targetHeight);
  }

  @override
  void dispose() {
    _cachedBlur?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedBlur == null) return const SizedBox.shrink();
    return RawImage(
      image: _cachedBlur,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

class _NowPlayingBackdrop extends StatelessWidget {
  const _NowPlayingBackdrop({
    required this.cover,
    required this.scheme,
    required this.brightness,
  });

  final ImageProvider<Object>? cover;
  final ColorScheme scheme;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? scheme.surface : scheme.secondaryContainer;
    final wash = isDark ? Colors.black : Colors.white;
    final shade = isDark ? Colors.black : scheme.onSecondaryContainer;

    if (cover == null) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 360),
        curve: AppMotion.enter,
        color: base,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 360),
      curve: AppMotion.enter,
      color: base,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        reverseDuration: const Duration(milliseconds: 220),
        switchInCurve: AppMotion.enter,
        switchOutCurve: AppMotion.exit,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: RepaintBoundary(
          key: ValueKey(cover),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: isDark ? 0.78 : 0.92,
                child: _CachedBackdropLayer(
                  imageProvider: cover!,
                  sigma: 18,
                  scale: 1.08,
                ),
              ),
              Opacity(
                opacity: isDark ? 0.30 : 0.34,
                child: _CachedBackdropLayer(
                  imageProvider: cover!,
                  sigma: 56,
                  scale: 1.34,
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      wash.withValues(alpha: isDark ? 0.16 : 0.38),
                      base.withValues(alpha: isDark ? 0.12 : 0.24),
                      wash.withValues(alpha: isDark ? 0.20 : 0.44),
                    ],
                    stops: const [0.0, 0.48, 1.0],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.18, -0.18),
                    radius: 1.08,
                    colors: [
                      Colors.transparent,
                      shade.withValues(alpha: isDark ? 0.18 : 0.08),
                      shade.withValues(alpha: isDark ? 0.42 : 0.17),
                    ],
                    stops: const [0.50, 0.78, 1.0],
                  ),
                ),
              ),
              ColoredBox(
                color: wash.withValues(alpha: isDark ? 0.06 : 0.14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExclusiveModeSwitch extends StatelessWidget {
  const _ExclusiveModeSwitch();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder(
      valueListenable: PlayService.instance.playbackService.wasapiExclusive,
      builder: (context, exclusive, _) => IconButton(
        onPressed: () {
          PlayService.instance.playbackService.useExclusiveMode(!exclusive);
        },
        icon: Center(
          child: Text(
            "独占",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: exclusive ? scheme.primary : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _NowPlayingMoreAction extends StatelessWidget {
  const _NowPlayingMoreAction();

  @override
  Widget build(BuildContext context) {
    final playbackService = context.watch<PlaybackService>();
    final nowPlaying = playbackService.nowPlaying;
    final scheme = Theme.of(context).colorScheme;

    if (nowPlaying == null) {
      return IconButton(
        onPressed: null,
        icon: const Icon(Symbols.more_vert),
        color: scheme.onSecondaryContainer,
      );
    }

    return IconButton(
      onPressed: () {
        showNowPlayingGlassPopup<void>(
          context: context,
          width: 420,
          height: 84.0 + nowPlaying.splitedArtists.length * 52.0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final artistName in nowPlaying.splitedArtists)
                _NowPlayingPopupAction(
                  icon: Symbols.people,
                  label: artistName,
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    final artist =
                        AudioLibrary.instance.artistCollection[artistName]!;
                    context.pushReplacement(
                      app_paths.ARTIST_DETAIL_PAGE,
                      extra: artist,
                    );
                  },
                ),
              _NowPlayingPopupAction(
                icon: Symbols.album,
                label: nowPlaying.album,
                onTap: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  final album =
                      AudioLibrary.instance.albumCollection[nowPlaying.album]!;
                  context.pushReplacement(app_paths.ALBUM_DETAIL_PAGE,
                      extra: album);
                },
              ),
              _NowPlayingPopupAction(
                icon: Symbols.info,
                label: "详细信息",
                onTap: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  context.pushReplacement(app_paths.AUDIO_DETAIL_PAGE,
                      extra: nowPlaying);
                },
              ),
            ],
          ),
        );
      },
      icon: const Icon(Symbols.more_vert),
      color: scheme.onSecondaryContainer,
    );
  }
}

class _NowPlayingPopupAction extends StatelessWidget {
  const _NowPlayingPopupAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Icon(icon, color: scheme.onSurfaceVariant),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopLyricSwitch extends StatelessWidget {
  const _DesktopLyricSwitch();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: PlayService.instance.desktopLyricService,
      builder: (context, _) {
        final desktopLyricService = PlayService.instance.desktopLyricService;
        return FutureBuilder(
          future: desktopLyricService.desktopLyric,
          builder: (context, snapshot) => IconButton(
            onPressed: snapshot.data == null
                ? desktopLyricService.startDesktopLyric
                : desktopLyricService.isLocked
                    ? desktopLyricService.sendUnlockMessage
                    : desktopLyricService.killDesktopLyric,
            icon: snapshot.connectionState == ConnectionState.done
                ? Icon(
                    desktopLyricService.isLocked ? Symbols.lock : Symbols.toast,
                    fill: snapshot.data == null ? 0 : 1,
                  )
                : const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(),
                  ),
            color: scheme.onSecondaryContainer,
          ),
        );
      },
    );
  }
}

class _NowPlayingSongInfo extends StatelessWidget {
  const _NowPlayingSongInfo();

  String _formatDuration(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  String _formatFromPath(String path) {
    final ext = path.split('.').last.toUpperCase();
    return ext;
  }

  String _guessBitDepth(int? bitrate, int? sampleRate) {
    if (bitrate == null || sampleRate == null) return '-';
    final perChannel = bitrate / 2.0;
    if (perChannel < 500) return '-';
    if (perChannel < 800) return '16 bit';
    if (perChannel < 1600) return '24 bit';
    return '32 bit';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final playbackService = PlayService.instance.playbackService;
    final nowPlaying = playbackService.nowPlaying;

    return IconButton(
      onPressed: nowPlaying == null
          ? null
          : () {
              final fileSize = _getFileLength(nowPlaying.path);
              final bitrateStr = nowPlaying.bitrate != null
                  ? '${nowPlaying.bitrate} kbps'
                  : '-';
              final sampleRateStr = nowPlaying.sampleRate != null
                  ? '${nowPlaying.sampleRate} Hz'
                  : '-';

              showNowPlayingGlassPopup<void>(
                context: context,
                title: "歌曲信息",
                width: 380,
                height: 380,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _InfoRow(label: "标题", value: nowPlaying.title),
                    _InfoRow(label: "艺术家", value: nowPlaying.artist),
                    _InfoRow(label: "专辑", value: nowPlaying.album),
                    _InfoRow(
                        label: "时长",
                        value: _formatDuration(nowPlaying.duration)),
                    _InfoRow(label: "比特率", value: bitrateStr),
                    _InfoRow(label: "采样率", value: sampleRateStr),
                    _InfoRow(
                        label: "位深",
                        value: _guessBitDepth(
                            nowPlaying.bitrate, nowPlaying.sampleRate)),
                    _InfoRow(
                        label: "大小",
                        value:
                            fileSize != null ? _formatFileSize(fileSize) : '-'),
                    _InfoRow(
                        label: "格式", value: _formatFromPath(nowPlaying.path)),
                  ],
                ),
              );
            },
      icon: const Icon(Symbols.info),
      color: scheme.onSecondaryContainer,
    );
  }
}

int? _getFileLength(String path) {
  try {
    return File(path).lengthSync();
  } catch (_) {
    return null;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NowPlayingVolDspSlider extends StatefulWidget {
  const _NowPlayingVolDspSlider();

  @override
  State<_NowPlayingVolDspSlider> createState() =>
      _NowPlayingVolDspSliderState();
}

class _NowPlayingVolDspSliderState extends State<_NowPlayingVolDspSlider> {
  final playbackService = PlayService.instance.playbackService;
  final dragVolDsp = ValueNotifier(
    AppPreference.instance.playbackPref.volumeDsp,
  );
  bool isDragging = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: () {
        showNowPlayingGlassPopup<void>(
          context: context,
          width: 210,
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: SliderTheme(
            data: const SliderThemeData(
              showValueIndicator: ShowValueIndicator.always,
              trackHeight: 3,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 18),
            ),
            child: ValueListenableBuilder(
              valueListenable: dragVolDsp,
              builder: (context, dragVolDspValue, _) => Slider(
                thumbColor: scheme.primary,
                activeColor: scheme.primary,
                inactiveColor: scheme.outline,
                min: 0.0,
                max: 1.0,
                value: isDragging ? dragVolDspValue : playbackService.volumeDsp,
                label: "${(dragVolDspValue * 100).toInt()}",
                onChangeStart: (value) {
                  isDragging = true;
                  dragVolDsp.value = value;
                  playbackService.setVolumeDsp(value);
                },
                onChanged: (value) {
                  dragVolDsp.value = value;
                  playbackService.setVolumeDsp(value);
                },
                onChangeEnd: (value) {
                  isDragging = false;
                  dragVolDsp.value = value;
                  playbackService.setVolumeDsp(value);
                },
              ),
            ),
          ),
        );
      },
      icon: const Icon(Symbols.volume_up),
      color: scheme.onSecondaryContainer,
    );
  }
}

class _NowPlayingPlayModeSwitch extends StatelessWidget {
  const _NowPlayingPlayModeSwitch();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final playbackService = PlayService.instance.playbackService;

    return ValueListenableBuilder(
      valueListenable: playbackService.playMode,
      builder: (context, playMode, _) {
        late IconData result;
        if (playMode == PlayMode.forward) {
          result = Symbols.repeat;
        } else if (playMode == PlayMode.loop) {
          result = Symbols.repeat_on;
        } else {
          result = Symbols.repeat_one_on;
        }

        return IconButton(
          onPressed: () {
            if (playMode == PlayMode.forward) {
              playbackService.setPlayMode(PlayMode.loop);
            } else if (playMode == PlayMode.loop) {
              playbackService.setPlayMode(PlayMode.singleLoop);
            } else {
              playbackService.setPlayMode(PlayMode.forward);
            }
          },
          icon: Icon(result),
          color: scheme.onSecondaryContainer,
        );
      },
    );
  }
}

class _NowPlayingShuffleSwitch extends StatelessWidget {
  const _NowPlayingShuffleSwitch();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final playbackService = PlayService.instance.playbackService;

    return ValueListenableBuilder(
      valueListenable: playbackService.shuffle,
      builder: (context, shuffle, _) => IconButton(
        onPressed: () {
          playbackService.useShuffle(!shuffle);
        },
        icon: Icon(shuffle ? Symbols.shuffle_on : Symbols.shuffle),
        color: scheme.onSecondaryContainer,
      ),
    );
  }
}

/// previous audio, pause/resume, next audio
class _NowPlayingMainControls extends StatelessWidget {
  const _NowPlayingMainControls();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final playbackService = PlayService.instance.playbackService;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: playbackService.lastAudio,
          icon: const Icon(Symbols.skip_previous),
          style: LargeFilledIconButtonStyle(primary: false, scheme: scheme),
        ),
        const SizedBox(width: 16),
        StreamBuilder(
          stream: playbackService.playerStateStream,
          initialData: playbackService.playerState,
          builder: (context, snapshot) {
            final playerState = snapshot.data!;
            late void Function() onTap;
            if (playerState == PlayerState.playing) {
              onTap = playbackService.pause;
            } else if (playerState == PlayerState.completed) {
              onTap = playbackService.playAgain;
            } else {
              onTap = playbackService.start;
            }

            return IconButton(
              onPressed: onTap,
              icon: Icon(
                playerState == PlayerState.playing
                    ? Symbols.pause
                    : Symbols.play_arrow,
              ),
              style: LargeFilledIconButtonStyle(primary: true, scheme: scheme),
            );
          },
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: playbackService.nextAudio,
          icon: const Icon(Symbols.skip_next),
          style: LargeFilledIconButtonStyle(primary: false, scheme: scheme),
        ),
      ],
    );
  }
}

/// suiggly slider, position and length
class _NowPlayingSlider extends StatefulWidget {
  const _NowPlayingSlider();

  @override
  State<_NowPlayingSlider> createState() => _NowPlayingSliderState();
}

class _NowPlayingSliderState extends State<_NowPlayingSlider> {
  final dragPosition = ValueNotifier(0.0);
  bool isDragging = false;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final playbackService = context.watch<PlaybackService>();
    final nowPlayingLength = playbackService.length;

    return Column(
      children: [
        SliderTheme(
          data: const SliderThemeData(
            showValueIndicator: ShowValueIndicator.always,
          ),
          child: StreamBuilder(
            stream: playbackService.playerStateStream,
            initialData: playbackService.playerState,
            builder: (context, playerStateSnapshot) => ListenableBuilder(
              listenable: dragPosition,
              builder: (context, _) => StreamBuilder(
                stream: playbackService.positionStream,
                initialData: playbackService.position,
                builder: (context, positionSnapshot) => Slider(
                  thumbColor: scheme.primary,
                  activeColor: scheme.primary,
                  inactiveColor: scheme.outline,
                  min: 0.0,
                  max: nowPlayingLength,
                  value: isDragging
                      ? dragPosition.value
                      : positionSnapshot.data! > nowPlayingLength
                          ? nowPlayingLength
                          : positionSnapshot.data!,
                  label: Duration(
                    milliseconds: (dragPosition.value * 1000).toInt(),
                  ).toStringHMMSS(),
                  onChangeStart: (value) {
                    isDragging = true;
                    dragPosition.value = value;
                  },
                  onChanged: (value) {
                    dragPosition.value = value;
                  },
                  onChangeEnd: (value) {
                    isDragging = false;
                    playbackService.seek(value);
                  },
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StreamBuilder(
                stream: playbackService.positionStream,
                initialData: playbackService.position,
                builder: (context, snapshot) {
                  final pos = snapshot.data!;
                  return Text(
                    Duration(
                      milliseconds: (pos * 1000).toInt(),
                    ).toStringHMMSS(),
                    style: TextStyle(color: scheme.onSecondaryContainer),
                  );
                },
              ),
              Text(
                Duration(
                  milliseconds: (nowPlayingLength * 1000).toInt(),
                ).toStringHMMSS(),
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ],
          ),
        )
      ],
    );
  }
}

/// title, artist, album, cover
class _NowPlayingInfo extends StatefulWidget {
  const _NowPlayingInfo({
    this.coverSize,
    this.coverAlignment = Alignment.centerLeft,
    this.coverSizeInset = 12,
  });

  final double? coverSize;
  final AlignmentGeometry coverAlignment;
  final double coverSizeInset;

  @override
  State<_NowPlayingInfo> createState() => __NowPlayingInfoState();
}

class __NowPlayingInfoState extends State<_NowPlayingInfo> {
  final playbackService = PlayService.instance.playbackService;
  Future<ImageProvider<Object>?>? nowPlayingCover;
  String? _coverPath;

  void updateCover() {
    final audio = playbackService.nowPlaying;
    if (_coverPath == audio?.path) return;

    _coverPath = audio?.path;
    setState(() {
      nowPlayingCover = audio?.largeCover;
    });
  }

  @override
  void initState() {
    super.initState();
    final audio = playbackService.nowPlaying;
    _coverPath = audio?.path;
    nowPlayingCover = audio?.largeCover;
    playbackService.addListener(updateCover);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nowPlaying = playbackService.nowPlaying;

    final placeholder = FittedBox(
      child: Icon(
        Symbols.broken_image,
        size: 400.0,
        color: scheme.onSecondaryContainer,
      ),
    );

    const loadingWidget = Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final coverSize = widget.coverSize ??
            (constraints.biggest.shortestSide - widget.coverSizeInset)
                .clamp(260.0, 680.0)
                .toDouble();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: _largeTitleBlockHeight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nowPlaying == null ? "Border Music" : nowPlaying.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      nowPlaying == null
                          ? "Enjoy Music"
                          : "${nowPlaying.artist} - ${nowPlaying.album}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSecondaryContainer),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: widget.coverAlignment,
                child: SizedBox.square(
                  dimension: coverSize,
                  child: RepaintBoundary(
                    child: nowPlayingCover == null
                        ? placeholder
                        : FutureBuilder(
                            future: nowPlayingCover,
                            builder: (context, snapshot) =>
                                switch (snapshot.connectionState) {
                              ConnectionState.done => snapshot.data == null
                                  ? placeholder
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image(
                                        image: snapshot.data!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            placeholder,
                                      ),
                                    ),
                              _ => loadingWidget,
                            },
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    playbackService.removeListener(updateCover);
    super.dispose();
  }
}
