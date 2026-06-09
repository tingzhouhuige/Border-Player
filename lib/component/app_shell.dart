// ignore_for_file: camel_case_types

import 'dart:ui';

import 'package:border_player/app_motion.dart';
import 'package:border_player/app_settings.dart';
import 'package:border_player/component/mini_now_playing.dart';
import 'package:border_player/component/responsive_builder.dart';
import 'package:border_player/component/side_nav.dart';
import 'package:border_player/component/title_bar.dart';
import 'package:border_player/play_service/play_service.dart';
import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.page});

  final Widget page;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType) {
        switch (screenType) {
          case ScreenType.small:
            return _AppShell_Small(page: page);
          case ScreenType.medium:
          case ScreenType.large:
            return _AppShell_Large(page: page);
        }
      },
    );
  }
}

class _AppShell_Small extends StatelessWidget {
  const _AppShell_Small({required this.page});

  final Widget page;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        _HomeCoverBackdrop(scheme: scheme),
        Scaffold(
          backgroundColor: _useHomeCoverBackdrop()
              ? Colors.transparent
              : scheme.surfaceContainer,
          appBar: const PreferredSize(
            preferredSize: Size.fromHeight(72.0),
            child: TitleBar(),
          ),
          drawer: const SideNav(),
          body: Stack(children: [page, const MiniNowPlaying()]),
        ),
      ],
    );
  }
}

class _AppShell_Large extends StatelessWidget {
  const _AppShell_Large({required this.page});

  final Widget page;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        _HomeCoverBackdrop(scheme: scheme),
        Scaffold(
          backgroundColor: _useHomeCoverBackdrop()
              ? Colors.transparent
              : scheme.surfaceContainer,
          appBar: const PreferredSize(
            preferredSize: Size.fromHeight(72.0),
            child: TitleBar(),
          ),
          body: Row(
            children: [
              const SideNav(),
              Expanded(
                child: Stack(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 20, 18),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22.0),
                      child: page,
                    ),
                  ),
                  const MiniNowPlaying()
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

bool _useHomeCoverBackdrop() {
  final settings = AppSettings.instance;
  return settings.dynamicTheme && settings.homeCoverBackdrop;
}

class _HomeCoverBackdrop extends StatefulWidget {
  const _HomeCoverBackdrop({required this.scheme});

  final ColorScheme scheme;

  @override
  State<_HomeCoverBackdrop> createState() => _HomeCoverBackdropState();
}

class _HomeCoverBackdropState extends State<_HomeCoverBackdrop> {
  final playbackService = PlayService.instance.playbackService;
  ImageProvider<Object>? _cover;
  String? _coverPath;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    playbackService.addListener(_updateCover);
    _updateCover();
  }

  @override
  void didUpdateWidget(covariant _HomeCoverBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_useHomeCoverBackdrop()) {
      _requestId++;
      _coverPath = null;
      if (_cover != null) {
        setState(() {
          _cover = null;
        });
      }
      return;
    }
    if (_cover == null) _updateCover();
  }

  void _updateCover() {
    if (!_useHomeCoverBackdrop()) return;
    final nowPlaying = playbackService.nowPlaying;
    final coverPath = nowPlaying?.path;
    if (coverPath != null && coverPath == _coverPath && _cover != null) {
      return;
    }

    final requestId = ++_requestId;
    _coverPath = coverPath;
    final coverFuture = nowPlaying?.cover;
    if (coverFuture == null) {
      if (mounted) {
        setState(() {
          _cover = null;
        });
      }
      return;
    }

    coverFuture.then((cover) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _cover = cover;
      });
    });
  }

  @override
  void dispose() {
    playbackService.removeListener(_updateCover);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final isDark = scheme.brightness == Brightness.dark;
    final base = scheme.surfaceContainer;
    final cover = _cover;

    if (!_useHomeCoverBackdrop() || cover == null) {
      return AnimatedContainer(
        duration: AppMotion.page,
        curve: AppMotion.enter,
        color: base,
      );
    }

    final wash = isDark ? Colors.black : Colors.white;
    final shade = isDark ? Colors.black : scheme.onSecondaryContainer;

    return AnimatedContainer(
      duration: AppMotion.page,
      curve: AppMotion.enter,
      color: base,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        reverseDuration: AppMotion.quick,
        switchInCurve: AppMotion.enter,
        switchOutCurve: AppMotion.exit,
        child: RepaintBoundary(
          key: ValueKey(_coverPath),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: isDark ? 0.72 : 0.84,
                child: Transform.scale(
                  scale: 1.10,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Image(
                      image: cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: isDark ? 0.28 : 0.30,
                child: Transform.scale(
                  scale: 1.36,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 58, sigmaY: 58),
                    child: Image(
                      image: cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      wash.withValues(alpha: isDark ? 0.18 : 0.40),
                      base.withValues(alpha: isDark ? 0.10 : 0.22),
                      wash.withValues(alpha: isDark ? 0.22 : 0.48),
                    ],
                    stops: const [0.0, 0.48, 1.0],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.22, -0.18),
                    radius: 1.12,
                    colors: [
                      Colors.transparent,
                      shade.withValues(alpha: isDark ? 0.16 : 0.07),
                      shade.withValues(alpha: isDark ? 0.38 : 0.14),
                    ],
                    stops: const [0.48, 0.78, 1.0],
                  ),
                ),
              ),
              ColoredBox(
                color: wash.withValues(alpha: isDark ? 0.05 : 0.12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
