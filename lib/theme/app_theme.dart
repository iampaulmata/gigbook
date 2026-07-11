import 'package:flutter/material.dart';

import '../models/custom_theme.dart';

/// Color roles the ChordPro renderer needs beyond Material's standard
/// [ColorScheme] slots, so a custom theme can set chord/section-header/
/// comment colors independently instead of all three collapsing onto
/// [ColorScheme.primary] / [ColorScheme.onSurfaceVariant].
@immutable
class ChordProColors extends ThemeExtension<ChordProColors> {
  final Color chord;
  final Color sectionHeader;
  final Color comment;

  const ChordProColors({
    required this.chord,
    required this.sectionHeader,
    required this.comment,
  });

  @override
  ChordProColors copyWith({Color? chord, Color? sectionHeader, Color? comment}) {
    return ChordProColors(
      chord: chord ?? this.chord,
      sectionHeader: sectionHeader ?? this.sectionHeader,
      comment: comment ?? this.comment,
    );
  }

  @override
  ChordProColors lerp(ThemeExtension<ChordProColors>? other, double t) {
    if (other is! ChordProColors) return this;
    return ChordProColors(
      chord: Color.lerp(chord, other.chord, t)!,
      sectionHeader: Color.lerp(sectionHeader, other.sectionHeader, t)!,
      comment: Color.lerp(comment, other.comment, t)!,
    );
  }
}

class AppTheme {
  static const _seedColor = Color(0xFF1A6B8A); // teal-blue

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      navigationBarTheme: const NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      extensions: [
        ChordProColors(
          chord: scheme.primary,
          sectionHeader: scheme.primary,
          comment: scheme.onSurfaceVariant,
        ),
      ],
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ).copyWith(
      // Slightly darker surface for stage use — easier on the eyes
      surface: const Color(0xFF0D1117),
      surfaceContainerHighest: const Color(0xFF161B22),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      navigationBarTheme: const NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      extensions: [
        ChordProColors(
          chord: scheme.primary,
          sectionHeader: scheme.primary,
          comment: scheme.onSurfaceVariant,
        ),
      ],
    );
  }

  /// Builds a [ThemeData] from a user's [CustomTheme] (research.md §1).
  /// Background/text/chord are pinned to the user's exact chosen colors;
  /// the rest of the Material 3 role palette (containers, outlines, etc.)
  /// is derived from the chord color as an accent via [ColorScheme.fromSeed]
  /// so the theme still reads as one coherent system.
  static ThemeData custom(CustomTheme customTheme) {
    final brightness =
        ThemeData.estimateBrightnessForColor(customTheme.backgroundColor);
    final scheme = ColorScheme.fromSeed(
      seedColor: customTheme.chordColor,
      brightness: brightness,
    ).copyWith(
      surface: customTheme.backgroundColor,
      onSurface: customTheme.textColor,
      primary: customTheme.chordColor,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: customTheme.backgroundColor,
      navigationBarTheme: const NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      extensions: [
        ChordProColors(
          chord: customTheme.chordColor,
          sectionHeader: customTheme.sectionHeaderColor,
          comment: customTheme.commentColor,
        ),
      ],
    );
  }
}
