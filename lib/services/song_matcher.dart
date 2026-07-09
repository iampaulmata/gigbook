import '../models/song.dart';

/// Shared case-insensitive title+artist matching, used anywhere GigBook needs
/// to recognize "the same song" across imports, shared setlists, Drive sync,
/// and live multi-device sessions — without relying on database IDs that
/// won't exist yet on the other side.
class SongMatcher {
  static String key(String title, String artist) =>
      '${title.trim().toLowerCase()}|${artist.trim().toLowerCase()}';

  static Song? find(List<Song> library, String title, String artist) {
    final target = key(title, artist);
    for (final song in library) {
      if (key(song.title, song.artist) == target) return song;
    }
    return null;
  }
}
