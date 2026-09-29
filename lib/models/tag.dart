class Tag {
  final String id;
  String name;
  int color;
  final DateTime createdAt;

  Tag({
    required this.id,
    required this.name,
    this.color = 0xFF6750A4,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color': color,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Tag.fromMap(Map<String, dynamic> m) => Tag(
        id: m['id'] as String,
        name: m['name'] as String,
        color: (m['color'] as int?) ?? 0xFF6750A4,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );

  Tag copyWith({String? name, int? color}) => Tag(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        createdAt: createdAt,
      );
}
