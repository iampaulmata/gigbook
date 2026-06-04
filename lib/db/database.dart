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
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        artist TEXT NOT NULL DEFAULT '',
        key TEXT,
        capo INTEGER,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        last_opened_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE setlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL
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

  Future<void> touchSong(int id) async {
    final d = await db;
    await d.update(
      'songs',
      {'last_opened_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
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
}
