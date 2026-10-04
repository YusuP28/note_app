import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tag.dart';
import '../../providers/note_provider.dart';
import '../../providers/tag_provider.dart';
import '../notes/home_screen.dart';

class TagsScreen extends StatelessWidget {
  const TagsScreen({super.key});

  // Palet 12 warna preset
  static const List<int> _palette = [
    0xFFE53935, // red
    0xFFD81B60, // pink
    0xFF8E24AA, // purple
    0xFF6750A4, // deep purple (default)
    0xFF3949AB, // indigo
    0xFF1E88E5, // blue
    0xFF00ACC1, // cyan
    0xFF00897B, // teal
    0xFF43A047, // green
    0xFF7CB342, // light green
    0xFFFDD835, // yellow
    0xFFFB8C00, // orange
    0xFF6D4C41, // brown
    0xFF546E7A, // blue grey
    0xFF000000, // black
  ];

  Future<void> _addOrEdit(BuildContext context, {Tag? tag}) async {
    final ctrl = TextEditingController(text: tag?.name ?? '');
    int selectedColor = tag?.color ?? _palette[3];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(tag == null ? 'Tag Baru' : 'Edit Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Nama tag',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Warna', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _palette.map((c) {
                  final active = selectedColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: active ? Colors.black : Colors.transparent,
                          width: active ? 3 : 0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: active
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, {
                'name': ctrl.text.trim(),
                'color': selectedColor,
              }),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    final name = result['name'] as String;
    final color = result['color'] as int;
    if (name.isEmpty) return;

    final p = context.read<TagProvider>();
    if (tag == null) {
      await p.add(name, color: color);
    } else {
      tag.name = name;
      tag.color = color;
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
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: Color(t.color),
                  ),
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
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true && context.mounted) {
                          await context.read<TagProvider>().delete(t.id);
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'del', child: Text('Hapus')),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
