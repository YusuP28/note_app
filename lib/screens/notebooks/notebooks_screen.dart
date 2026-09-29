import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/notebook.dart';
import '../../providers/note_provider.dart';
import '../../providers/notebook_provider.dart';
import '../notes/home_screen.dart';

class NotebooksScreen extends StatelessWidget {
  const NotebooksScreen({super.key});

  Future<void> _addOrEdit(BuildContext context, {Notebook? nb, String? parentId}) async {
    final ctrl = TextEditingController(text: nb?.name ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(nb == null ? 'Notebook Baru' : 'Edit Notebook'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nama notebook',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final p = context.read<NotebookProvider>();
    if (nb == null) {
      await p.add(name, parentId: parentId);
    } else {
      nb.name = name;
      await p.update(nb);
    }
  }

  Future<void> _confirmDelete(BuildContext context, Notebook nb) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Notebook?'),
        content: Text('Notebook "${nb.name}" akan dihapus. Catatan di dalamnya tidak dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<NotebookProvider>().delete(nb.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<NotebookProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Notebook')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEdit(context),
        child: const Icon(Icons.create_new_folder_outlined),
      ),
      body: p.notebooks.isEmpty
          ? const Center(child: Text('Belum ada notebook'))
          : ListView(
              children: _buildTree(context, p, null, 0),
            ),
    );
  }

  List<Widget> _buildTree(BuildContext context, NotebookProvider p, String? parent, int depth) {
    final children = p.childrenOf(parent);
    final items = <Widget>[];
    for (final nb in children) {
      items.add(ListTile(
        contentPadding: EdgeInsets.only(left: 16.0 + depth * 20, right: 8),
        leading: CircleAvatar(radius: 10, backgroundColor: Color(nb.color)),
        title: Text(nb.name),
        onTap: () {
          final np = context.read<NoteProvider>();
          np.setFilter(NoteFilter.all);
          np.setNotebookFilter(nb.id);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        },
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'sub') _addOrEdit(context, parentId: nb.id);
            if (v == 'edit') _addOrEdit(context, nb: nb);
            if (v == 'del') _confirmDelete(context, nb);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'sub', child: Text('Sub-notebook')),
            PopupMenuItem(value: 'edit', child: Text('Rename')),
            PopupMenuItem(value: 'del', child: Text('Hapus')),
          ],
        ),
      ));
      items.addAll(_buildTree(context, p, nb.id, depth + 1));
    }
    return items;
  }
}
