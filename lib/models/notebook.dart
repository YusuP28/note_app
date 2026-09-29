class Notebook {
  final String id;
  String name;
  int color;
  String? icon;
  String? parentId;
  int sortOrder;
  final DateTime createdAt;
  DateTime updatedAt;

  Notebook({
    required this.id,
    required this.name,
    this.color = 0xFF6750A4,
    this.icon,
    this.parentId,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color': color,
        'icon': icon,
        'parent_id': parentId,
        'sort_order': sortOrder,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Notebook.fromMap(Map<String, dynamic> m) => Notebook(
        id: m['id'] as String,
        name: m['name'] as String,
        color: (m['color'] as int?) ?? 0xFF6750A4,
        icon: m['icon'] as String?,
        parentId: m['parent_id'] as String?,
        sortOrder: (m['sort_order'] as int?) ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
      );

  Notebook copyWith({
    String? name,
    int? color,
    String? icon,
    bool clearIcon = false,
    String? parentId,
    bool clearParent = false,
    int? sortOrder,
    DateTime? updatedAt,
  }) {
    return Notebook(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: clearIcon ? null : (icon ?? this.icon),
      parentId: clearParent ? null : (parentId ?? this.parentId),
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
