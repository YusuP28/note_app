import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../providers/note_provider.dart';
import '../services/export_service.dart';
import '../screens/notes/edit_screen.dart';

/// Tampilkan bottom sheet opsi untuk catatan.
/// Return aksi yang dipilih (String) atau null.
Future<String?> showNoteContextSheet(BuildContext context, Note note) async {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Judul catatan
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Icon(Icons.note_outlined,
                    color: Theme.of(ctx).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    note.title.isEmpty ? 'Tanpa Judul' : note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Aksi: Buka & Edit
          _tile(ctx, Icons.edit_outlined, 'Buka & Edit', 'open'),
          // Aksi: Mode Baca
          _tile(ctx, Icons.menu_book_outlined, 'Mode Baca', 'read'),
          // Aksi: Pin/Unpin
          _tile(
            ctx,
            note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            note.isPinned ? 'Lepas Sematan' : 'Sematkan',
            'pin',
          ),
          // Aksi: Arsip
          _tile(ctx, Icons.archive_outlined, 'Arsipkan', 'archive'),
          // Aksi: Bagikan sebagai TXT
          _tile(ctx, Icons.text_snippet_outlined,
              'Bagikan sebagai .txt', 'share_txt'),
          // Aksi: Bagikan sebagai teks
          _tile(ctx, Icons.share_outlined, 'Bagikan sebagai Teks', 'share_text'),
          // Aksi: Salin ke clipboard
          _tile(ctx, Icons.copy_all_outlined, 'Salin Teks', 'copy'),
          // Aksi: Info
          _tile(ctx, Icons.info_outline, 'Info', 'info'),
          // Aksi: Hapus
          _tile(ctx, Icons.delete_outline, 'Pindah ke Sampah', 'trash',
              color: Theme.of(ctx).colorScheme.error),

          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Widget _tile(BuildContext ctx, IconData icon, String label, String action,
    {Color? color}) {
  return ListTile(
    leading: Icon(icon, color: color),
    title: Text(label, style: TextStyle(color: color)),
    onTap: () => Navigator.pop(ctx, action),
  );
}

/// Handle aksi dari context sheet.
Future<void> handleNoteAction(
  BuildContext context,
  Note note,
  String action,
) async {
  final provider = context.read<NoteProvider>();

  switch (action) {
    case 'read':
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditScreen(note: note, readOnly: true),
        ),
      );
      break;

    case 'open':
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditScreen(note: note)),
      );
      break;

    case 'pin':
      await provider.togglePin(note);
      _snack(context, note.isPinned ? 'Disematkan' : 'Lepas sematan');
      break;

    case 'archive':
      await provider.archive(note, true);
      _snack(context, 'Diarsipkan');
      break;

    case 'share_txt':
      await ExportService().shareAsTxt(note);
      break;

    case 'share_text':
      await ExportService().shareAsText(note);
      break;

    case 'copy':
      final content = note.title.isEmpty
          ? note.plainText
          : '${note.title}\n\n${note.plainText}';
      await Clipboard.setData(ClipboardData(text: content));
      _snack(context, 'Teks disalin ke clipboard');
      break;

    case 'info':
      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Info Catatan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('ID', note.id.substring(0, 8)),
              _infoRow('Dibuat', _fmt(note.createdAt)),
              _infoRow('Diubah', _fmt(note.updatedAt)),
              _infoRow('Notebook', note.notebookId?.substring(0, 8) ?? '-'),
              _infoRow('Tag', '${note.tagIds.length}'),
              _infoRow('Gambar', '${note.attachments.length}'),
              _infoRow('Panjang', '${note.plainText.length} char'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
      break;

    case 'trash':
      await provider.trash(note);
      _snack(context, 'Dipindah ke sampah');
      break;
  }
}

Widget _infoRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 80,
              child: Text('$label',
                  style: const TextStyle(fontSize: 12, color: Colors.grey))),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );

String _fmt(DateTime t) {
  return '${t.day}/${t.month}/${t.year} ${t.hour}:${t.minute.toString().padLeft(2, '0')}';
}

void _snack(BuildContext ctx, String msg) {
  ScaffoldMessenger.of(ctx).showSnackBar(
    SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
  );
}
