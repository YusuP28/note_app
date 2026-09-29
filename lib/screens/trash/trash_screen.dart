import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/note_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/note_card.dart';
import '../notes/edit_screen.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NoteProvider>().setFilter(NoteFilter.trashed);
    });
  }

  Future<void> _restore(String id) async {
    final p = context.read<NoteProvider>();
    final n = p.notes.firstWhere((e) => e.id == id);
    await p.restore(n);
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Permanen?'),
        content: const Text('Catatan ini tidak bisa dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<NoteProvider>().deletePermanently(id);
    }
  }

  Future<void> _empty() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kosongkan Sampah?'),
        content: const Text('Semua catatan di sampah akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kosongkan')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<NoteProvider>().emptyTrash();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<NoteProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sampah'),
        actions: [
          if (p.notes.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete_forever), onPressed: _empty),
        ],
      ),
      body: p.notes.isEmpty
          ? const EmptyState(icon: Icons.delete_outline, title: 'Sampah kosong')
          : ListView.builder(
              itemCount: p.notes.length,
              itemBuilder: (_, i) {
                final n = p.notes[i];
                return Dismissible(
                  key: ValueKey(n.id),
                  background: Container(
                    color: Colors.green,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.restore, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete_forever, color: Colors.white),
                  ),
                  confirmDismiss: (dir) async {
                    if (dir == DismissDirection.startToEnd) {
                      await _restore(n.id);
                      return false;
                    } else {
                      await _delete(n.id);
                      return false;
                    }
                  },
                  child: NoteCard(
                    note: n,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditScreen(note: n)),
                    ),
                    onLongPress: () {},
                  ),
                );
              },
            ),
    );
  }
}
