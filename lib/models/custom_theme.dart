import 'package:flutter/material.dart';

const customThemeFormatVersion = 1;

/// A user-created named set of colors for the app's "Custom" theme option.
/// See specs/004-custom-theme/data-model.md.
class CustomTheme {
  final String name;
  final Color backgroundColor;
  final Color textColor;
  final Color chordColor;
  final Color sectionHeaderColor;
  final Color commentColor;
  final int formatVersion;

  const CustomTheme({
    required this.name,
    required this.backgroundColor,
    required this.textColor,
    required this.chordColor,
    required this.sectionHeaderColor,
    required this.commentColor,
    this.formatVersion = customThemeFormatVersion,
  });

  CustomTheme copyWith({
    String? name,
    Color? backgroundColor,
    Color? textColor,
    Color? chordColor,
    Color? sectionHeaderColor,
    Color? commentColor,
  }) {
    return CustomTheme(
      name: name ?? this.name,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      chordColor: chordColor ?? this.chordColor,
      sectionHeaderColor: sectionHeaderColor ?? this.sectionHeaderColor,
      commentColor: commentColor ?? this.commentColor,
      formatVersion: formatVersion,
    );
  }

  /// Nests colors under a `colors` key to match the shareable
  /// `.gigbook-theme.json` contract exactly (contracts/theme-json-schema.md),
  /// so local storage and the exported file use one shape.
  Map<String, dynamic> toJson() => {
        'name': name,
        'colors': {
          'background': colorToHex(backgroundColor),
          'text': colorToHex(textColor),
          'chord': colorToHex(chordColor),
          'sectionHeader': colorToHex(sectionHeaderColor),
          'comment': colorToHex(commentColor),
        },
        'formatVersion': formatVersion,
      };

  factory CustomTheme.fromJson(Map<String, dynamic> json) {
    final colors = json['colors'] as Map;
    return CustomTheme(
      name: json['name'] as String,
      backgroundColor: colorFromHex(colors['background'] as String),
      textColor: colorFromHex(colors['text'] as String),
      chordColor: colorFromHex(colors['chord'] as String),
      sectionHeaderColor: colorFromHex(colors['sectionHeader'] as String),
      commentColor: colorFromHex(colors['comment'] as String),
      formatVersion: json['formatVersion'] as int? ?? customThemeFormatVersion,
    );
  }
}

String colorToHex(Color color) {
  final argb = color.toARGB32();
  return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

Color colorFromHex(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  final argb =
      int.parse(cleaned.length == 6 ? 'FF$cleaned' : cleaned, radix: 16);
  return Color(argb);
}
