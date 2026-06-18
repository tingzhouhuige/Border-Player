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

class _VerticalLyricScrollViewState extends State<_VerticalLyricScrollView>
    with TickerProviderStateMixin {
  final playbackService = PlayService.instance.playbackService;
  final lyricService = PlayService.instance.lyricService;
  late StreamSubscription lyricLineStreamSubscription;
  final scrollController = ScrollController();
  late final AnimationController _scrollAnimationController;
  late final AnimationController _entranceAnimationController;

  int _currentLine = 0;
  bool _scrollFramePending = false;
  bool _pendingScrollAnimated = false;
  bool _entranceReady = false;
  double _scrollAnimationStart = 0;
  double _scrollAnimationTarget = 0;
  final currentLyricTileKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _scrollAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(_tickScrollAnimation);
    _entranceAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _initLyricView();
    lyricLineStreamSubscription =
        lyricService.lyricLineStream.listen(_updateNextLyricLine);
  }

  void _tickScrollAnimation() {
    if (!scrollController.hasClients) return;

    final progress =
        Curves.easeOutCubic.transform(_scrollAnimationController.value);
    final targetOffset = _scrollAnimationStart +
        (_scrollAnimationTarget - _scrollAnimationStart) * progress;
    final clampedOffset = targetOffset.clamp(
      scrollController.position.minScrollExtent,
      scrollController.position.maxScrollExtent,
    );

    if ((scrollController.offset - clampedOffset).abs() < 0.1) return;
    scrollController.jumpTo(clampedOffset);
  }

  void _initLyricView() {
    final next = widget.lyric.lines.indexWhere(
      (element) =>
          element.start.inMilliseconds / 1000 > playbackService.position,
    );
    _currentLine = max((next == -1 ? widget.lyric.lines.length : next) - 1, 0);

    _scheduleLyricEntrance();
  }

  void _scheduleLyricEntrance() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final targetOffset = _targetOffsetForCurrentLyric();
      if (targetOffset == null) return;

      _scrollAnimationController.stop();
      scrollController.jumpTo(targetOffset);
      setState(() {
        _entranceReady = true;
      });
      _entranceAnimationController.forward(from: 0);
    });
  }

  void _scheduleScrollToCurrentLyric({required bool animated}) {
    _pendingScrollAnimated = _pendingScrollAnimated || animated;
    if (_scrollFramePending) return;

    _scrollFramePending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shouldAnimate = _pendingScrollAnimated;
      _scrollFramePending = false;
      _pendingScrollAnimated = false;
      if (!mounted) return;
      _scrollToCurrentLyric(animated: shouldAnimate);
    });
  }

  double? _targetOffsetForCurrentLyric() {
    final targetContext = currentLyricTileKey.currentContext;
    if (targetContext == null) return null;
    if (!targetContext.mounted) return null;
    if (!scrollController.hasClients) return null;

    final renderBox = targetContext.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final viewport = RenderAbstractViewport.of(renderBox);
    return viewport.getOffsetToReveal(renderBox, 0.25).offset.clamp(
          scrollController.position.minScrollExtent,
          scrollController.position.maxScrollExtent,
        );
  }

  void _scrollToCurrentLyric({required bool animated}) {
    final targetOffset = _targetOffsetForCurrentLyric();
    if (targetOffset == null) return;

    final diff = (scrollController.offset - targetOffset).abs();
    _scrollAnimationController.stop();
    if (diff < 2.0) {
      return;
    } else if (!animated) {
      scrollController.jumpTo(targetOffset);
    } else {
      _scrollAnimationStart = scrollController.offset;
      _scrollAnimationTarget = targetOffset.toDouble();
      _scrollAnimationController.forward(from: 0);
    }
  }

  void _seekToLyricLine(int i) {
    playbackService.seek(widget.lyric.lines[i].start.inMilliseconds / 1000);
    setState(() {
      _currentLine = i;
    });
    _scheduleScrollToCurrentLyric(animated: true);
  }

  void _updateNextLyricLine(int lyricLine) {
    if (widget.lyric.lines.isEmpty) return;
    final nextLine = lyricLine.clamp(0, widget.lyric.lines.length - 1);
    if (nextLine == _currentLine) return;
    setState(() {
      _currentLine = nextLine;
    });

    _scheduleScrollToCurrentLyric(animated: true);
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final spacerHeight = (viewportHeight * 0.4).clamp(120.0, 400.0);

    final lyricScrollView = CustomScrollView(
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

    return ClipRect(
      child: AnimatedBuilder(
        animation: _entranceAnimationController,
        builder: (context, child) {
          final progress = Curves.easeOutCubic.transform(
            _entranceAnimationController.value,
          );
          return Opacity(
            opacity: _entranceReady ? 1 : 0,
            child: Transform.translate(
              offset: Offset(0, (1 - progress) * 56),
              child: child,
            ),
          );
        },
        child: lyricScrollView,
      ),
    );
  }

  @override
  void dispose() {
    _scrollAnimationController.dispose();
    _entranceAnimationController.dispose();
    lyricLineStreamSubscription.cancel();
    scrollController.dispose();
    super.dispose();
  }
}
