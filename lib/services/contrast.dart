import 'dart:math' as math;

import 'package:flutter/material.dart';

/// WCAG AA contrast ratio threshold for normal text (spec Assumptions).
const wcagAAContrastThreshold = 4.5;

double _linearize(double channel) {
  return channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}

double _relativeLuminance(Color color) {
  final r = _linearize(color.r);
  final g = _linearize(color.g);
  final b = _linearize(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// WCAG 2.x contrast ratio between two colors, from 1:1 (identical) to
/// 21:1 (black vs. white). Order of arguments does not matter.
double contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

bool meetsMinimumContrast(Color a, Color b) {
  return contrastRatio(a, b) >= wcagAAContrastThreshold;
}
