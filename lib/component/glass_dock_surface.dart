import 'dart:ui';

import 'package:flutter/material.dart';

class GlassDockSurface extends StatelessWidget {
  const GlassDockSurface({
    super.key,
    required this.child,
    required this.borderRadius,
    this.padding = EdgeInsets.zero,
    this.height,
    this.width,
    this.enabled = true,
    this.clipBehavior = Clip.antiAlias,
    this.shadowScale = 1.0,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double? height;
  final double? width;
  final bool enabled;
  final Clip clipBehavior;
  final double shadowScale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!enabled) {
      return SizedBox(
        height: height,
        width: width,
        child: child,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.16),
            blurRadius: 74 * shadowScale,
            spreadRadius: 2,
            offset: Offset(0, 20 * shadowScale),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 42 * shadowScale,
            spreadRadius: -8,
            offset: Offset(0, 16 * shadowScale),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 58, sigmaY: 58),
          child: Container(
            height: height,
            width: width,
            padding: padding,
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.34),
              borderRadius: borderRadius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: 0.8,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.surface.withValues(alpha: 0.44),
                  scheme.primaryContainer.withValues(alpha: 0.22),
                  scheme.surface.withValues(alpha: 0.26),
                ],
                stops: const [0.0, 0.58, 1.0],
              ),
            ),
            child: RepaintBoundary(child: child),
          ),
        ),
      ),
    );
  }
}
