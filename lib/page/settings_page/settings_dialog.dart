import 'dart:ui';

import 'package:flutter/material.dart';

class SettingsGlassDialog extends StatelessWidget {
  const SettingsGlassDialog({
    super.key,
    required this.title,
    required this.child,
    required this.actions,
    this.width = 650,
    this.height = 560,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 42, vertical: 36),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: width,
            height: height,
            padding: const EdgeInsets.fromLTRB(30, 28, 30, 24),
            decoration: BoxDecoration(
              color: scheme.surface.withOpacity(0.9),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.surface.withOpacity(0.94),
                  scheme.surfaceContainerHighest.withOpacity(0.78),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withOpacity(0.14),
                  blurRadius: 38,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: settingsDialogTitleStyle(scheme)),
                const SizedBox(height: 22),
                Expanded(child: child),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i != 0) const SizedBox(width: 18),
                      actions[i],
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle settingsDialogTitleStyle(ColorScheme scheme) {
  return TextStyle(
    color: scheme.onSurface,
    fontSize: 22,
    height: 1.15,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );
}

TextStyle settingsDialogTextStyle(ColorScheme scheme) {
  return TextStyle(
    color: scheme.onSurface,
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );
}

ButtonStyle settingsDialogActionStyle(ColorScheme scheme) {
  return TextButton.styleFrom(
    foregroundColor: scheme.primary,
    disabledForegroundColor: scheme.onSurface.withOpacity(0.28),
    textStyle: const TextStyle(
      fontSize: 15,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    minimumSize: const Size(42, 36),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}
