part of 'page.dart';

class _NowPlayingPage_Large extends StatelessWidget {
  const _NowPlayingPage_Large();

  @override
  Widget build(BuildContext context) {
    const spacer = SizedBox(width: 8.0);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32.0, 8.0, 32.0, 32.0),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                const Expanded(child: _NowPlayingInfo()),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: NOW_PLAYING_VIEW_MODE,
                    builder: (context, value, _) => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: switch (value) {
                        NowPlayingViewMode.onlyMain =>
                          const VerticalLyricView(),
                        NowPlayingViewMode.withLyric =>
                          const VerticalLyricView(),
                        NowPlayingViewMode.withPlaylist =>
                          const CurrentPlaylistView(),
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withOpacity(0.20),
                  blurRadius: 54,
                  spreadRadius: 8,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
                child: Container(
                  height: 190,
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 22),
                  decoration: BoxDecoration(
                    color: scheme.surface.withOpacity(0.62),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: scheme.onSurface.withOpacity(0.08),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.surface.withOpacity(0.72),
                        scheme.primaryContainer.withOpacity(0.34),
                      ],
                    ),
                  ),
                  child: const Column(
                    children: [
                      _NowPlayingSlider(),
                      Spacer(),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _NowPlayingShuffleSwitch(),
                                  spacer,
                                  _NowPlayingPlayModeSwitch(),
                                  spacer,
                                  _NowPlayingVolDspSlider(),
                                  spacer,
                                  _ExclusiveModeSwitch(),
                                ],
                              ),
                            ),
                            _NowPlayingMainControls(),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _NowPlayingLargeViewSwitch(),
                                  spacer,
                                  _DesktopLyricSwitch(),
                                  spacer,
                                  _NowPlayingMoreAction(),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 切换视图：lyric / playlist
class _NowPlayingLargeViewSwitch extends StatelessWidget {
  const _NowPlayingLargeViewSwitch();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder(
      valueListenable: NOW_PLAYING_VIEW_MODE,
      builder: (context, value, _) => IconButton(
        tooltip: switch (value) {
          NowPlayingViewMode.withPlaylist => "歌词",
          _ => "播放列表",
        },
        onPressed: () {
          if (value == NowPlayingViewMode.onlyMain ||
              value == NowPlayingViewMode.withLyric) {
            NOW_PLAYING_VIEW_MODE.value = NowPlayingViewMode.withPlaylist;
            AppPreference.instance.nowPlayingPagePref.nowPlayingViewMode =
                NowPlayingViewMode.withPlaylist;
          } else {
            NOW_PLAYING_VIEW_MODE.value = NowPlayingViewMode.withLyric;
            AppPreference.instance.nowPlayingPagePref.nowPlayingViewMode =
                NowPlayingViewMode.withLyric;
          }
        },
        icon: Icon(
          switch (value) {
            NowPlayingViewMode.withPlaylist => Symbols.lyrics,
            _ => Symbols.queue_music,
          },
        ),
        color: scheme.onSecondaryContainer,
      ),
    );
  }
}
