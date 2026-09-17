import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/note.dart';
import '../services/storage_service.dart';
import 'edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  List<Note> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await _storage.loadNotes();
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _saveNotes() async {
    await _storage.saveNotes(_notes);
  }

  Future<void> _addOrEdit([Note? note]) async {
    final result = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (_) => EditScreen(note: note)),
    );

    if (result != null) {
      setState(() {
        final index = _notes.indexWhere((n) => n.id == result.id);
        if (index >= 0) {
          _notes[index] = result;
        } else {
          _notes.insert(0, result);
        }
      });
      await _saveNotes();
    }
  }

  Future<void> _delete(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan?'),
        content: const Text('Catatan akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _notes.removeAt(index));
      await _saveNotes();
    }
  }

  Future<void> _export() async {
    if (_notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada catatan untuk di-export')),
      );
      return;
    }
    final path = await _storage.exportNotes(_notes);
    await Share.shareXFiles([XFile(path)], text: 'Backup catatan saya');
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.single.path == null) return;

    try {
      final imported = await _storage.importNotes(result.files.single.path!);
      setState(() => _notes = imported);
      await _saveNotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${imported.length} catatan berhasil di-import')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal import: file tidak valid')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatanku'),
        actions: [
          IconButton(icon: const Icon(Icons.file_download), tooltip: 'Import', onPressed: _import),
          IconButton(icon: const Icon(Icons.file_upload), tooltip: 'Export', onPressed: _export),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.note_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Belum ada catatan', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      SizedBox(height: 8),
                      Text('Tap tombol + untuk mulai', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _notes.length,
                  itemBuilder: (ctx, i) {
                    final note = _notes[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListTile(
                        title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () => _addOrEdit(note),
                        onLongPress: () => _delete(i),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
