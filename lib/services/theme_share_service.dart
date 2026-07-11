import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/custom_theme.dart';
import 'theme_json.dart';

export 'theme_json.dart' show ThemeFormatException;

class ThemeShareService {
  /// Writes the theme to a temp .json file and opens the native share sheet
  /// (FR-012). Mirrors SetlistShareService.share.
  static Future<void> share(CustomTheme theme) async {
    final data = {
      'type': themeJsonFileType,
      ...theme.toJson(),
    };

    final dir = await getTemporaryDirectory();
    final safeName = theme.name.replaceAll(RegExp(r'[^\w\-. ]'), '_').trim();
    final fileName =
        '${safeName.isEmpty ? 'theme' : safeName}.gigbook-theme.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(jsonEncode(data));

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        text: 'GigBook theme: ${theme.name}',
      ),
    );
  }

  /// Lets the user pick a shared theme .json file and parses it into a
  /// [CustomTheme] (FR-013). Name-collision handling is a UI-layer concern
  /// (see confirmNameCollision in custom_theme_screen.dart, FR-019) — this
  /// just returns the parsed theme, or null if the user cancelled the pick.
  static Future<CustomTheme?> pickAndParse() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;

    String content;
    if (file.bytes != null) {
      content = utf8.decode(file.bytes!, allowMalformed: true);
    } else if (file.path != null) {
      content = await File(file.path!).readAsString();
    } else {
      throw const ThemeFormatException('Could not read the selected file.');
    }

    final parsed = parseThemeJson(content);
    return CustomTheme(
      name: parsed.name,
      backgroundColor: colorFromHex(parsed.colors.background),
      textColor: colorFromHex(parsed.colors.text),
      chordColor: colorFromHex(parsed.colors.chord),
      sectionHeaderColor: colorFromHex(parsed.colors.sectionHeader),
      commentColor: colorFromHex(parsed.colors.comment),
    );
  }
}
