// ignore_for_file: camel_case_types

import 'package:border_player/component/mini_now_playing.dart';
import 'package:border_player/component/responsive_builder.dart';
import 'package:border_player/component/side_nav.dart';
import 'package:border_player/component/title_bar.dart';
import 'package:border_player/window_fullscreen_state.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

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
    return ValueListenableBuilder<bool>(
      valueListenable: windowNativeFullScreen,
      builder: (context, isFullScreen, _) {
        return DragToResizeArea(
          resizeEdgeSize: isFullScreen ? 0 : 12,
          child: Scaffold(
            backgroundColor: scheme.surfaceContainer,
            appBar: const PreferredSize(
              preferredSize: Size.fromHeight(72.0),
              child: TitleBar(),
            ),
            drawer: const SideNav(),
            body: Stack(children: [page, const MiniNowPlaying()]),
          ),
        );
      },
    );
  }
}

class _FullScreenAwareDragToResizeArea extends StatelessWidget {
  const _FullScreenAwareDragToResizeArea({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: windowNativeFullScreen,
      builder: (context, isFullScreen, _) {
        return DragToResizeArea(
          resizeEdgeSize: isFullScreen ? 0 : 12,
          child: child,
        );
      },
    );
  }
}

class _AppShell_Large extends StatelessWidget {
  const _AppShell_Large({required this.page});

  final Widget page;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _FullScreenAwareDragToResizeArea(
      child: Scaffold(
        backgroundColor: scheme.surfaceContainer,
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
    );
  }
}
