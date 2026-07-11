import 'dart:convert';

/// Thrown when content isn't a recognizable GigBook theme export.
class ThemeFormatException implements Exception {
  final String message;
  const ThemeFormatException(this.message);

  @override
  String toString() => message;
}

class ThemeJsonColors {
  final String background;
  final String text;
  final String chord;
  final String sectionHeader;
  final String comment;

  const ThemeJsonColors({
    required this.background,
    required this.text,
    required this.chord,
    required this.sectionHeader,
    required this.comment,
  });
}

class ParsedThemeJson {
  final String name;
  final ThemeJsonColors colors;
  const ParsedThemeJson({required this.name, required this.colors});
}

const themeJsonFileType = 'gigbook-theme';
const themeJsonFileVersion = 1;

const _hexColorRe = r'^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$';

String _requireHexColor(Map colors, String key) {
  final value = colors[key];
  if (value is! String || !RegExp(_hexColorRe).hasMatch(value)) {
    throw const ThemeFormatException('That file is not a valid GigBook theme.');
  }
  return value;
}

/// Parses and validates a `.gigbook-theme.json` export — shared by manual
/// theme import (via the share sheet / file picker) so both stay in sync
/// with a single file-format definition (contracts/theme-json-schema.md).
ParsedThemeJson parseThemeJson(String content) {
  final Map<String, dynamic> data;
  try {
    data = jsonDecode(content) as Map<String, dynamic>;
  } catch (_) {
    throw const ThemeFormatException('That file is not a valid GigBook theme.');
  }

  if (data['type'] != themeJsonFileType) {
    throw const ThemeFormatException('That file is not a GigBook theme.');
  }

  final version = data['version'];
  if (version is! int || version > themeJsonFileVersion) {
    throw const ThemeFormatException(
        'This theme was created by a newer version of GigBook. Update the app to import it.');
  }

  final rawName = (data['name'] as String?)?.trim() ?? '';
  final name = rawName.isNotEmpty ? rawName : 'Imported theme';

  final rawColors = data['colors'];
  if (rawColors is! Map) {
    throw const ThemeFormatException('That file is not a valid GigBook theme.');
  }

  final colors = ThemeJsonColors(
    background: _requireHexColor(rawColors, 'background'),
    text: _requireHexColor(rawColors, 'text'),
    chord: _requireHexColor(rawColors, 'chord'),
    sectionHeader: _requireHexColor(rawColors, 'sectionHeader'),
    comment: _requireHexColor(rawColors, 'comment'),
  );

  return ParsedThemeJson(name: name, colors: colors);
}
