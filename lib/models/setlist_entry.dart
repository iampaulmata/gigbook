class SetlistEntry {
  final int? id;
  final int setlistId;
  final int songId;
  final int position;

  const SetlistEntry({
    this.id,
    required this.setlistId,
    required this.songId,
    required this.position,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'setlist_id': setlistId,
        'song_id': songId,
        'position': position,
      };

  factory SetlistEntry.fromMap(Map<String, dynamic> map) => SetlistEntry(
        id: map['id'] as int?,
        setlistId: map['setlist_id'] as int,
        songId: map['song_id'] as int,
        position: map['position'] as int,
      );
}
