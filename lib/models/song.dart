class Song {
  final int? id;
  final String title;
  final String artist;
  final String? key;
  final int? capo;
  final bool isFavorite;
  final String content;
  final DateTime createdAt;
  final DateTime? lastOpenedAt;

  const Song({
    this.id,
    required this.title,
    this.artist = '',
    this.key,
    this.capo,
    this.isFavorite = false,
    required this.content,
    required this.createdAt,
    this.lastOpenedAt,
  });

  Song copyWith({
    int? id,
    String? title,
    String? artist,
    String? key,
    int? capo,
    bool? isFavorite,
    String? content,
    DateTime? createdAt,
    DateTime? lastOpenedAt,
  }) =>
      Song(
        id: id ?? this.id,
        title: title ?? this.title,
        artist: artist ?? this.artist,
        key: key ?? this.key,
        capo: capo ?? this.capo,
        isFavorite: isFavorite ?? this.isFavorite,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'artist': artist,
        'key': key,
        'capo': capo,
        'is_favorite': isFavorite ? 1 : 0,
        'content': content,
        'created_at': createdAt.millisecondsSinceEpoch,
        'last_opened_at': lastOpenedAt?.millisecondsSinceEpoch,
      };

  factory Song.fromMap(Map<String, dynamic> map) => Song(
        id: map['id'] as int?,
        title: map['title'] as String,
        artist: (map['artist'] as String?) ?? '',
        key: map['key'] as String?,
        capo: map['capo'] as int?,
        isFavorite: (map['is_favorite'] as int?) == 1,
        content: map['content'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        lastOpenedAt: map['last_opened_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                map['last_opened_at'] as int)
            : null,
      );
}
