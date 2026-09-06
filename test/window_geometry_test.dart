import 'package:border_player/window_geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const primary = Rect.fromLTWH(0, 0, 1920, 1040);
  const secondary = Rect.fromLTWH(-1080, 0, 1080, 1920);

  test('accepts normal and partially off-screen window bounds', () {
    expect(
      hasMeaningfulVisibleArea(
        const Rect.fromLTWH(300, 200, 900, 700),
        const [primary, secondary],
      ),
      isTrue,
    );
    expect(
      hasMeaningfulVisibleArea(
        const Rect.fromLTWH(-50, 100, 100, 700),
        const [primary, secondary],
      ),
      isTrue,
    );
  });

  test('rejects Windows minimized sentinel coordinates', () {
    expect(
      hasMeaningfulVisibleArea(
        const Rect.fromLTWH(-32000, -32000, 900, 700),
        const [primary, secondary],
      ),
      isFalse,
    );
  });

  test('rejects bounds without a usable visible grab area', () {
    expect(
      hasMeaningfulVisibleArea(
        const Rect.fromLTWH(1900, 1030, 900, 700),
        const [primary],
      ),
      isFalse,
    );
  });

  test('constrains startup size to the current work area', () {
    expect(
      constrainWindowSizeToWorkArea(
        const Size(9000, 7000),
        primary,
      ),
      const Size(1920, 1040),
    );
    expect(
      constrainWindowSizeToWorkArea(
        const Size(100, 100),
        primary,
      ),
      minimumAppWindowSize,
    );
  });
}
