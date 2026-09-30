class Note {
  final String id;
  String title;
  String content; // sekarang = Quill Delta JSON
  String plainText; // text tanpa format (untuk search & preview)
  String? notebookId;
  int? color;
  bool isPinned;
  bool isArchived;
  bool isTrashed;
  bool isLocked;
  DateTime? trashedAt;
  DateTime? reminderAt;
  List<String> attachments;
  int sortOrder;
  final DateTime createdAt;
  DateTime updatedAt;
  List<String> tagIds;

  Note({
    required this.id,
    this.title = '',
    this.content = '',
    this.plainText = '',
    this.notebookId,
    this.color,
    this.isPinned = false,
    this.isArchived = false,
    this.isTrashed = false,
    this.isLocked = false,
    this.trashedAt,
    this.reminderAt,
    this.attachments = const [],
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.tagIds = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'plain_text': plainText,
        'notebook_id': notebookId,
        'color': color,
        'is_pinned': isPinned ? 1 : 0,
        'is_archived': isArchived ? 1 : 0,
        'is_trashed': isTrashed ? 1 : 0,
        'is_locked': isLocked ? 1 : 0,
        'trashed_at': trashedAt?.millisecondsSinceEpoch,
        'reminder_at': reminderAt?.millisecondsSinceEpoch,
        'attachments': attachments.isEmpty ? null : attachments.join('|'),
        'sort_order': sortOrder,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Note.fromMap(Map<String, dynamic> m, {List<String> tags = const []}) =>
      Note(
        id: m['id'] as String,
        title: (m['title'] as String?) ?? '',
        content: (m['content'] as String?) ?? '',
        plainText: (m['plain_text'] as String?) ?? '',
        notebookId: m['notebook_id'] as String?,
        color: m['color'] as int?,
        isPinned: (m['is_pinned'] as int? ?? 0) == 1,
        isArchived: (m['is_archived'] as int? ?? 0) == 1,
        isTrashed: (m['is_trashed'] as int? ?? 0) == 1,
        isLocked: (m['is_locked'] as int? ?? 0) == 1,
        trashedAt: m['trashed_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['trashed_at'] as int)
            : null,
        reminderAt: m['reminder_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['reminder_at'] as int)
            : null,
        attachments: (m['attachments'] as String?)?.isNotEmpty == true
            ? (m['attachments'] as String).split('|')
            : const [],
        sortOrder: (m['sort_order'] as int?) ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
        tagIds: tags,
      );

  Note copyWith({
    String? title,
    String? content,
    String? plainText,
    String? notebookId,
    bool clearNotebook = false,
    int? color,
    bool clearColor = false,
    bool? isPinned,
    bool? isArchived,
    bool? isTrashed,
    bool? isLocked,
    DateTime? trashedAt,
    DateTime? reminderAt,
    bool clearReminder = false,
    List<String>? attachments,
    int? sortOrder,
    DateTime? updatedAt,
    List<String>? tagIds,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      plainText: plainText ?? this.plainText,
      notebookId: clearNotebook ? null : (notebookId ?? this.notebookId),
      color: clearColor ? null : (color ?? this.color),
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isTrashed: isTrashed ?? this.isTrashed,
      isLocked: isLocked ?? this.isLocked,
      trashedAt: trashedAt ?? this.trashedAt,
      reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
      attachments: attachments ?? this.attachments,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tagIds: tagIds ?? this.tagIds,
    );
  }
}
