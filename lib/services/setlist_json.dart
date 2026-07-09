import 'dart:convert';

/// Thrown when content isn't a recognizable GigBook setlist export.
class SetlistFormatException implements Exception {
  final String message;
  const SetlistFormatException(this.message);

  @override
  String toString() => message;
}

class SetlistJsonEntry {
  final String title;
  final String artist;
  const SetlistJsonEntry({required this.title, required this.artist});
}

class ParsedSetlistJson {
  final String name;
  final List<SetlistJsonEntry> entries;
  const ParsedSetlistJson({required this.name, required this.entries});
}

const setlistJsonFileType = 'gigbook-setlist';
const setlistJsonFileVersion = 1;

/// Parses and validates a `.gigbook-setlist.json` export — shared by manual
/// setlist import (via the share sheet) and Drive auto-sync, so both stay in
/// sync with a single file-format definition.
ParsedSetlistJson parseSetlistJson(String content) {
  final Map<String, dynamic> data;
  try {
    data = jsonDecode(content) as Map<String, dynamic>;
  } catch (_) {
    throw const SetlistFormatException(
        'That file is not a valid GigBook setlist.');
  }
  if (data['type'] != setlistJsonFileType) {
    throw const SetlistFormatException('That file is not a GigBook setlist.');
  }

  final rawName = (data['name'] as String?)?.trim() ?? '';
  final name = rawName.isNotEmpty ? rawName : 'Imported setlist';
  final rawEntries = (data['songs'] as List?) ?? const [];

  final entries = rawEntries.map((entry) {
    final map = entry as Map;
    return SetlistJsonEntry(
      title: (map['title'] as String? ?? '').trim(),
      artist: (map['artist'] as String? ?? '').trim(),
    );
  }).toList();

  return ParsedSetlistJson(name: name, entries: entries);
}
