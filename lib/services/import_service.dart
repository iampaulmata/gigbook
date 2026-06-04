import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../db/database.dart';
import '../models/song.dart';
import 'chordpro_parser.dart';

class ImportService {
  static Future<List<Song>> pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['cho', 'pro', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return [];

    final imported = <Song>[];
    for (final file in result.files) {
      final song = await _importFile(file);
      if (song != null) imported.add(song);
    }
    return imported;
  }

  static Future<Song?> _importFile(PlatformFile file) async {
    String content;
    try {
      if (file.bytes != null) {
        content = utf8.decode(file.bytes!, allowMalformed: true);
      } else if (file.path != null) {
        final bytes = await File(file.path!).readAsBytes();
        content = utf8.decode(bytes, allowMalformed: true);
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }

    final meta = ChordProParser.extractMeta(content);
    final filename = p.basenameWithoutExtension(file.name);

    final song = Song(
      title: meta.title.isNotEmpty ? meta.title : filename,
      artist: meta.artist,
      key: meta.key,
      capo: meta.capo,
      content: content,
      createdAt: DateTime.now(),
    );

    final id = await AppDatabase.instance.insertSong(song);
    return song.copyWith(id: id);
  }
}
