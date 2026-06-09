import 'package:border_player/app_settings.dart';
import 'package:border_player/component/glass_dock_surface.dart';
import 'package:border_player/component/rectangle_progress_indicator.dart';
import 'package:border_player/component/responsive_builder.dart';
import 'package:border_player/play_service/play_service.dart';
import 'package:border_player/src/bass/bass_player.dart';
import 'package:border_player/app_paths.dart' as app_paths;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

class MiniNowPlaying extends StatelessWidget {
  const MiniNowPlaying({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(builder: (context, screenType) {
      final scheme = Theme.of(context).colorScheme;
      final useGlassBackdrop = AppSettings.instance.dynamicTheme &&
          AppSettings.instance.homeCoverBackdrop;

      return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            8.0,
            0,
            8.0,
            screenType == ScreenType.small ? 8.0 : 38.0,
          ),
          child: SizedBox(
            height: 58.0,
            width: 612.0,
            child: useGlassBackdrop
                ? GlassDockSurface(
                    borderRadius: BorderRadius.circular(30),
                    child: LayoutBuilder(builder: (context, constraints) {
                      return RectangleProgressIndicator(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        transparentTrack: true,
                        child: const _NowPlayingForeground(),
                      );
                    }),
                  )
                : DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.08),
                          blurRadius: 30,
                          spreadRadius: 3,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.40),
                          blurRadius: 26,
                          spreadRadius: -8,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: LayoutBuilder(builder: (context, constraints) {
                        return RectangleProgressIndicator(
                          size:
                              Size(constraints.maxWidth, constraints.maxHeight),
                          transparentTrack: false,
                          child: const _NowPlayingForeground(),
                        );
                      }),
                    ),
                  ),
          ),
        ),
      );
    });
  }
}

class _NowPlayingForeground extends StatelessWidget {
  const _NowPlayingForeground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      type: MaterialType.transparency,
      borderRadius: BorderRadius.circular(30.0),
      child: InkWell(
        onTap: () => context.push(app_paths.NOW_PLAYING_PAGE),
        borderRadius: BorderRadius.circular(30.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ListenableBuilder(
            listenable: PlayService.instance.playbackService,
            builder: (context, _) {
              final playbackService = PlayService.instance.playbackService;
              final nowPlaying = playbackService.nowPlaying;
              final placeholder = Icon(
                Symbols.broken_image,
                size: 48.0,
                color: scheme.onSecondaryContainer,
              );

              return Row(
                children: [
                  /// now playing cover
                  nowPlaying != null
                      ? FutureBuilder(
                          future: nowPlaying.cover,
                          builder: (context, snapshot) =>
                              switch (snapshot.connectionState) {
                            ConnectionState.done => snapshot.data == null
                                ? placeholder
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(26.0),
                                    child: Image(
                                      image: snapshot.data!,
                                      width: 48.0,
                                      height: 48.0,
                                      errorBuilder: (_, __, ___) => placeholder,
                                    ),
                                  ),
                            _ => const SizedBox(
                                width: 48,
                                height: 48,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          },
                        )
                      : placeholder,
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        /// title
                        Text(
                          nowPlaying != null
                              ? nowPlaying.title
                              : "Border Player",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSecondaryContainer,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),

                        /// artist - album
                        Text(
                          nowPlaying != null
                              ? "${nowPlaying.artist} - ${nowPlaying.album}"
                              : "Enjoy music",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  const _MiniPlaybackControls(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MiniPlaybackControls extends StatelessWidget {
  const _MiniPlaybackControls();

  ButtonStyle _buttonStyle(ColorScheme scheme, bool useGlassBackdrop) {
    return IconButton.styleFrom(
      fixedSize: const Size.square(36),
      minimumSize: const Size.square(36),
      padding: EdgeInsets.zero,
      shape: const CircleBorder(),
      backgroundColor:
          useGlassBackdrop ? Colors.transparent : scheme.secondaryContainer,
      foregroundColor: scheme.onSecondaryContainer,
      hoverColor: scheme.onSecondaryContainer.withValues(alpha: 0.08),
    );
  }

  Widget _dockButton({
    required ColorScheme scheme,
    required bool useGlassBackdrop,
    required VoidCallback? onPressed,
    required Widget icon,
  }) {
    final button = IconButton(
      onPressed: onPressed,
      icon: icon,
      style: _buttonStyle(scheme, useGlassBackdrop),
    );

    if (!useGlassBackdrop) return button;

    return SizedBox.square(
      dimension: 36,
      child: GlassDockSurface(
        borderRadius: BorderRadius.circular(18),
        shadowScale: 0.22,
        child: button,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final playbackService = PlayService.instance.playbackService;
    final useGlassBackdrop = AppSettings.instance.dynamicTheme &&
        AppSettings.instance.homeCoverBackdrop;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dockButton(
          scheme: scheme,
          useGlassBackdrop: useGlassBackdrop,
          onPressed: playbackService.lastAudio,
          icon: const Icon(Symbols.skip_previous, size: 21),
        ),
        const SizedBox(width: 4),
        StreamBuilder(
          stream: playbackService.playerStateStream,
          initialData: playbackService.playerState,
          builder: (context, snapshot) {
            late void Function() onPressed;
            if (snapshot.data! == PlayerState.playing) {
              onPressed = playbackService.pause;
            } else if (snapshot.data! == PlayerState.completed) {
              onPressed = playbackService.playAgain;
            } else {
              onPressed = playbackService.start;
            }

            return _dockButton(
              scheme: scheme,
              useGlassBackdrop: useGlassBackdrop,
              onPressed: onPressed,
              icon: Icon(
                snapshot.data! == PlayerState.playing
                    ? Symbols.pause
                    : Symbols.play_arrow,
              ),
            );
          },
        ),
        const SizedBox(width: 4),
        _dockButton(
          scheme: scheme,
          useGlassBackdrop: useGlassBackdrop,
          onPressed: playbackService.nextAudio,
          icon: const Icon(Symbols.skip_next, size: 21),
        ),
      ],
    );
  }
}
