import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

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
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFFFE89D),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Symbols.music_note,
        color: Color(0xFF2E2A22),
        size: iconSize,
        weight: 700,
        fill: 1,
      ),
    );
  }
}
