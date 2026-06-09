import 'dart:ui';

import 'package:border_player/app_motion.dart';
import 'package:border_player/app_settings.dart';
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
            color: scheme.primaryContainer.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.13),
              width: 0.8,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primaryContainer.withValues(alpha: 0.38),
                scheme.surfaceContainerHighest.withValues(alpha: 0.48),
                scheme.secondaryContainer.withValues(alpha: 0.34),
              ],
              stops: const [0.0, 0.58, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.10),
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
  Offset? globalPosition,
}) {
  final renderBox = context.findRenderObject() as RenderBox?;
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
  final theme = Theme.of(context);
  final anchorOffset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
  final anchorSize = renderBox?.size ?? Size.zero;
  final overlaySize = overlay?.size ?? MediaQuery.sizeOf(context);
  final maxLeft = overlaySize.width - width - 16.0;
  final rawLeft =
      globalPosition?.dx ?? anchorOffset.dx + anchorSize.width - width;
  final left = rawLeft.clamp(16.0, maxLeft < 16.0 ? 16.0 : maxLeft).toDouble();

  final anchorTop = globalPosition?.dy ?? anchorOffset.dy;
  final anchorBottom =
      globalPosition?.dy ?? anchorOffset.dy + anchorSize.height;
  final spaceAbove = anchorTop - 16.0;
  final spaceBelow = overlaySize.height - anchorBottom - 16.0;
  final maxHeight = overlaySize.height - 32.0;
  final effectiveHeight = height > maxHeight ? maxHeight : height;
  final double top;
  if (spaceBelow >= effectiveHeight) {
    top = anchorBottom + (globalPosition == null ? 8 : 0);
  } else if (spaceAbove >= effectiveHeight) {
    top = anchorTop - effectiveHeight - (globalPosition == null ? 18 : 0);
  } else {
    top = 16.0;
  }

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: AppMotion.popup,
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
                  height: effectiveHeight,
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
      return AppMotion.popupTransition(
        animation: animation,
        alignment: Alignment.bottomRight,
        child: child,
      );
    },
  );
}

Color _nowPlayingGlassPanelColor(ColorScheme scheme) {
  var color = scheme.surface;
  color = Color.alphaBlend(
    scheme.secondaryContainer.withValues(alpha: 0.34),
    color,
  );
  color = Color.alphaBlend(
    scheme.surfaceContainerHighest.withValues(alpha: 0.48),
    color,
  );
  color = Color.alphaBlend(
    scheme.primaryContainer.withValues(alpha: 0.38),
    color,
  );
  return color;
}

MenuStyle nowPlayingGlassMenuStyle(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final useHomeGlass = AppSettings.instance.dynamicTheme &&
      AppSettings.instance.homeCoverBackdrop;
  final panelColor = _nowPlayingGlassPanelColor(scheme);

  return MenuStyle(
    elevation: WidgetStatePropertyAll(useHomeGlass ? 22 : 0),
    backgroundColor: WidgetStatePropertyAll(
      useHomeGlass ? panelColor : scheme.secondaryContainer,
    ),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    shadowColor: WidgetStatePropertyAll(
      useHomeGlass
          ? scheme.primary.withValues(alpha: 0.10)
          : Colors.transparent,
    ),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(useHomeGlass ? 28 : 18),
        side: BorderSide(
          color: useHomeGlass
              ? scheme.primary.withValues(alpha: 0.13)
              : scheme.outlineVariant.withValues(alpha: 0.12),
          width: useHomeGlass ? 0.8 : 0.7,
        ),
      ),
    ),
  );
}

ButtonStyle nowPlayingGlassMenuItemStyle(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final useHomeGlass = AppSettings.instance.dynamicTheme &&
      AppSettings.instance.homeCoverBackdrop;

  return MenuItemButton.styleFrom(
    foregroundColor: scheme.onSurface,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  ).copyWith(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.hovered)) {
        return useHomeGlass
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.22)
            : scheme.onSurface.withValues(alpha: 0.08);
      }
      return Colors.transparent;
    }),
  );
}

MenuStyle nowPlayingGlassSubmenuStyle(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final useHomeGlass = AppSettings.instance.dynamicTheme &&
      AppSettings.instance.homeCoverBackdrop;
  final panelColor = _nowPlayingGlassPanelColor(scheme);

  return MenuStyle(
    elevation: WidgetStatePropertyAll(useHomeGlass ? 22 : 0),
    backgroundColor: WidgetStatePropertyAll(
      useHomeGlass ? panelColor : scheme.secondaryContainer,
    ),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    shadowColor: WidgetStatePropertyAll(
      useHomeGlass
          ? scheme.primary.withValues(alpha: 0.10)
          : Colors.transparent,
    ),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(useHomeGlass ? 28 : 18),
        side: BorderSide(
          color: useHomeGlass
              ? scheme.primary.withValues(alpha: 0.13)
              : scheme.outlineVariant.withValues(alpha: 0.12),
          width: useHomeGlass ? 0.8 : 0.7,
        ),
      ),
    ),
  );
}
