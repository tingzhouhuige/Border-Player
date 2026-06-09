import 'package:border_player/app_settings.dart';
import 'package:border_player/component/glass_dock_surface.dart';
import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 40,
    this.iconSize = 24,
  });

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final useDynamicAccent = AppSettings.instance.dynamicTheme;
    final useGlassBackdrop = AppSettings.instance.dynamicTheme &&
        AppSettings.instance.homeCoverBackdrop;
    final shadow = isDark ? Colors.black : scheme.onSecondaryContainer;
    final dynamicDiscBase = Color.lerp(
      scheme.secondaryContainer,
      shadow,
      isDark ? 0.10 : 0.045,
    )!;
    final dynamicDiscDepth = Color.lerp(
      scheme.primaryContainer,
      shadow,
      isDark ? 0.14 : 0.065,
    )!;
    final discColors = useDynamicAccent
        ? [
            Color.lerp(
              scheme.secondaryContainer,
              dynamicDiscBase,
              0.68,
            )!,
            dynamicDiscBase,
            dynamicDiscDepth,
          ]
        : const [
            Color(0xFFFFF9C9),
            Color(0xFFFFF3A8),
            Color(0xFFFFE98F),
          ];

    final note = Center(
      child: SizedBox(
        width: iconSize * 1.04,
        height: iconSize * 1.04,
        child: OverflowBox(
          maxWidth: size,
          maxHeight: size,
          child: Image.asset(
            'assets/images/brand_note.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
          ),
        ),
      ),
    );

    if (useGlassBackdrop) {
      return SizedBox(
        width: size,
        height: size,
        child: GlassDockSurface(
          borderRadius: BorderRadius.circular(size / 2),
          shadowScale: 0.28,
          child: note,
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: discColors,
          ),
          border: useDynamicAccent
              ? null
              : Border.all(
                  color: const Color(0xFFFFFBE0),
                  width: 0.8,
                ),
          boxShadow: useDynamicAccent
              ? [
                  BoxShadow(
                    color:
                        scheme.primary.withValues(alpha: isDark ? 0.16 : 0.10),
                    blurRadius: 10,
                    spreadRadius: -7,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: note,
      ),
    );
  }
}
