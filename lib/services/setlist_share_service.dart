import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/setlist.dart';
import '../models/song.dart';
import 'setlist_json.dart';
import 'song_matcher.dart';

export 'setlist_json.dart' show SetlistFormatException;

class SetlistImportResult {
  final String name;
  final List<Song> matchedSongs;
  final List<String> missingSongs;

  const SetlistImportResult({
    required this.name,
    required this.matchedSongs,
    required this.missingSongs,
  });
}

class SetlistShareService {
  /// Writes the setlist to a temp .json file and opens the native share sheet.
  /// The recipient is assumed to already have the referenced song files
  /// imported locally — only title/artist references travel in the file.
  static Future<void> share(Setlist setlist, List<Song> songs) async {
    final data = {
      'type': setlistJsonFileType,
      'version': setlistJsonFileVersion,
      'name': setlist.name,
      'songs': songs
          .map((s) => {'title': s.title, 'artist': s.artist})
          .toList(),
    };

    final dir = await getTemporaryDirectory();
    final safeName = setlist.name.replaceAll(RegExp(r'[^\w\-. ]'), '_').trim();
    final fileName =
        '${safeName.isEmpty ? 'setlist' : safeName}.gigbook-setlist.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(jsonEncode(data));

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        text: 'GigBook setlist: ${setlist.name}',
      ),
    );
  }

  /// Lets the user pick a shared setlist .json file and matches its songs
  /// against [library] by title+artist (case-insensitive).
  static Future<SetlistImportResult?> pickAndParse(List<Song> library) async {
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
      throw const SetlistFormatException('Could not read the selected file.');
    }

    final parsed = parseSetlistJson(content);

    final matched = <Song>[];
    final missing = <String>[];
    for (final entry in parsed.entries) {
      final song = SongMatcher.find(library, entry.title, entry.artist);
      if (song != null) {
        matched.add(song);
      } else {
        missing.add(entry.artist.isEmpty
            ? entry.title
            : '${entry.title} — ${entry.artist}');
      }
    }

    return SetlistImportResult(
        name: parsed.name, matchedSongs: matched, missingSongs: missing);
  }
}
