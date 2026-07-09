import 'package:flutter/foundation.dart';

import '../db/database.dart';
import '../models/song.dart';
import '../services/import_service.dart';

class LibraryProvider extends ChangeNotifier {
  List<Song> _songs = [];
  String _query = '';
  bool _loading = false;

  List<Song> get songs => _songs;
  bool get loading => _loading;
  String get query => _query;

  List<Song> get filtered {
    if (_query.isEmpty) return _songs;
    final q = _query.toLowerCase();
    return _songs
        .where((s) =>
            s.title.toLowerCase().contains(q) ||
            s.artist.toLowerCase().contains(q))
        .toList();
  }

  Future<void> loadSongs() async {
    _loading = true;
    notifyListeners();
    _songs = await AppDatabase.instance.getAllSongs();
    _loading = false;
    notifyListeners();
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  Future<ImportResult> importFiles() async {
    final result = await ImportService.pickAndImportFiles();
    if (result.imported.isNotEmpty) {
      await loadSongs();
    }
    return result;
  }

  Future<ImportResult> importFolder() async {
    final result = await ImportService.pickAndImportFolder();
    if (result.imported.isNotEmpty) {
      await loadSongs();
    }
    return result;
  }

  Future<void> deleteSong(int id) async {
    await AppDatabase.instance.deleteSong(id);
    _songs.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  Future<void> toggleFavorite(Song song) async {
    final updated = song.copyWith(isFavorite: !song.isFavorite);
    await AppDatabase.instance.updateSong(updated);
    final idx = _songs.indexWhere((s) => s.id == song.id);
    if (idx != -1) {
      _songs[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> updateSong(Song song) async {
    await AppDatabase.instance.updateSong(song);
    final idx = _songs.indexWhere((s) => s.id == song.id);
    if (idx != -1) {
      _songs[idx] = song;
      notifyListeners();
    }
  }
}
