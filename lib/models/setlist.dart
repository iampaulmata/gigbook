class Setlist {
  final int? id;
  final String name;
  final DateTime createdAt;
  final String? sourceUri;
  final DateTime? sourceModifiedAt;
  final DateTime? localEditedAt;

  const Setlist({
    this.id,
    required this.name,
    required this.createdAt,
    this.sourceUri,
    this.sourceModifiedAt,
    this.localEditedAt,
  });

  Setlist copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    String? sourceUri,
    DateTime? sourceModifiedAt,
    DateTime? localEditedAt,
  }) =>
      Setlist(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        sourceUri: sourceUri ?? this.sourceUri,
        sourceModifiedAt: sourceModifiedAt ?? this.sourceModifiedAt,
        localEditedAt: localEditedAt ?? this.localEditedAt,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'created_at': createdAt.millisecondsSinceEpoch,
        'source_uri': sourceUri,
        'source_modified_at': sourceModifiedAt?.millisecondsSinceEpoch,
        'local_edited_at': localEditedAt?.millisecondsSinceEpoch,
      };

  factory Setlist.fromMap(Map<String, dynamic> map) => Setlist(
        id: map['id'] as int?,
        name: map['name'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        sourceUri: map['source_uri'] as String?,
        sourceModifiedAt: map['source_modified_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                map['source_modified_at'] as int)
            : null,
        localEditedAt: map['local_edited_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                map['local_edited_at'] as int)
            : null,
      );
}
