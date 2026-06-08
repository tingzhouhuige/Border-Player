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
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF9C9),
              Color(0xFFFFF3A8),
              Color(0xFFFFE98F),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFFFFBE0),
            width: 0.8,
          ),
        ),
        child: Center(
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
        ),
      ),
    );
  }
}
