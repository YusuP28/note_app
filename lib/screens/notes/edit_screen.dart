import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/note.dart';
import '../../models/tag.dart';
import '../../providers/note_provider.dart';
import '../../providers/notebook_provider.dart';
import '../../providers/tag_provider.dart';

class EditScreen extends StatefulWidget {
  final Note? note;
  const EditScreen({super.key, this.note});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  late Note _working;
  bool _isNew = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isNew = widget.note == null;
    _working = widget.note ??
        Note(id: '', createdAt: DateTime.now(), updatedAt: DateTime.now());
    _titleCtrl = TextEditingController(text: _working.title);
    _contentCtrl = TextEditingController(text: _working.content);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final p = context.read<NoteProvider>();
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (title.isEmpty && content.isEmpty) {
      if (mounted) Navigator.pop(context, null);
      return;
    }

    try {
      if (_isNew) {
        final created = await p.addNote(
          title: title.isEmpty ? 'Tanpa Judul' : title,
          content: content,
          notebookId: _working.notebookId,
        );
        // apply warna & tag
        if (_working.color != null) created.color = _working.color;
        created.tagIds = List.from(_working.tagIds);
        await p.updateNote(created);
      } else {
        _working.title = title.isEmpty ? 'Tanpa Judul' : title;
        _working.content = content;
        await p.updateNote(_working);
      }
      if (mounted) Navigator.pop(context, null);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal simpan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notebooks = context.watch<NotebookProvider>();
    final tags = context.watch<TagProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Catatan Baru' : 'Edit Catatan'),
        actions: [
          IconButton(
            tooltip: 'Warna',
            icon: const Icon(Icons.palette_outlined),
            onPressed: _pickColor,
          ),
          IconButton(
            tooltip: 'Notebook',
            icon: const Icon(Icons.folder_outlined),
            onPressed: () => _pickNotebook(notebooks),
          ),
          IconButton(
            tooltip: 'Tag',
            icon: const Icon(Icons.label_outline),
            onPressed: () => _pickTags(tags),
          ),
          IconButton(
            tooltip: 'Simpan',
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                hintText: 'Judul...',
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: TextField(
                controller: _contentCtrl,
                decoration: const InputDecoration(
                  hintText: 'Tulis catatan di sini...',
                  border: InputBorder.none,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            if (_working.tagIds.isNotEmpty) _tagChips(tags),
          ],
        ),
      ),
    );
  }

  Widget _tagChips(TagProvider tp) {
    final map = {for (final t in tp.tags) t.id: t};
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _working.tagIds
            .where(map.containsKey)
            .map((id) {
              final tag = map[id]!;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Chip(
                  label: Text(tag.name),
                  backgroundColor: Color(tag.color).withOpacity(0.15),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setState(() => _working.tagIds.remove(id)),
                ),
              );
            })
            .toList(),
      ),
    );
  }

  Future<void> _pickColor() async {
    final colors = <Color>[
      const Color(0xFF6750A4),
      const Color(0xFFE57373),
      const Color(0xFFFFB74D),
      const Color(0xFFFFF176),
      const Color(0xFF81C784),
      const Color(0xFF64B5F6),
      const Color(0xFFBA68C8),
      const Color(0xFFA1887F),
    ];
    final picked = await showDialog<Color?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Warna'),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...colors.map((c) => GestureDetector(
                  onTap: () => Navigator.pop(ctx, c),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black26),
                    ),
                  ),
                )),
            GestureDetector(
              onTap: () => Navigator.pop(ctx, Colors.transparent),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black26),
                  color: Colors.white,
                ),
                child: const Icon(Icons.close, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        _working.color = picked == Colors.transparent ? null : picked.value;
      });
    }
  }

  Future<void> _pickNotebook(NotebookProvider np) async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('Tanpa Notebook'),
              onTap: () => Navigator.pop(ctx, '__none__'),
            ),
            const Divider(height: 1),
            ...np.notebooks.map((nb) => ListTile(
                  leading: CircleAvatar(
                    radius: 10,
                    backgroundColor: Color(nb.color),
                  ),
                  title: Text(nb.name),
                  selected: _working.notebookId == nb.id,
                  onTap: () => Navigator.pop(ctx, nb.id),
                )),
          ],
        ),
      ),
    );
    if (selected != null) {
      setState(() {
        _working.notebookId = selected == '__none__' ? null : selected;
      });
    }
  }

  Future<void> _pickTags(TagProvider tp) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final ctrl = TextEditingController();
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tag',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        decoration: const InputDecoration(
                          hintText: 'Tambah tag baru...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        final name = ctrl.text.trim();
                        if (name.isEmpty) return;
                        final t = await tp.add(name);
                        setLocal(() {});
                        setState(() => _working.tagIds.add(t.id));
                        ctrl.clear();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tp.tags.map((Tag t) {
                        final sel = _working.tagIds.contains(t.id);
                        return FilterChip(
                          label: Text(t.name),
                          selected: sel,
                          onSelected: (v) => setState(() {
                            if (v) {
                              _working.tagIds.add(t.id);
                            } else {
                              _working.tagIds.remove(t.id);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}
