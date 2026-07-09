import 'package:flutter/foundation.dart';

import '../db/database.dart';
import '../models/setlist.dart';
import '../models/song.dart';

class SetlistProvider extends ChangeNotifier {
  List<Setlist> _setlists = [];

  List<Setlist> get setlists => _setlists;

  Future<void> loadSetlists() async {
    _setlists = await AppDatabase.instance.getAllSetlists();
    notifyListeners();
  }

  Future<Setlist> createSetlist(String name) async {
    final setlist = Setlist(name: name, createdAt: DateTime.now());
    final id = await AppDatabase.instance.insertSetlist(setlist);
    final created = setlist.copyWith(id: id);
    _setlists.add(created);
    _setlists.sort((a, b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    notifyListeners();
    return created;
  }

  Future<void> renameSetlist(int id, String name) async {
    await AppDatabase.instance.updateSetlistName(id, name);
    final idx = _setlists.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _setlists[idx] = _setlists[idx].copyWith(name: name);
      _setlists.sort((a, b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      notifyListeners();
    }
  }

  Future<void> deleteSetlist(int id) async {
    await AppDatabase.instance.deleteSetlist(id);
    _setlists.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  Future<List<Song>> getSongs(int setlistId) async {
    return AppDatabase.instance.getSongsForSetlist(setlistId);
  }

  Future<void> addSong(int setlistId, int songId) async {
    await AppDatabase.instance.addSongToSetlist(setlistId, songId);
    await _stampLocalEditIfLinked(setlistId);
  }

  Future<void> removeSong(int setlistId, int songId) async {
    await AppDatabase.instance.removeSongFromSetlist(setlistId, songId);
    await _stampLocalEditIfLinked(setlistId);
  }

  Future<void> reorder(int setlistId, List<int> orderedSongIds) async {
    await AppDatabase.instance.reorderSetlistEntries(setlistId, orderedSongIds);
    await _stampLocalEditIfLinked(setlistId);
  }

  /// Marks a Drive-linked setlist as edited locally since its last sync
  /// pull, so a later Drive sync can detect a conflict instead of silently
  /// overwriting this edit with the remote version.
  Future<void> _stampLocalEditIfLinked(int setlistId) async {
    Setlist? setlist;
    for (final s in _setlists) {
      if (s.id == setlistId) {
        setlist = s;
        break;
      }
    }
    if (setlist?.sourceUri == null) return;
    await AppDatabase.instance.setSetlistLocalEditedAt(setlistId, DateTime.now());
  }
}
