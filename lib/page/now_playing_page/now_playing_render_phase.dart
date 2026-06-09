import 'package:flutter/widgets.dart';

class NowPlayingRenderPhase extends InheritedWidget {
  const NowPlayingRenderPhase({
    super.key,
    required this.heavyVisualsReady,
    required super.child,
  });

  final bool heavyVisualsReady;

  static bool heavyVisualsReadyOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<NowPlayingRenderPhase>()
            ?.heavyVisualsReady ??
        true;
  }

  @override
  bool updateShouldNotify(NowPlayingRenderPhase oldWidget) {
    return heavyVisualsReady != oldWidget.heavyVisualsReady;
  }
}
