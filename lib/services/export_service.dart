import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/note.dart';

class ExportService {
  static final ExportService _i = ExportService._();
  factory ExportService() => _i;
  ExportService._();

  /// Export note sebagai .txt
  Future<File> writeTxt(Note note) async {
    final dir = await getTemporaryDirectory();
    final safeTitle = _safeFileName(note.title.isEmpty ? 'catatan' : note.title);
    final file = File('${dir.path}/$safeTitle.txt');
    final content = '${note.title}\n\n${note.plainText}';
    await file.writeAsString(content);
    return file;
  }

  /// Export note sebagai .md (markdown)
  Future<File> writeMarkdown(Note note) async {
    final dir = await getTemporaryDirectory();
    final safeTitle = _safeFileName(note.title.isEmpty ? 'catatan' : note.title);
    final file = File('${dir.path}/$safeTitle.md');
    final content = '# ${note.title}\n\n${note.plainText}';
    await file.writeAsString(content);
    return file;
  }

  /// Share note sebagai .txt ke app lain
  Future<void> shareAsTxt(Note note) async {
    final file = await writeTxt(note);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/plain')],
      subject: note.title,
      text: note.title,
    );
  }

  /// Share note sebagai teks (tanpa file)
  Future<void> shareAsText(Note note) async {
    final content = note.title.isEmpty
        ? note.plainText
        : '${note.title}\n\n${note.plainText}';
    await Share.share(content, subject: note.title);
  }

  String _safeFileName(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
    return cleaned.length > 40 ? cleaned.substring(0, 40) : cleaned;
  }
}
