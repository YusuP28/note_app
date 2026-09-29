import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tag.dart';
import '../../providers/note_provider.dart';
import '../../providers/tag_provider.dart';
import '../notes/home_screen.dart';

class TagsScreen extends StatelessWidget {
  const TagsScreen({super.key});

  Future<void> _addOrEdit(BuildContext context, {Tag? tag}) async {
    final ctrl = TextEditingController(text: tag?.name ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tag == null ? 'Tag Baru' : 'Edit Tag'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nama tag',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Simpan')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final p = context.read<TagProvider>();
    if (tag == null) {
      await p.add(name);
    } else {
      tag.name = name;
      await p.update(tag);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TagProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Tag')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEdit(context),
        child: const Icon(Icons.add),
      ),
      body: p.tags.isEmpty
          ? const Center(child: Text('Belum ada tag'))
          : ListView.builder(
              itemCount: p.tags.length,
              itemBuilder: (_, i) {
                final t = p.tags[i];
                return ListTile(
                  leading: CircleAvatar(radius: 10, backgroundColor: Color(t.color)),
                  title: Text(t.name),
                  onTap: () {
                    final np = context.read<NoteProvider>();
                    np.setFilter(NoteFilter.all);
                    np.setNotebookFilter(null);
                    np.setTagFilter(t.id);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') _addOrEdit(context, tag: t);
                      if (v == 'del') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Hapus Tag?'),
                            content: Text('Tag "${t.name}" akan dihapus dari semua catatan.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Batal')),
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Hapus')),
                            ],
                          ),
                        );
                        if (ok == true && context.mounted) {
                          await context.read<TagProvider>().delete(t.id);
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Rename')),
                      PopupMenuItem(value: 'del', child: Text('Hapus')),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
