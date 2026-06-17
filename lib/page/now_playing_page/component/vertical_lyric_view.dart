import 'dart:async';
import 'dart:math';

import 'package:border_player/lyric/lyric.dart';
import 'package:border_player/page/now_playing_page/component/lyric_view_controls.dart';
import 'package:border_player/page/now_playing_page/component/lyric_view_tile.dart';
import 'package:border_player/page/now_playing_page/now_playing_render_phase.dart';
import 'package:border_player/play_service/play_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

bool ALWAYS_SHOW_LYRIC_VIEW_CONTROLS = false;

class VerticalLyricView extends StatefulWidget {
  const VerticalLyricView({super.key});

  @override
  State<VerticalLyricView> createState() => _VerticalLyricViewState();
}

class _VerticalLyricViewState extends State<VerticalLyricView> {
  bool isHovering = false;
  final lyricViewController = LyricViewController();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final heavyVisualsReady =
        NowPlayingRenderPhase.heavyVisualsReadyOf(context);

    const loadingWidget = Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(),
      ),
    );

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          isHovering = true;
        });
      },
      onExit: (_) {
        setState(() {
          isHovering = false;
        });
      },
      child: Material(
        type: MaterialType.transparency,
        child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(scrollbars: false),
          child: ChangeNotifierProvider.value(
            value: lyricViewController,
            child: heavyVisualsReady
                ? ListenableBuilder(
                    listenable: PlayService.instance.lyricService,
                    builder: (context, _) => FutureBuilder(
                      future: PlayService.instance.lyricService.currLyricFuture,
                      builder: (context, snapshot) {
                        final lyricNullable = snapshot.data;
                        final noLyricWidget = Center(
                          child: Text(
                            "无歌词",
                            style: TextStyle(
                              fontSize: 22,
                              color: scheme.onSecondaryContainer,
                            ),
                          ),
                        );

                        return Stack(
                          children: [
                            switch (snapshot.connectionState) {
                              ConnectionState.none => loadingWidget,
                              ConnectionState.waiting => loadingWidget,
                              ConnectionState.active => loadingWidget,
                              ConnectionState.done => lyricNullable == null
                                  ? noLyricWidget
                                  : _VerticalLyricScrollView(
                                      lyric: lyricNullable,
                                    ),
                            },
                            if (isHovering || ALWAYS_SHOW_LYRIC_VIEW_CONTROLS)
                              const Align(
                                alignment: Alignment.bottomRight,
                                child: LyricViewControls(),
                              )
                          ],
                        );
                      },
                    ),
                  )
                : loadingWidget,
          ),
        ),
      ),
    );
  }
}

final LYRIC_VIEW_KEY = GlobalKey();

class _VerticalLyricScrollView extends StatefulWidget {
  const _VerticalLyricScrollView({required this.lyric});

  final Lyric lyric;

  @override
  State<_VerticalLyricScrollView> createState() =>
      _VerticalLyricScrollViewState();
}

class _VerticalLyricScrollViewState extends State<_VerticalLyricScrollView> {
  final playbackService = PlayService.instance.playbackService;
  final lyricService = PlayService.instance.lyricService;
  late StreamSubscription lyricLineStreamSubscription;
  final scrollController = ScrollController();

  int _currentLine = 0;
  final currentLyricTileKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _initLyricView();
    lyricLineStreamSubscription =
        lyricService.lyricLineStream.listen(_updateNextLyricLine);
  }

  void _initLyricView() {
    final next = widget.lyric.lines.indexWhere(
      (element) =>
          element.start.inMilliseconds / 1000 > playbackService.position,
    );
    _currentLine = max((next == -1 ? widget.lyric.lines.length : next) - 1, 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLyric();
    });
  }

  void _scrollToCurrentLyric() {
    final targetContext = currentLyricTileKey.currentContext;
    if (targetContext == null) return;
    if (!targetContext.mounted) return;

    final renderBox = targetContext.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final viewport = RenderAbstractViewport.of(renderBox);
    final targetOffset = viewport
        .getOffsetToReveal(renderBox, 0.25)
        .offset
        .clamp(
          scrollController.position.minScrollExtent,
          scrollController.position.maxScrollExtent,
        );

    final diff = (scrollController.offset - targetOffset).abs();
    if (diff < 2.0) {
      scrollController.jumpTo(targetOffset);
    } else {
      scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _seekToLyricLine(int i) {
    playbackService.seek(widget.lyric.lines[i].start.inMilliseconds / 1000);
    setState(() {
      _currentLine = i;
    });
  }

  void _updateNextLyricLine(int lyricLine) {
    if (lyricLine == _currentLine) return;
    setState(() {
      _currentLine = lyricLine;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLyric();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final spacerHeight = (viewportHeight * 0.4).clamp(120.0, 400.0);

    return CustomScrollView(
      key: LYRIC_VIEW_KEY,
      controller: scrollController,
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: spacerHeight),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final isCurrent = i == _currentLine;
              return LyricViewTile(
                key: isCurrent ? currentLyricTileKey : null,
                line: widget.lyric.lines[i],
                opacity: isCurrent ? 1.0 : 0.18,
                onTap: () => _seekToLyricLine(i),
              );
            },
            childCount: widget.lyric.lines.length,
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: spacerHeight),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    lyricLineStreamSubscription.cancel();
    scrollController.dispose();
  }
}
