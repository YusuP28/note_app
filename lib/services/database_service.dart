import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/attachment.dart';
import '../models/note.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _db;
  static const int _version = 2;
  static const String _dbName = 'note_app_v7.db';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    debugPrint('DB path: $path');
    return openDatabase(
      path,
      version: _version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int v) async {
    await db.execute('''
      CREATE TABLE notebooks (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL DEFAULT 0xFF6750A4,
        icon TEXT,
        parent_id TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (parent_id) REFERENCES notebooks(id) ON DELETE CASCADE
      )
    ''');
    await db
        .execute('CREATE INDEX idx_notebooks_parent ON notebooks(parent_id)');

    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        color INTEGER NOT NULL DEFAULT 0xFF6750A4,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_tags_name ON tags(name)');

    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL DEFAULT '',
        content TEXT NOT NULL DEFAULT '',
        plain_text TEXT NOT NULL DEFAULT '',
        notebook_id TEXT,
        color INTEGER,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        is_trashed INTEGER NOT NULL DEFAULT 0,
        is_locked INTEGER NOT NULL DEFAULT 0,
        trashed_at INTEGER,
        reminder_at INTEGER,
        attachments TEXT,
        bg_image_path TEXT,
        bg_opacity INTEGER NOT NULL DEFAULT 300,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (notebook_id) REFERENCES notebooks(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_notes_notebook ON notes(notebook_id)');
    await db.execute(
        'CREATE INDEX idx_notes_flags ON notes(is_pinned, is_archived, is_trashed)');
    await db
        .execute('CREATE INDEX idx_notes_updated ON notes(updated_at DESC)');
    await db.execute('CREATE INDEX idx_notes_title ON notes(title)');
    await db.execute('CREATE INDEX idx_notes_reminder ON notes(reminder_at)');

    await db.execute('''
      CREATE TABLE note_tags (
        note_id TEXT NOT NULL,
        tag_id TEXT NOT NULL,
        PRIMARY KEY (note_id, tag_id),
        FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_note_tags_tag ON note_tags(tag_id)');

    await _createAttachmentsSchema(db);

    debugPrint('DB created OK');
  }

  Future<void> _createAttachmentsSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS note_attachments (
        id TEXT PRIMARY KEY,
        note_id TEXT NOT NULL,
        type TEXT NOT NULL,
        path TEXT NOT NULL,
        mime_type TEXT,
        size_bytes INTEGER NOT NULL DEFAULT 0,
        duration_ms INTEGER,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_note_attachments_note ON note_attachments(note_id)');
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      await _createAttachmentsSchema(db);
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<void> wipe() async {
    final db = await database;
    await db.delete('note_tags');
    await db.delete('note_attachments');
    await db.delete('notes');
    await db.delete('tags');
    await db.delete('notebooks');
  }

  Future<void> insertAttachment(Attachment attachment) async {
    final db = await database;
    await db.insert(
      'note_attachments',
      attachment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAttachment(String id) async {
    final db = await database;
    await db.delete('note_attachments', where: 'id = ?', whereArgs: [id]);
  }

  Future<Note?> getNoteById(String id) async {
    final db = await database;
    final rows = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final tagRows = await db.query(
      'note_tags',
      columns: ['tag_id'],
      where: 'note_id = ?',
      whereArgs: [id],
    );
    final tags = tagRows.map((e) => e['tag_id'] as String).toList();
    return Note.fromMap(rows.first, tags: tags);
  }

  Future<List<Attachment>> getAttachmentsForNote(String noteId) async {
    final db = await database;
    final rows = await db.query(
      'note_attachments',
      where: 'note_id = ?',
      whereArgs: [noteId],
      orderBy: 'created_at ASC',
    );
    return rows.map(Attachment.fromMap).toList();
  }
}
