import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';
import 'package:saf_util/saf_util_platform_interface.dart' show SafDocumentFile;

import '../db/database.dart';
import '../models/setlist.dart';
import '../models/song.dart';
import 'chordpro_parser.dart';
import 'import_service.dart';
import 'setlist_json.dart';
import 'song_matcher.dart';

/// A synced song whose Drive file changed remotely while it also had local
/// edits since the last pull. Sync leaves the local copy untouched and
/// records this instead of picking a side, so the user can resolve it.
class SongConflict {
  final int songId;
  final String title;
  final String sourceUri;
  final String remoteContent;
  final DateTime remoteModifiedAt;

  const SongConflict({
    required this.songId,
    required this.title,
    required this.sourceUri,
    required this.remoteContent,
    required this.remoteModifiedAt,
  });
}

/// Same as [SongConflict] but for a `.gigbook-setlist.json` export.
class SetlistConflict {
  final int setlistId;
  final String name;
  final String sourceUri;
  final String remoteContent;
  final DateTime remoteModifiedAt;

  const SetlistConflict({
    required this.setlistId,
    required this.name,
    required this.sourceUri,
    required this.remoteContent,
    required this.remoteModifiedAt,
  });
}

class DriveSyncSummary {
  final int newSongs;
  final int updatedSongs;
  final int newSetlists;
  final int updatedSetlists;
  final int missingCount;
  final List<SongConflict> songConflicts;
  final List<SetlistConflict> setlistConflicts;
  final List<String> unmatchedSetlistSongs;

  const DriveSyncSummary({
    this.newSongs = 0,
    this.updatedSongs = 0,
    this.newSetlists = 0,
    this.updatedSetlists = 0,
    this.missingCount = 0,
    this.songConflicts = const [],
    this.setlistConflicts = const [],
    this.unmatchedSetlistSongs = const [],
  });

  bool get hasChanges =>
      newSongs > 0 || updatedSongs > 0 || newSetlists > 0 || updatedSetlists > 0;

  bool get hasConflicts => songConflicts.isNotEmpty || setlistConflicts.isNotEmpty;
}

enum _FileKind { song, setlist, ignored }

/// Recursively scans a Drive folder (picked once via SAF) for song lyric
/// files and `.gigbook-setlist.json` exports, and applies any new or changed
/// ones to the local library. Matches by the file's stable source URI (not
/// title/artist) so local edits to a song's title don't break tracking.
/// Files removed from the folder are never auto-deleted locally — just
/// reported, so nothing disappears from a musician's library unexpectedly.
class DriveSyncService {
  static final _safUtil = SafUtil();
  static final _safStream = SafStream();
  static const _safWriteChannel = MethodChannel('com.gigbook.gigbook/saf_write');

  static Future<DriveSyncSummary> sync(String rootUri) async {
    final files = await _walk(rootUri);

    final songResult = await _syncSongs(files);
    final setlistResult = await _syncSetlists(files);

    return DriveSyncSummary(
      newSongs: songResult.newCount,
      updatedSongs: songResult.updatedCount,
      missingCount: songResult.missingCount + setlistResult.missingCount,
      newSetlists: setlistResult.newCount,
      updatedSetlists: setlistResult.updatedCount,
      songConflicts: songResult.conflicts,
      setlistConflicts: setlistResult.conflicts,
      unmatchedSetlistSongs: setlistResult.unmatched,
    );
  }

  /// Walks the folder tree, keeping track of each file's immediate parent
  /// folder URI — needed so linked songs can later be written back via
  /// `SafStream.writeFileBytes`, which addresses files by (parent tree URI,
  /// file name) rather than by the file's own document URI.
  static Future<List<({SafDocumentFile file, String parentUri})>> _walk(
      String rootUri) async {
    final result = <({SafDocumentFile file, String parentUri})>[];
    final queue = <String>[rootUri];
    while (queue.isNotEmpty) {
      final uri = queue.removeLast();
      final entries = await _safUtil.list(uri);
      for (final entry in entries) {
        if (entry.isDir) {
          queue.add(entry.uri);
        } else {
          result.add((file: entry, parentUri: uri));
        }
      }
    }
    return result;
  }

  static _FileKind _classify(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.gigbook-setlist.json')) return _FileKind.setlist;
    final ext = lower.contains('.') ? lower.split('.').last : '';
    if (ImportService.songExtensions.contains(ext)) return _FileKind.song;
    return _FileKind.ignored;
  }

  // ─── Songs ──────────────────────────────────────────────────────────────

  static Future<
      ({
        int newCount,
        int updatedCount,
        int missingCount,
        List<SongConflict> conflicts
      })> _syncSongs(
      List<({SafDocumentFile file, String parentUri})> walked) async {
    final songFiles =
        walked.where((w) => _classify(w.file.name) == _FileKind.song).toList();

    final linkedSongs = await AppDatabase.instance.getSongsWithSourceUri();
    final linkedByUri = {for (final s in linkedSongs) s.sourceUri!: s};
    final allSongs = await AppDatabase.instance.getAllSongs();
    final unlinkedSongs = allSongs.where((s) => s.sourceUri == null).toList();

    var newCount = 0;
    var updatedCount = 0;
    final conflicts = <SongConflict>[];
    final seenUris = <String>{};

    for (final walkedFile in songFiles) {
      final file = walkedFile.file;
      final parentUri = walkedFile.parentUri;
      seenUris.add(file.uri);
      final remoteModifiedAt =
          DateTime.fromMillisecondsSinceEpoch(file.lastModified);
      final existing = linkedByUri[file.uri];

      if (existing != null) {
        final unchanged = existing.sourceModifiedAt != null &&
            !remoteModifiedAt.isAfter(existing.sourceModifiedAt!);
        if (unchanged) {
          // Backfill the write-back location for songs linked before it
          // existed, so pushSongEdit can start working for them too.
          if (existing.sourceParentUri == null ||
              existing.sourceFileName == null) {
            await AppDatabase.instance
                .updateSongDriveLocation(existing.id!, parentUri, file.name);
          }
          continue;
        }

        final editedSinceLastPull = existing.localEditedAt != null &&
            (existing.sourceModifiedAt == null ||
                existing.localEditedAt!.isAfter(existing.sourceModifiedAt!));
        if (editedSinceLastPull) {
          final content = await _readText(file.uri);
          if (content != null) {
            conflicts.add(SongConflict(
              songId: existing.id!,
              title: existing.title,
              sourceUri: file.uri,
              remoteContent: content,
              remoteModifiedAt: remoteModifiedAt,
            ));
          }
          continue;
        }

        final content = await _readText(file.uri);
        if (content == null) continue;
        final meta = ChordProParser.extractMeta(content);
        await AppDatabase.instance.updateSong(existing.copyWith(
          title: meta.title.isNotEmpty ? meta.title : existing.title,
          artist: meta.artist,
          key: meta.key,
          capo: meta.capo,
          tempo: meta.tempo,
          content: content,
          sourceModifiedAt: remoteModifiedAt,
          sourceParentUri: parentUri,
          sourceFileName: file.name,
        ));
        updatedCount++;
        continue;
      }

      // New to the sync engine — first check if it's already been imported
      // by hand, so we link instead of creating a duplicate.
      final content = await _readText(file.uri);
      if (content == null) continue;
      final meta = ChordProParser.extractMeta(content);
      final fallbackName =
          file.name.contains('.') ? file.name.split('.').first : file.name;
      final title = meta.title.isNotEmpty ? meta.title : fallbackName;

      final match = SongMatcher.find(unlinkedSongs, title, meta.artist);
      if (match != null) {
        await AppDatabase.instance
            .updateSongSource(match.id!, file.uri, remoteModifiedAt);
        await AppDatabase.instance
            .updateSongDriveLocation(match.id!, parentUri, file.name);
        continue;
      }

      final song = Song(
        title: title,
        artist: meta.artist,
        key: meta.key,
        capo: meta.capo,
        tempo: meta.tempo,
        content: content,
        createdAt: DateTime.now(),
        sourceUri: file.uri,
        sourceModifiedAt: remoteModifiedAt,
        sourceParentUri: parentUri,
        sourceFileName: file.name,
      );
      await AppDatabase.instance.insertSong(song);
      newCount++;
    }

    final missingCount =
        linkedSongs.where((s) => !seenUris.contains(s.sourceUri)).length;

    return (
      newCount: newCount,
      updatedCount: updatedCount,
      missingCount: missingCount,
      conflicts: conflicts,
    );
  }

  // ─── Setlists ───────────────────────────────────────────────────────────

  static Future<
      ({
        int newCount,
        int updatedCount,
        int missingCount,
        List<SetlistConflict> conflicts,
        List<String> unmatched
      })> _syncSetlists(
      List<({SafDocumentFile file, String parentUri})> walked) async {
    final setlistFiles = walked
        .map((w) => w.file)
        .where((f) => _classify(f.name) == _FileKind.setlist)
        .toList();

    final linkedSetlists = await AppDatabase.instance.getSetlistsWithSourceUri();
    final linkedByUri = {for (final s in linkedSetlists) s.sourceUri!: s};
    final allSetlists = await AppDatabase.instance.getAllSetlists();
    final unlinkedSetlists =
        allSetlists.where((s) => s.sourceUri == null).toList();
    final library = await AppDatabase.instance.getAllSongs();

    var newCount = 0;
    var updatedCount = 0;
    final conflicts = <SetlistConflict>[];
    final unmatched = <String>[];
    final seenUris = <String>{};

    for (final file in setlistFiles) {
      seenUris.add(file.uri);
      final remoteModifiedAt =
          DateTime.fromMillisecondsSinceEpoch(file.lastModified);
      final existing = linkedByUri[file.uri];

      if (existing != null) {
        final unchanged = existing.sourceModifiedAt != null &&
            !remoteModifiedAt.isAfter(existing.sourceModifiedAt!);
        if (unchanged) continue;

        final editedSinceLastPull = existing.localEditedAt != null &&
            (existing.sourceModifiedAt == null ||
                existing.localEditedAt!.isAfter(existing.sourceModifiedAt!));
        if (editedSinceLastPull) {
          final content = await _readText(file.uri);
          if (content != null) {
            conflicts.add(SetlistConflict(
              setlistId: existing.id!,
              name: existing.name,
              sourceUri: file.uri,
              remoteContent: content,
              remoteModifiedAt: remoteModifiedAt,
            ));
          }
          continue;
        }

        final content = await _readText(file.uri);
        if (content == null) continue;
        ParsedSetlistJson parsed;
        try {
          parsed = parseSetlistJson(content);
        } catch (_) {
          continue;
        }
        final matchResult = _matchedSongIds(parsed, library);
        unmatched.addAll(matchResult.unmatched);
        await AppDatabase.instance.updateSetlistName(existing.id!, parsed.name);
        await AppDatabase.instance
            .replaceSetlistSongs(existing.id!, matchResult.ids);
        await AppDatabase.instance
            .updateSetlistSource(existing.id!, file.uri, remoteModifiedAt);
        updatedCount++;
        continue;
      }

      final content = await _readText(file.uri);
      if (content == null) continue;
      ParsedSetlistJson parsed;
      try {
        parsed = parseSetlistJson(content);
      } catch (_) {
        continue;
      }

      final nameMatch = unlinkedSetlists
          .where((s) => s.name.trim().toLowerCase() == parsed.name.trim().toLowerCase())
          .toList();
      final matchResult = _matchedSongIds(parsed, library);
      unmatched.addAll(matchResult.unmatched);

      if (nameMatch.isNotEmpty) {
        final setlist = nameMatch.first;
        await AppDatabase.instance
            .replaceSetlistSongs(setlist.id!, matchResult.ids);
        await AppDatabase.instance
            .updateSetlistSource(setlist.id!, file.uri, remoteModifiedAt);
        continue;
      }

      final id = await AppDatabase.instance.insertSetlist(Setlist(
        name: parsed.name,
        createdAt: DateTime.now(),
        sourceUri: file.uri,
        sourceModifiedAt: remoteModifiedAt,
      ));
      await AppDatabase.instance.replaceSetlistSongs(id, matchResult.ids);
      newCount++;
    }

    final missingCount =
        linkedSetlists.where((s) => !seenUris.contains(s.sourceUri)).length;

    return (
      newCount: newCount,
      updatedCount: updatedCount,
      missingCount: missingCount,
      conflicts: conflicts,
      unmatched: unmatched,
    );
  }

  static ({List<int> ids, List<String> unmatched}) _matchedSongIds(
      ParsedSetlistJson parsed, List<Song> library) {
    final ids = <int>[];
    final unmatched = <String>[];
    for (final entry in parsed.entries) {
      final song = SongMatcher.find(library, entry.title, entry.artist);
      if (song != null) {
        ids.add(song.id!);
      } else {
        unmatched.add(entry.artist.isEmpty
            ? entry.title
            : '${entry.title} — ${entry.artist}');
      }
    }
    return (ids: ids, unmatched: unmatched);
  }

  // ─── Conflict resolution ──────────────────────────────────────────────────

  /// Discards the remote change and keeps the local edit — acknowledges the
  /// remote version as seen so it stops being reported as a conflict.
  static Future<void> keepLocalSong(SongConflict conflict) async {
    await AppDatabase.instance.updateSongSource(
        conflict.songId, conflict.sourceUri, conflict.remoteModifiedAt);
  }

  /// Discards the local edit and applies the remote version, the same way a
  /// normal (non-conflicting) sync update would.
  static Future<void> useRemoteSong(SongConflict conflict) async {
    final song = await AppDatabase.instance.getSongById(conflict.songId);
    if (song == null) return;
    final meta = ChordProParser.extractMeta(conflict.remoteContent);
    await AppDatabase.instance.updateSong(Song(
      id: song.id,
      title: meta.title.isNotEmpty ? meta.title : song.title,
      artist: meta.artist,
      key: meta.key,
      capo: meta.capo,
      tempo: meta.tempo,
      isFavorite: song.isFavorite,
      content: conflict.remoteContent,
      createdAt: song.createdAt,
      lastOpenedAt: song.lastOpenedAt,
      sourceUri: conflict.sourceUri,
      sourceModifiedAt: conflict.remoteModifiedAt,
      localEditedAt: null,
    ));
  }

  static Future<void> keepLocalSetlist(SetlistConflict conflict) async {
    await AppDatabase.instance.updateSetlistSource(
        conflict.setlistId, conflict.sourceUri, conflict.remoteModifiedAt);
  }

  static Future<void> useRemoteSetlist(SetlistConflict conflict) async {
    ParsedSetlistJson parsed;
    try {
      parsed = parseSetlistJson(conflict.remoteContent);
    } catch (_) {
      return;
    }
    final library = await AppDatabase.instance.getAllSongs();
    final matchResult = _matchedSongIds(parsed, library);
    await AppDatabase.instance
        .updateSetlistName(conflict.setlistId, parsed.name);
    await AppDatabase.instance
        .replaceSetlistSongs(conflict.setlistId, matchResult.ids);
    await AppDatabase.instance.updateSetlistSource(
        conflict.setlistId, conflict.sourceUri, conflict.remoteModifiedAt);
    await AppDatabase.instance.setSetlistLocalEditedAt(conflict.setlistId, null);
  }

  /// Writes a linked song's current content back to its file in the synced
  /// Drive folder — directly to the song's own known document URI via a
  /// native ContentResolver write (see `MainActivity.kt`), not by searching
  /// for it by name in its parent folder. `saf_stream`'s `writeFileBytes`
  /// overwrite path does the latter (via `DocumentFile.findFile`), which
  /// turned out to be unreliable against Google Drive's SAF provider —
  /// on a lookup miss it silently creates a duplicate file instead of
  /// overwriting the original, which is why edits weren't propagating.
  /// No-op if the song isn't linked; throws on any I/O failure so the
  /// caller can decide how to handle it (the local edit is never lost
  /// either way).
  static Future<void> pushSongEdit(Song song) async {
    final sourceUri = song.sourceUri;
    if (sourceUri == null) return;

    final bytes = Uint8List.fromList(utf8.encode(song.content));
    await _safWriteChannel
        .invokeMethod('writeToUri', {'uri': sourceUri, 'bytes': bytes});

    final fresh = await _safUtil.stat(sourceUri, false);
    final modifiedAt = fresh != null
        ? DateTime.fromMillisecondsSinceEpoch(fresh.lastModified)
        : DateTime.now();

    await AppDatabase.instance.updateSong(Song(
      id: song.id,
      title: song.title,
      artist: song.artist,
      key: song.key,
      capo: song.capo,
      tempo: song.tempo,
      isFavorite: song.isFavorite,
      content: song.content,
      createdAt: song.createdAt,
      lastOpenedAt: song.lastOpenedAt,
      sourceUri: sourceUri,
      sourceParentUri: song.sourceParentUri,
      sourceFileName: song.sourceFileName,
      sourceModifiedAt: modifiedAt,
      localEditedAt: null,
    ));
  }

  static Future<String?> _readText(String uri) async {
    try {
      final bytes = await _safStream.readFileBytes(uri);
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return null;
    }
  }
}
