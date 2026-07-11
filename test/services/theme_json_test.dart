import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gigbook/services/theme_json.dart';

const _validJson = '''
{
  "type": "gigbook-theme",
  "version": 1,
  "name": "Stage Lighting",
  "colors": {
    "background": "#0D1117",
    "text": "#E6EDF3",
    "chord": "#58A6FF",
    "sectionHeader": "#F0883E",
    "comment": "#8B949E"
  }
}
''';

void main() {
  group('parseThemeJson — valid input', () {
    test('parses a well-formed theme file', () {
      final parsed = parseThemeJson(_validJson);
      expect(parsed.name, 'Stage Lighting');
      expect(parsed.colors.background, '#0D1117');
      expect(parsed.colors.text, '#E6EDF3');
      expect(parsed.colors.chord, '#58A6FF');
      expect(parsed.colors.sectionHeader, '#F0883E');
      expect(parsed.colors.comment, '#8B949E');
    });

    test('round-trips: encoding a parsed theme reproduces identical colors',
        () {
      final parsed = parseThemeJson(_validJson);
      final reEncoded = jsonEncode({
        'type': themeJsonFileType,
        'version': themeJsonFileVersion,
        'name': parsed.name,
        'colors': {
          'background': parsed.colors.background,
          'text': parsed.colors.text,
          'chord': parsed.colors.chord,
          'sectionHeader': parsed.colors.sectionHeader,
          'comment': parsed.colors.comment,
        },
      });
      final reParsed = parseThemeJson(reEncoded);
      expect(reParsed.colors.background, parsed.colors.background);
      expect(reParsed.colors.text, parsed.colors.text);
      expect(reParsed.colors.chord, parsed.colors.chord);
      expect(reParsed.colors.sectionHeader, parsed.colors.sectionHeader);
      expect(reParsed.colors.comment, parsed.colors.comment);
    });

    test('defaults an empty/missing name to "Imported theme"', () {
      final json = jsonDecode(_validJson) as Map<String, dynamic>;
      json['name'] = '';
      final parsed = parseThemeJson(jsonEncode(json));
      expect(parsed.name, 'Imported theme');
    });
  });

  group('parseThemeJson — rejection cases', () {
    test('rejects malformed JSON', () {
      expect(() => parseThemeJson('not json at all {{{'),
          throwsA(isA<ThemeFormatException>()));
    });

    test('rejects a missing type field', () {
      final json = jsonDecode(_validJson) as Map<String, dynamic>;
      json.remove('type');
      expect(() => parseThemeJson(jsonEncode(json)),
          throwsA(isA<ThemeFormatException>()));
    });

    test('rejects a wrong type field', () {
      final json = jsonDecode(_validJson) as Map<String, dynamic>;
      json['type'] = 'gigbook-setlist';
      expect(() => parseThemeJson(jsonEncode(json)),
          throwsA(isA<ThemeFormatException>()));
    });

    test('rejects a newer, unrecognized version', () {
      final json = jsonDecode(_validJson) as Map<String, dynamic>;
      json['version'] = 2;
      expect(() => parseThemeJson(jsonEncode(json)),
          throwsA(isA<ThemeFormatException>()));
    });

    test('rejects a missing colors.* field', () {
      final json = jsonDecode(_validJson) as Map<String, dynamic>;
      (json['colors'] as Map<String, dynamic>).remove('chord');
      expect(() => parseThemeJson(jsonEncode(json)),
          throwsA(isA<ThemeFormatException>()));
    });

    test('rejects a malformed colors.* value', () {
      final json = jsonDecode(_validJson) as Map<String, dynamic>;
      (json['colors'] as Map<String, dynamic>)['comment'] = 'not-a-hex-color';
      expect(() => parseThemeJson(jsonEncode(json)),
          throwsA(isA<ThemeFormatException>()));
    });

    test('rejects a missing colors object entirely', () {
      final json = jsonDecode(_validJson) as Map<String, dynamic>;
      json.remove('colors');
      expect(() => parseThemeJson(jsonEncode(json)),
          throwsA(isA<ThemeFormatException>()));
    });
  });
}
