import 'dart:ui';

import 'package:border_player/app_motion.dart';
import 'package:border_player/app_settings.dart';
import 'package:border_player/component/glass_dock_surface.dart';
import 'package:border_player/page/now_playing_page/component/now_playing_popup.dart';
import 'package:flutter/material.dart';

Future<T?> showSettingsGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
}) {
  final useHomeGlass = AppSettings.instance.dynamicTheme &&
      AppSettings.instance.homeCoverBackdrop;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor ??
        (useHomeGlass
            ? Colors.transparent
            : Colors.black.withValues(alpha: 0.46)),
    transitionDuration: AppMotion.popup,
    pageBuilder: (context, _, __) => builder(context),
    transitionBuilder: (context, animation, _, child) {
      return AppMotion.popupTransition(
        animation: animation,
        child: child,
      );
    },
  );
}

class SettingsGlassDialog extends StatelessWidget {
  const SettingsGlassDialog({
    super.key,
    required this.title,
    required this.child,
    required this.actions,
    this.titleActions = const [],
    this.width = 650,
    this.height = 560,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final List<Widget> titleActions;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final useHomeGlass = AppSettings.instance.dynamicTheme &&
        AppSettings.instance.homeCoverBackdrop;
    final useAudioAccent = AppSettings.instance.dynamicTheme;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titleActions.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (var i = 0; i < titleActions.length; i++) ...[
                if (i != 0) const SizedBox(width: 10),
                titleActions[i],
              ],
            ],
          ),
          const SizedBox(height: 18),
        ],
        Expanded(child: child),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i != 0) const SizedBox(width: 18),
              GlassDockSurface(
                borderRadius: BorderRadius.circular(999),
                height: 38,
                shadowScale: 0.16,
                child: actions[i],
              ),
            ],
          ],
        ),
      ],
    );

    if (useHomeGlass) {
      return Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 42, vertical: 36),
        child: NowPlayingGlassPanel(
          title: title,
          width: width,
          height: height,
          padding: const EdgeInsets.fromLTRB(30, 28, 30, 24),
          child: content,
        ),
      );
    }

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
              color: useAudioAccent
                  ? scheme.secondaryContainer.withValues(alpha: 0.88)
                  : scheme.surface.withOpacity(0.9),
              gradient: useAudioAccent
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.surface.withOpacity(0.94),
                        scheme.surfaceContainerHighest.withOpacity(0.78),
                      ],
                    ),
              boxShadow: [
                BoxShadow(
                  color: useAudioAccent
                      ? scheme.shadow.withValues(alpha: 0.10)
                      : scheme.shadow.withOpacity(0.14),
                  blurRadius: useAudioAccent ? 42 : 38,
                  spreadRadius: useAudioAccent ? -8 : 0,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child:
                          Text(title, style: settingsDialogTitleStyle(scheme)),
                    ),
                    for (var i = 0; i < titleActions.length; i++) ...[
                      if (i != 0) const SizedBox(width: 10),
                      titleActions[i],
                    ],
                  ],
                ),
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
    foregroundColor: scheme.onSurface,
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
