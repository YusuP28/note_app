import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';

class ExportService {
  Future<String> exportAsTxt(Note note) async {
    final dir = await getApplicationDocumentsDirectory();
    final safe = _safeName(note.title.isEmpty ? 'catatan' : note.title);
    final file = File('${dir.path}/$safe.txt');
    await file.writeAsString('${note.title}\n\n${note.content}');
    return file.path;
  }

  Future<String> exportAsMarkdown(Note note) async {
    final dir = await getApplicationDocumentsDirectory();
    final safe = _safeName(note.title.isEmpty ? 'catatan' : note.title);
    final file = File('${dir.path}/$safe.md');
    await file.writeAsString('# ${note.title}\n\n${note.content}');
    return file.path;
  }

  String _safeName(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim()
        .substring(0, name.length > 40 ? 40 : name.length);
  }
}
