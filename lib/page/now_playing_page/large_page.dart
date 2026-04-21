part of 'page.dart';

class _NowPlayingPage_Large extends StatelessWidget {
  const _NowPlayingPage_Large();

  @override
  Widget build(BuildContext context) {
    const spacer = SizedBox(width: 8.0);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32.0, _largePageTopGap, 32.0, 32.0),
      child: Column(
        children: [
          Expanded(
            child: FractionallySizedBox(
              widthFactor: 0.92,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final leftWidth = constraints.maxWidth * 0.56;
                  final coverAreaHeight =
                      constraints.maxHeight - _largeTitleBlockHeight;
                  final relaxedCoverAreaHeight = coverAreaHeight - 72;
                  var coverSize = leftWidth - 48;
                  if (coverSize > relaxedCoverAreaHeight) {
                    coverSize = relaxedCoverAreaHeight;
                  }
                  if (coverSize > 680) {
                    coverSize = 680;
                  }
                  if (coverSize < 220) {
                    coverSize = 220;
                  }
                  final coverTop = _largeTitleBlockHeight +
                      ((coverAreaHeight - coverSize) / 2)
                          .clamp(0.0, 999.0)
                          .toDouble();

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      SizedBox(
                        width: coverSize,
                        child: _NowPlayingInfo(coverSize: coverSize),
                      ),
                      Positioned(
                        left: coverSize + 48,
                        right: 0,
                        top: coverTop,
                        height: coverSize,
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
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          FractionallySizedBox(
            widthFactor: 0.92,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withOpacity(0.16),
                    blurRadius: 74,
                    spreadRadius: 2,
                    offset: const Offset(0, 20),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 42,
                    spreadRadius: -8,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 58, sigmaY: 58),
                  child: Container(
                    height: 176,
                    padding: const EdgeInsets.fromLTRB(30, 22, 30, 20),
                    decoration: BoxDecoration(
                      color: scheme.surface.withOpacity(0.34),
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.10),
                        width: 0.8,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.surface.withOpacity(0.44),
                          scheme.primaryContainer.withOpacity(0.22),
                          scheme.surface.withOpacity(0.26),
                        ],
                        stops: const [0.0, 0.58, 1.0],
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
