import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/note.dart';
import '../../models/tag.dart';
import '../../providers/note_provider.dart';
import '../../providers/notebook_provider.dart';
import '../../providers/tag_provider.dart';
import '../../utils/date_utils.dart';
import '../../services/image_attachment_service.dart';
import '../../widgets/image_picker_sheet.dart';
import '../../widgets/image_thumbnail.dart';
import 'dart:io';

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
  DateTime? _reminder;
  late List<String> _attachments;
  Timer? _draftTimer;
  late final String _draftKeyTitle;
  late final String _draftKeyContent;

  @override
  void initState() {
    super.initState();
    _isNew = widget.note == null;
    _working = widget.note ??
        Note(id: '', createdAt: DateTime.now(), updatedAt: DateTime.now());
    _titleCtrl = TextEditingController(text: _working.title);
    _contentCtrl = TextEditingController(text: _working.content);
    _reminder = _working.reminderAt;
    _attachments = List.from(_working.attachments);
    _draftKeyTitle = 'draft_${_working.id}_title';
    _draftKeyContent = 'draft_${_working.id}_content';
    _titleCtrl.addListener(_onDraftChange);
    _contentCtrl.addListener(_onDraftChange);
    if (_isNew) _restoreDraft();
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString(_draftKeyTitle) ?? '';
    final c = p.getString(_draftKeyContent) ?? '';
    if (t.isNotEmpty || c.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _titleCtrl.text = t;
        _contentCtrl.text = c;
      });
    }
  }

  void _onDraftChange() {
    if (!_isNew) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(seconds: 3), _saveDraft);
  }

  Future<void> _saveDraft() async {
    if (!_isNew) return;
    final p = await SharedPreferences.getInstance();
    await p.setString(_draftKeyTitle, _titleCtrl.text);
    await p.setString(_draftKeyContent, _contentCtrl.text);
  }

  Future<void> _clearDraft() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_draftKeyTitle);
    await p.remove(_draftKeyContent);
  }

  Future<bool> _save({bool silent = false}) async {
    if (_saving) return false;
    _saving = true;

    final p = context.read<NoteProvider>();
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (title.isEmpty && content.isEmpty) {
      await _clearDraft();
      _saving = false;
      return true;
    }

    try {
      if (_isNew) {
        final created = await p.addNote(
          title: title.isEmpty ? 'Tanpa Judul' : title,
          content: content,
          notebookId: _working.notebookId,
        );
        if (_working.color != null) created.color = _working.color;
        created.tagIds = List.from(_working.tagIds);
        created.attachments = List.from(_attachments);
        await p.updateNote(created);
        if (_reminder != null) await p.setReminder(created, _reminder);
        _working = created;
        _isNew = false;
      } else {
        _working.title = title.isEmpty ? 'Tanpa Judul' : title;
        _working.content = content;
        _working.attachments = List.from(_attachments);
        await p.updateNote(_working);
        await p.setReminder(_working, _reminder);
      }
      await _clearDraft();
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tersimpan'), duration: Duration(seconds: 1)),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal simpan: $e')),
        );
      }
      return false;
    } finally {
      _saving = false;
    }
  }

  /// Hitung warna teks kontras terhadap background
  Color _contrastText(Color bg) {
    final lum = bg.computeLuminance();
    return lum > 0.5 ? Colors.black87 : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final notebooks = context.watch<NotebookProvider>();
    final tags = context.watch<TagProvider>();
    final scheme = Theme.of(context).colorScheme;

    // Warna editor mengikuti warna catatan
    final customColor = _working.color != null ? Color(_working.color!) : null;
    final editorBg = customColor ?? scheme.surface;
    // Warna teks hanya kontras kalau pakai warna custom
    final textColor = customColor != null
        ? _contrastText(editorBg)
        : scheme.onSurface;
    final hintColor = textColor.withOpacity(0.55);
    final iconColor = textColor;
    final dividerColor = textColor.withOpacity(0.25);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _save(silent: true);
        if (mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: editorBg,
        appBar: AppBar(
          backgroundColor: editorBg,
          foregroundColor: iconColor,
          elevation: 0,
          title: Text(
            _isNew ? 'Catatan Baru' : 'Edit Catatan',
            style: TextStyle(color: textColor),
          ),
          iconTheme: IconThemeData(color: iconColor),
          actions: [
            IconButton(
              tooltip: _reminder == null ? 'Set Pengingat' : 'Pengingat aktif',
              icon: Icon(
                _reminder == null ? Icons.alarm_add : Icons.alarm_on,
                color: _reminder != null ? scheme.primary : iconColor,
              ),
              onPressed: _pickReminder,
            ),
            IconButton(
              tooltip: 'Warna',
              icon: Icon(Icons.palette_outlined, color: iconColor),
              onPressed: _pickColor,
            ),
            IconButton(
              tooltip: 'Notebook',
              icon: Icon(Icons.folder_outlined, color: iconColor),
              onPressed: () => _pickNotebook(notebooks),
            ),
            IconButton(
              tooltip: 'Tag',
              icon: Icon(Icons.label_outline, color: iconColor),
              onPressed: () => _pickTags(tags),
            ),
            IconButton(
              tooltip: 'Simpan',
              icon: _saving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: iconColor),
                    )
                  : Icon(Icons.check, color: iconColor),
              onPressed: _saving
                  ? null
                  : () async {
                      final ok = await _save();
                      if (ok && mounted) Navigator.pop(context);
                    },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_reminder != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: textColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.alarm, size: 16, color: textColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pengingat: ${AppDate.full(_reminder!)}',
                          style: TextStyle(fontSize: 12, color: textColor),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 16, color: textColor),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _reminder = null),
                      ),
                    ],
                  ),
                ),
              TextField(
                controller: _titleCtrl,
                cursorColor: textColor,
                decoration: InputDecoration(
                  hintText: 'Judul...',
                  hintStyle: TextStyle(color: hintColor),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Divider(color: dividerColor),
              Expanded(
                child: TextField(
                  controller: _contentCtrl,
                  cursorColor: textColor,
                  decoration: InputDecoration(
                    hintText: 'Tulis catatan di sini...',
                    hintStyle: TextStyle(color: hintColor),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(color: textColor),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
              if (_working.tagIds.isNotEmpty) _tagChips(tags, textColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tagChips(TagProvider tp, Color textColor) {
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
                  label: Text(tag.name, style: TextStyle(color: textColor)),
                  backgroundColor: textColor.withOpacity(0.15),
                  deleteIcon: Icon(Icons.close, size: 16, color: textColor),
                  onDeleted: () => setState(() => _working.tagIds.remove(id)),
                ),
              );
            })
            .toList(),
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await showImageSourceSheet(context);
    if (source == null) return;

    setState(() => _saving = true);
    try {
      if (source == 'gallery') {
        final list = await ImageAttachmentService().pickFromGallery();
        if (list.isNotEmpty) {
          setState(() => _attachments.addAll(list));
        }
      } else if (source == 'camera') {
        final path = await ImageAttachmentService().pickFromCamera();
        if (path != null) {
          setState(() => _attachments.add(path));
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _removeAttachment(int index) async {
    final path = _attachments[index];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Gambar?'),
        content: const Text('Gambar akan dihapus dari catatan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) {
      await ImageAttachmentService().deleteFile(path);
      setState(() => _attachments.removeAt(index));
    }
  }

  void _previewImage(String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: InteractiveViewer(
            child: Image.file(File(path)),
          ),
        ),
      ),
    );
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final initial = _reminder ?? now.add(const Duration(minutes: 5));

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    final picked = DateTime(
      date.year, date.month, date.day,
      time.hour, time.minute, 0, 0, 0,
    );

    if (picked.isBefore(DateTime.now().add(const Duration(seconds: 30)))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih waktu minimal 1 menit ke depan')),
        );
      }
      return;
    }

    setState(() => _reminder = picked);
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
                child: const Icon(Icons.close, size: 18, color: Colors.black),
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
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16, right: 16, top: 16),
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
