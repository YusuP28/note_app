class Attachment {
  static const String typeImage = 'image';
  static const String typeAudio = 'audio';
  static const String typeVideo = 'video';
  static const String typeFile = 'file';
  static const String typeDrawing = 'drawing';

  final String id;
  final String noteId;
  final String type;
  final String path;
  final String? mimeType;
  final int sizeBytes;
  final int? durationMs;
  final DateTime createdAt;

  Attachment({
    required this.id,
    required this.noteId,
    required this.type,
    required this.path,
    this.mimeType,
    this.sizeBytes = 0,
    this.durationMs,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'note_id': noteId,
        'type': type,
        'path': path,
        'mime_type': mimeType,
        'size_bytes': sizeBytes,
        'duration_ms': durationMs,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Attachment.fromMap(Map<String, dynamic> m) => Attachment(
        id: m['id'] as String,
        noteId: m['note_id'] as String,
        type: m['type'] as String,
        path: m['path'] as String,
        mimeType: m['mime_type'] as String?,
        sizeBytes: (m['size_bytes'] as int?) ?? 0,
        durationMs: m['duration_ms'] as int?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );

  Attachment copyWith({
    String? path,
    String? mimeType,
    int? sizeBytes,
    int? durationMs,
  }) =>
      Attachment(
        id: id,
        noteId: noteId,
        type: type,
        path: path ?? this.path,
        mimeType: mimeType ?? this.mimeType,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        durationMs: durationMs ?? this.durationMs,
        createdAt: createdAt,
      );
}
