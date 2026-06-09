import 'dart:async';

import 'package:border_player/play_service/play_service.dart';
import 'package:flutter/material.dart';

class RectangleProgressIndicator extends StatefulWidget {
  const RectangleProgressIndicator({
    super.key,
    required this.size,
    required this.child,
    this.transparentTrack = false,
  });

  final Size size;
  final Widget child;
  final bool transparentTrack;

  @override
  State<RectangleProgressIndicator> createState() =>
      _RectangleProgressIndicatorState();
}

class _RectangleProgressIndicatorState
    extends State<RectangleProgressIndicator> {
  late StreamSubscription<double> subscription;

  final progress = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    subscription =
        PlayService.instance.playbackService.positionStream.listen((event) {
      final length = PlayService.instance.playbackService.length;
      progress.value = length == 0 ? 0 : event / length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      size: widget.size,
      painter: RectangleProgressPainter(
        progress: progress,
        scheme: scheme,
        transparentTrack: widget.transparentTrack,
      ),
      child: widget.child,
    );
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }
}

class RectangleProgressPainter extends CustomPainter {
  RectangleProgressPainter({
    required this.progress,
    required this.scheme,
    required this.transparentTrack,
  }) : super(repaint: progress);

  final ValueNotifier<double> progress;
  final ColorScheme scheme;
  final bool transparentTrack;

  @override
  void paint(Canvas canvas, Size size) {
    if (!transparentTrack) {
      final trackPainter = Paint()..color = scheme.secondaryContainer;
      canvas.drawRect(
        Rect.fromLTWH(0.0, 0.0, size.width, size.height),
        trackPainter,
      );
    }

    final progressPainter = Paint()
      ..color = scheme.primary.withValues(
        alpha: transparentTrack ? 0.10 : 0.18,
      );
    canvas.drawRect(
      Rect.fromLTWH(0.0, 0.0, size.width * progress.value, size.height),
      progressPainter,
    );
  }

  @override
  bool shouldRepaint(RectangleProgressPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(RectangleProgressPainter oldDelegate) => false;
}
