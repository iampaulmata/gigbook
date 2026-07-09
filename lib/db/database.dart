import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/song.dart';
import '../models/setlist.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _db;

  AppDatabase._internal();

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'gigbook.db');
    return openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE songs ADD COLUMN tempo INTEGER');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE songs ADD COLUMN source_uri TEXT');
      await db
          .execute('ALTER TABLE songs ADD COLUMN source_modified_at INTEGER');
      await db.execute('ALTER TABLE setlists ADD COLUMN source_uri TEXT');
      await db.execute(
          'ALTER TABLE setlists ADD COLUMN source_modified_at INTEGER');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE songs ADD COLUMN local_edited_at INTEGER');
      await db
          .execute('ALTER TABLE setlists ADD COLUMN local_edited_at INTEGER');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE songs ADD COLUMN source_parent_uri TEXT');
      await db.execute('ALTER TABLE songs ADD COLUMN source_file_name TEXT');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        artist TEXT NOT NULL DEFAULT '',
        key TEXT,
        capo INTEGER,
        tempo INTEGER,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        last_opened_at INTEGER,
        source_uri TEXT,
        source_modified_at INTEGER,
        local_edited_at INTEGER,
        source_parent_uri TEXT,
        source_file_name TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE setlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        source_uri TEXT,
        source_modified_at INTEGER,
        local_edited_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE setlist_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        setlist_id INTEGER NOT NULL,
        song_id INTEGER NOT NULL,
        position INTEGER NOT NULL,
        FOREIGN KEY (setlist_id) REFERENCES setlists(id) ON DELETE CASCADE,
        FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_setlist_entries_setlist ON setlist_entries(setlist_id)');
  }

  // ─── Songs ────────────────────────────────────────────────────────────────

  Future<int> insertSong(Song song) async {
    final d = await db;
    return d.insert('songs', song.toMap());
  }

  Future<List<Song>> getAllSongs() async {
    final d = await db;
    final maps =
        await d.query('songs', orderBy: 'title COLLATE NOCASE ASC');
    return maps.map(Song.fromMap).toList();
  }

  Future<void> updateSong(Song song) async {
    final d = await db;
    await d.update('songs', song.toMap(),
        where: 'id = ?', whereArgs: [song.id]);
  }

  Future<void> deleteSong(int id) async {
    final d = await db;
    await d.delete('songs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateSongSource(
      int id, String sourceUri, DateTime sourceModifiedAt) async {
    final d = await db;
    await d.update(
      'songs',
      {
        'source_uri': sourceUri,
        'source_modified_at': sourceModifiedAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> touchSong(int id) async {
    final d = await db;
    await d.update(
      'songs',
      {'last_opened_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Backfills the parent folder URI and exact file name for a linked song,
  /// needed to write edits back to the file (see [DriveSyncService.pushSongEdit]
  /// in `drive_sync_service.dart`) — songs linked before this existed have
  /// these as null until their next sync pass.
  Future<void> updateSongDriveLocation(
      int id, String parentUri, String fileName) async {
    final d = await db;
    await d.update(
      'songs',
      {'source_parent_uri': parentUri, 'source_file_name': fileName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Song?> getSongById(int id) async {
    final d = await db;
    final maps = await d.query('songs', where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isEmpty ? null : Song.fromMap(maps.first);
  }

  Future<Song?> getSongBySourceUri(String sourceUri) async {
    final d = await db;
    final maps = await d.query('songs',
        where: 'source_uri = ?', whereArgs: [sourceUri], limit: 1);
    return maps.isEmpty ? null : Song.fromMap(maps.first);
  }

  /// Every song linked to a Drive source — used to detect changes and to
  /// notice files that have disappeared from the sync folder.
  Future<List<Song>> getSongsWithSourceUri() async {
    final d = await db;
    final maps =
        await d.query('songs', where: 'source_uri IS NOT NULL');
    return maps.map(Song.fromMap).toList();
  }

  // ─── Setlists ─────────────────────────────────────────────────────────────

  Future<int> insertSetlist(Setlist setlist) async {
    final d = await db;
    return d.insert('setlists', setlist.toMap());
  }

  Future<List<Setlist>> getAllSetlists() async {
    final d = await db;
    final maps =
        await d.query('setlists', orderBy: 'name COLLATE NOCASE ASC');
    return maps.map(Setlist.fromMap).toList();
  }

  Future<void> updateSetlistName(int id, String name) async {
    final d = await db;
    await d
        .update('setlists', {'name': name}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteSetlist(int id) async {
    final d = await db;
    await d.delete('setlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<Setlist?> getSetlistBySourceUri(String sourceUri) async {
    final d = await db;
    final maps = await d.query('setlists',
        where: 'source_uri = ?', whereArgs: [sourceUri], limit: 1);
    return maps.isEmpty ? null : Setlist.fromMap(maps.first);
  }

  Future<List<Setlist>> getSetlistsWithSourceUri() async {
    final d = await db;
    final maps =
        await d.query('setlists', where: 'source_uri IS NOT NULL');
    return maps.map(Setlist.fromMap).toList();
  }

  Future<void> updateSetlistSource(
      int id, String sourceUri, DateTime sourceModifiedAt) async {
    final d = await db;
    await d.update(
      'setlists',
      {
        'source_uri': sourceUri,
        'source_modified_at': sourceModifiedAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Marks (or clears, when [at] is null) a linked setlist as edited locally
  /// since its last Drive pull, so sync can detect a conflict with a
  /// concurrent remote edit instead of silently overwriting it.
  Future<void> setSetlistLocalEditedAt(int id, DateTime? at) async {
    final d = await db;
    await d.update(
      'setlists',
      {'local_edited_at': at?.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── Setlist entries ──────────────────────────────────────────────────────

  Future<void> addSongToSetlist(int setlistId, int songId) async {
    final d = await db;
    final existing = await d.query(
      'setlist_entries',
      where: 'setlist_id = ? AND song_id = ?',
      whereArgs: [setlistId, songId],
    );
    if (existing.isNotEmpty) return;
    final count = Sqflite.firstIntValue(await d.rawQuery(
          'SELECT COUNT(*) FROM setlist_entries WHERE setlist_id = ?',
          [setlistId],
        )) ??
        0;
    await d.insert('setlist_entries', {
      'setlist_id': setlistId,
      'song_id': songId,
      'position': count,
    });
  }

  Future<void> removeSongFromSetlist(int setlistId, int songId) async {
    final d = await db;
    await d.delete(
      'setlist_entries',
      where: 'setlist_id = ? AND song_id = ?',
      whereArgs: [setlistId, songId],
    );
  }

  Future<List<Song>> getSongsForSetlist(int setlistId) async {
    final d = await db;
    final maps = await d.rawQuery('''
      SELECT s.* FROM songs s
      INNER JOIN setlist_entries se ON s.id = se.song_id
      WHERE se.setlist_id = ?
      ORDER BY se.position ASC
    ''', [setlistId]);
    return maps.map(Song.fromMap).toList();
  }

  Future<void> reorderSetlistEntries(
      int setlistId, List<int> orderedSongIds) async {
    final d = await db;
    final batch = d.batch();
    for (var i = 0; i < orderedSongIds.length; i++) {
      batch.update(
        'setlist_entries',
        {'position': i},
        where: 'setlist_id = ? AND song_id = ?',
        whereArgs: [setlistId, orderedSongIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Replaces a setlist's entire song membership/order in one go — used when
  /// re-importing an updated setlist file, where the whole list should match
  /// the file rather than being merged entry-by-entry.
  Future<void> replaceSetlistSongs(
      int setlistId, List<int> orderedSongIds) async {
    final d = await db;
    final batch = d.batch();
    batch.delete('setlist_entries',
        where: 'setlist_id = ?', whereArgs: [setlistId]);
    for (var i = 0; i < orderedSongIds.length; i++) {
      batch.insert('setlist_entries', {
        'setlist_id': setlistId,
        'song_id': orderedSongIds[i],
        'position': i,
      });
    }
    await batch.commit(noResult: true);
  }
}
