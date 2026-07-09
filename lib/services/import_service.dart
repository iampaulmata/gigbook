import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../db/database.dart';
import '../models/song.dart';
import 'chordpro_parser.dart';
import 'song_matcher.dart';

class ImportResult {
  final List<Song> imported;
  final int skipped;
  final String? error;

  const ImportResult({required this.imported, required this.skipped, this.error});

  const ImportResult.error(this.error)
      : imported = const [],
        skipped = 0;
}

class ImportService {
  static const songExtensions = ['cho', 'pro', 'txt'];
  static const _extensions = songExtensions;

  static Future<ImportResult> pickAndImportFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _extensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return const ImportResult(imported: [], skipped: 0);
    }

    final existingKeys = await _existingKeys();
    final imported = <Song>[];
    var skipped = 0;
    for (final file in result.files) {
      final content = await _readPlatformFile(file);
      if (content == null) {
        skipped++;
        continue;
      }
      final song = await _importContent(
        content: content,
        fallbackName: p.basenameWithoutExtension(file.name),
        existingKeys: existingKeys,
      );
      if (song != null) {
        imported.add(song);
      } else {
        skipped++;
      }
    }
    return ImportResult(imported: imported, skipped: skipped);
  }

  /// Imports every .cho/.pro/.txt file found (recursively) in a picked folder.
  /// Requires "All files access" on Android since the folder may live outside
  /// this app's sandbox and outside what SAF content-resolvers expose.
  static Future<ImportResult> pickAndImportFolder() async {
    if (Platform.isAndroid) {
      final granted = await _ensureStoragePermission();
      if (!granted) {
        return const ImportResult.error(
          'Storage access is required for folder import. '
          'Grant "All files access" for GigBook in system settings, then try again.',
        );
      }
    }

    final dirPath = await FilePicker.platform.getDirectoryPath();
    if (dirPath == null) return const ImportResult(imported: [], skipped: 0);

    final dir = Directory(dirPath);
    List<File> files;
    try {
      files = await dir
          .list(recursive: true)
          .where((e) =>
              e is File &&
              _extensions.contains(
                  p.extension(e.path).replaceFirst('.', '').toLowerCase()))
          .cast<File>()
          .toList();
    } catch (_) {
      return const ImportResult.error(
        'Could not read that folder. Try picking a different folder or use "Import files" instead.',
      );
    }

    final existingKeys = await _existingKeys();
    final imported = <Song>[];
    var skipped = 0;
    for (final file in files) {
      String? content;
      try {
        content = utf8.decode(await file.readAsBytes(), allowMalformed: true);
      } catch (_) {
        content = null;
      }
      if (content == null) {
        skipped++;
        continue;
      }
      final song = await _importContent(
        content: content,
        fallbackName: p.basenameWithoutExtension(file.path),
        existingKeys: existingKeys,
      );
      if (song != null) {
        imported.add(song);
      } else {
        skipped++;
      }
    }
    return ImportResult(imported: imported, skipped: skipped);
  }

  static Future<bool> _ensureStoragePermission() async {
    if (await Permission.manageExternalStorage.isGranted) return true;
    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  static Future<String?> _readPlatformFile(PlatformFile file) async {
    try {
      if (file.bytes != null) {
        return utf8.decode(file.bytes!, allowMalformed: true);
      } else if (file.path != null) {
        final bytes = await File(file.path!).readAsBytes();
        return utf8.decode(bytes, allowMalformed: true);
      }
    } catch (_) {}
    return null;
  }

  static Future<Song?> _importContent({
    required String content,
    required String fallbackName,
    required Set<String> existingKeys,
  }) async {
    final meta = ChordProParser.extractMeta(content);
    final title = meta.title.isNotEmpty ? meta.title : fallbackName;
    final key = SongMatcher.key(title, meta.artist);
    if (existingKeys.contains(key)) return null;

    final song = Song(
      title: title,
      artist: meta.artist,
      key: meta.key,
      capo: meta.capo,
      tempo: meta.tempo,
      content: content,
      createdAt: DateTime.now(),
    );

    final id = await AppDatabase.instance.insertSong(song);
    existingKeys.add(key);
    return song.copyWith(id: id);
  }

  static Future<Set<String>> _existingKeys() async {
    final songs = await AppDatabase.instance.getAllSongs();
    return songs.map((s) => SongMatcher.key(s.title, s.artist)).toSet();
  }
}
