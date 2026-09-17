import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';

class StorageService {
  static const String _fileName = 'notes.json';

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<Note>> loadNotes() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List<dynamic> data = jsonDecode(content);
      return data.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveNotes(List<Note> notes) async {
    final file = await _getFile();
    final data = notes.map((n) => n.toJson()).toList();
    await file.writeAsString(jsonEncode(data));
  }

  Future<String> exportNotes(List<Note> notes) async {
    final dir = await getExternalStorageDirectory();
    final exportFile = File('${dir!.path}/notes_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    final data = notes.map((n) => n.toJson()).toList();
    await exportFile.writeAsString(jsonEncode(data));
    return exportFile.path;
  }

  Future<List<Note>> importNotes(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final List<dynamic> data = jsonDecode(content);
    return data.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
  }
}
