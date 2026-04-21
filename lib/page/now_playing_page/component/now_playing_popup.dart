import 'dart:ui';

import 'package:flutter/material.dart';

class NowPlayingGlassDialog extends StatelessWidget {
  const NowPlayingGlassDialog({
    super.key,
    required this.title,
    required this.child,
    this.width = 448,
    this.height = 520,
  });

  final String title;
  final Widget child;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
      backgroundColor: Colors.transparent,
      child: NowPlayingGlassPanel(
        title: title,
        width: width,
        height: height,
        child: child,
      ),
    );
  }
}

class NowPlayingGlassPanel extends StatelessWidget {
  const NowPlayingGlassPanel({
    super.key,
    required this.child,
    this.title,
    this.width = 360,
    this.height = 320,
    this.padding = const EdgeInsets.fromLTRB(20, 22, 20, 18),
  });

  final String? title;
  final Widget child;
  final double width;
  final double height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withOpacity(0.30),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: scheme.primary.withOpacity(0.13),
              width: 0.8,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primaryContainer.withOpacity(0.38),
                scheme.surfaceContainerHighest.withOpacity(0.48),
                scheme.secondaryContainer.withOpacity(0.34),
              ],
              stops: const [0.0, 0.58, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withOpacity(0.10),
                blurRadius: 42,
                spreadRadius: -10,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: title == null
              ? child
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 18),
                      child: Text(
                        title!,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                    ),
                    Expanded(child: child),
                  ],
                ),
        ),
      ),
    );
  }
}

Future<T?> showNowPlayingGlassPopup<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  double width = 360,
  double height = 320,
  EdgeInsets padding = const EdgeInsets.fromLTRB(20, 22, 20, 18),
}) {
  final renderBox = context.findRenderObject() as RenderBox?;
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
  final theme = Theme.of(context);
  final anchorOffset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
  final anchorSize = renderBox?.size ?? Size.zero;
  final overlaySize = overlay?.size ?? MediaQuery.sizeOf(context);
  final maxLeft = overlaySize.width - width - 16.0;
  final maxTop = overlaySize.height - height - 16.0;
  final rawLeft = anchorOffset.dx + anchorSize.width - width;
  final rawTop = anchorOffset.dy - height - 18;
  final left = rawLeft.clamp(16.0, maxLeft < 16.0 ? 16.0 : maxLeft).toDouble();
  final top = rawTop.clamp(16.0, maxTop < 16.0 ? 16.0 : maxTop).toDouble();

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 130),
    pageBuilder: (context, _, __) {
      return Stack(
        children: [
          Theme(
            data: theme,
            child: Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: NowPlayingGlassPanel(
                  title: title,
                  width: width,
                  height: height,
                  padding: padding,
                  child: child,
                ),
              ),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (context, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          alignment: Alignment.bottomRight,
          child: child,
        ),
      );
    },
  );
}

MenuStyle nowPlayingGlassMenuStyle(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return MenuStyle(
    elevation: const WidgetStatePropertyAll(0),
    backgroundColor: WidgetStatePropertyAll(
      scheme.primaryContainer.withOpacity(0.64),
    ),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    shadowColor: WidgetStatePropertyAll(scheme.shadow.withOpacity(0.10)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: scheme.outlineVariant.withOpacity(0.12),
          width: 0.7,
        ),
      ),
    ),
  );
}
