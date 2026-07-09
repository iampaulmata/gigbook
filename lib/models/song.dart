class Song {
  final int? id;
  final String title;
  final String artist;
  final String? key;
  final int? capo;
  final int? tempo;
  final bool isFavorite;
  final String content;
  final DateTime createdAt;
  final DateTime? lastOpenedAt;
  final String? sourceUri;
  final DateTime? sourceModifiedAt;
  final DateTime? localEditedAt;
  final String? sourceParentUri;
  final String? sourceFileName;

  const Song({
    this.id,
    required this.title,
    this.artist = '',
    this.key,
    this.capo,
    this.tempo,
    this.isFavorite = false,
    required this.content,
    required this.createdAt,
    this.lastOpenedAt,
    this.sourceUri,
    this.sourceModifiedAt,
    this.localEditedAt,
    this.sourceParentUri,
    this.sourceFileName,
  });

  Song copyWith({
    int? id,
    String? title,
    String? artist,
    String? key,
    int? capo,
    int? tempo,
    bool? isFavorite,
    String? content,
    DateTime? createdAt,
    DateTime? lastOpenedAt,
    String? sourceUri,
    DateTime? sourceModifiedAt,
    DateTime? localEditedAt,
    String? sourceParentUri,
    String? sourceFileName,
  }) =>
      Song(
        id: id ?? this.id,
        title: title ?? this.title,
        artist: artist ?? this.artist,
        key: key ?? this.key,
        capo: capo ?? this.capo,
        tempo: tempo ?? this.tempo,
        isFavorite: isFavorite ?? this.isFavorite,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
        sourceUri: sourceUri ?? this.sourceUri,
        sourceModifiedAt: sourceModifiedAt ?? this.sourceModifiedAt,
        localEditedAt: localEditedAt ?? this.localEditedAt,
        sourceParentUri: sourceParentUri ?? this.sourceParentUri,
        sourceFileName: sourceFileName ?? this.sourceFileName,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'artist': artist,
        'key': key,
        'capo': capo,
        'tempo': tempo,
        'is_favorite': isFavorite ? 1 : 0,
        'content': content,
        'created_at': createdAt.millisecondsSinceEpoch,
        'last_opened_at': lastOpenedAt?.millisecondsSinceEpoch,
        'source_uri': sourceUri,
        'source_modified_at': sourceModifiedAt?.millisecondsSinceEpoch,
        'local_edited_at': localEditedAt?.millisecondsSinceEpoch,
        'source_parent_uri': sourceParentUri,
        'source_file_name': sourceFileName,
      };

  factory Song.fromMap(Map<String, dynamic> map) => Song(
        id: map['id'] as int?,
        title: map['title'] as String,
        artist: (map['artist'] as String?) ?? '',
        key: map['key'] as String?,
        capo: map['capo'] as int?,
        tempo: map['tempo'] as int?,
        isFavorite: (map['is_favorite'] as int?) == 1,
        content: map['content'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        lastOpenedAt: map['last_opened_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                map['last_opened_at'] as int)
            : null,
        sourceUri: map['source_uri'] as String?,
        sourceModifiedAt: map['source_modified_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                map['source_modified_at'] as int)
            : null,
        localEditedAt: map['local_edited_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                map['local_edited_at'] as int)
            : null,
        sourceParentUri: map['source_parent_uri'] as String?,
        sourceFileName: map['source_file_name'] as String?,
      );
}
