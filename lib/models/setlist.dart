class Setlist {
  final int? id;
  final String name;
  final DateTime createdAt;

  const Setlist({
    this.id,
    required this.name,
    required this.createdAt,
  });

  Setlist copyWith({int? id, String? name, DateTime? createdAt}) => Setlist(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Setlist.fromMap(Map<String, dynamic> map) => Setlist(
        id: map['id'] as int?,
        name: map['name'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}
