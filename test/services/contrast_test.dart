import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gigbook/services/contrast.dart';

void main() {
  group('contrastRatio', () {
    test('black vs white is exactly 21:1', () {
      expect(contrastRatio(Colors.black, Colors.white), closeTo(21.0, 0.01));
    });

    test('a color against itself is exactly 1:1', () {
      expect(contrastRatio(Colors.red, Colors.red), closeTo(1.0, 0.001));
    });

    test('is symmetric regardless of argument order', () {
      final a = contrastRatio(Colors.black, const Color(0xFF808080));
      final b = contrastRatio(const Color(0xFF808080), Colors.black);
      expect(a, closeTo(b, 0.0001));
    });
  });

  group('meetsMinimumContrast (WCAG AA, 4.5:1)', () {
    test('passes for a clearly readable pair', () {
      // ~8:1 — mid-dark gray on white, well above the AA threshold.
      expect(
        meetsMinimumContrast(const Color(0xFF505050), Colors.white),
        isTrue,
      );
    });

    test('fails for a clearly unreadable pair', () {
      // ~2.6:1 — light gray on white, well below the AA threshold.
      expect(
        meetsMinimumContrast(const Color(0xFFA0A0A0), Colors.white),
        isFalse,
      );
    });

    test('fails when both colors are identical', () {
      expect(
        meetsMinimumContrast(const Color(0xFF336699), const Color(0xFF336699)),
        isFalse,
      );
    });

    test('passes for maximum contrast (black on white)', () {
      expect(meetsMinimumContrast(Colors.black, Colors.white), isTrue);
    });
  });
}
