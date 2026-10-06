import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/note.dart';
import '../../models/tag.dart';
import '../../providers/note_provider.dart';
import '../../providers/notebook_provider.dart';
import '../../providers/tag_provider.dart';
import '../../utils/date_utils.dart';
import '../../services/quill_image_service.dart';
import '../../services/image_attachment_service.dart';
import '../../widgets/image_picker_sheet.dart';
import '../../widgets/local_image_embed.dart';

class EditScreen extends StatefulWidget {
  final Note? note;
  final bool readOnly;
  const EditScreen({super.key, this.note, this.readOnly = false});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late TextEditingController _titleCtrl;
  late quill.QuillController _contentCtrl;
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  late Note _working;
  bool _isNew = false;
  bool _saving = false;
  DateTime? _reminder;
  String? _bgImagePath;
  double _bgOpacity = 0.3;
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
    _contentCtrl = _buildQuillController(_working.content);
    if (widget.readOnly) _contentCtrl.readOnly = true;

    _reminder = _working.reminderAt;
    _bgImagePath = _working.bgImagePath;
    _bgOpacity = _working.bgOpacity;

    // Force re-render setelah frame pertama (fix bg image kadang tidak muncul)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _bgImagePath != null) {
        setState(() {});
      }
    });

    _draftKeyTitle = 'draft_${_working.id}_title';
    _draftKeyContent = 'draft_${_working.id}_content';
    _titleCtrl.addListener(_onDraftChange);
    _contentCtrl.addListener(_onDraftChange);
    if (_isNew) _restoreDraft();
  }

  quill.QuillController _buildQuillController(String content) {
    try {
      if (content.trim().startsWith('[')) {
        final json = jsonDecode(content);
        if (json is List) {
          final doc = quill.Document.fromJson(json);
          return quill.QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
        }
      }
    } catch (_) {}
    final doc = quill.Document()..insert(0, content);
    return quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
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
        if (c.isNotEmpty) _contentCtrl = _buildQuillController(c);
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
    await p.setString(_draftKeyContent, _deltaJson());
  }

  Future<void> _clearDraft() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_draftKeyTitle);
    await p.remove(_draftKeyContent);
  }

  String _deltaJson() => jsonEncode(_contentCtrl.document.toDelta().toJson());
  String _plainText() => _contentCtrl.document.toPlainText().trim();

  Future<bool> _save({bool silent = false}) async {
    if (_saving) return false;
    _saving = true;

    final p = context.read<NoteProvider>();
    final title = _titleCtrl.text.trim();
    final delta = _deltaJson();
    final plain = _plainText();

    if (title.isEmpty && plain.isEmpty && _bgImagePath == null) {
      await _clearDraft();
      _saving = false;
      return true;
    }

    try {
      if (_isNew) {
        final created = await p.addNote(
          title: title.isEmpty ? 'Tanpa Judul' : title,
          content: '',
          notebookId: _working.notebookId,
        );
        created.content = delta;
        created.plainText = plain;
        if (_working.color != null) created.color = _working.color;
        created.tagIds = List.from(_working.tagIds);
        created.bgImagePath = _bgImagePath;
        created.bgOpacity = _bgOpacity;
        await p.updateNote(created);
        if (_reminder != null) await p.setReminder(created, _reminder);
        _working = created;
        _isNew = false;
      } else {
        _working.title = title.isEmpty ? 'Tanpa Judul' : title;
        _working.content = delta;
        _working.plainText = plain;
        _working.bgImagePath = _bgImagePath;
        _working.bgOpacity = _bgOpacity;
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

  Color _contrastText(Color bg) =>
      bg.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

  Future<void> _insertImage() async {
    final source = await showImageSourceSheet(context);
    if (source == null) return;
    if (source == 'gallery') {
      await QuillImageService().insertFromGallery(_contentCtrl);
    } else if (source == 'camera') {
      await QuillImageService().insertFromCamera(_contentCtrl);
    }
  }

  Future<void> _pickBackgroundImage() async {
    final source = await showImageSourceSheet(context);
    if (source == null) return;
    String? path;
    if (source == 'gallery') {
      final files = await ImageAttachmentService().pickFromGallery();
      if (files.isNotEmpty) path = files.first;
    } else {
      path = await ImageAttachmentService().pickFromCamera();
    }
    if (path != null) {
      setState(() => _bgImagePath = path);
    }
  }

  void _showOpacitySlider() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Transparansi Background',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.brightness_low, size: 18),
                  Expanded(
                    child: Slider(
                      value: _bgOpacity,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      label: '${(_bgOpacity * 100).round()}%',
                      onChanged: (v) {
                        setLocal(() {});
                        setState(() => _bgOpacity = v);
                      },
                    ),
                  ),
                  const Icon(Icons.brightness_high, size: 18),
                ],
              ),
              Center(
                child: Text('${(_bgOpacity * 100).round()}%',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              const Text('Semakin kecil % → gambar lebih transparan',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notebooks = context.watch<NotebookProvider>();
    final tags = context.watch<TagProvider>();
    final scheme = Theme.of(context).colorScheme;

    final customColor = _working.color != null ? Color(_working.color!) : null;
    final editorBg = customColor ?? scheme.surface;
    final textColor = customColor != null ? _contrastText(editorBg) : scheme.onSurface;
    final dividerColor = textColor.withOpacity(0.25);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _save(silent: true);
        if (!mounted) return;
        Navigator.of(context).maybePop();
      },
      child: Scaffold(
        backgroundColor: editorBg,
        appBar: AppBar(
          backgroundColor: editorBg,
          foregroundColor: textColor,
          elevation: 0,
          title: Text(
            widget.readOnly ? 'Baca Catatan' : (_isNew ? 'Catatan Baru' : 'Edit Catatan'),
            style: TextStyle(color: textColor),
          ),
          iconTheme: IconThemeData(color: textColor),
          actions: widget.readOnly
              ? [
                  IconButton(
                    tooltip: 'Bagikan',
                    icon: Icon(Icons.share_outlined, color: textColor),
                    onPressed: () => _shareReadOnly(context),
                  ),
                  IconButton(
                    tooltip: 'Edit',
                    icon: Icon(Icons.edit_outlined, color: textColor),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditScreen(note: widget.note),
                        ),
                      );
                    },
                  ),
                ]
              : [
            // Tombol Simpan (utama)
            IconButton(
              tooltip: 'Simpan',
              icon: _saving
                  ? SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: textColor),
                    )
                  : Icon(Icons.check, color: textColor),
              onPressed: _saving ? null : () async {
                final ok = await _save();
                if (ok && mounted) Navigator.pop(context);
              },
            ),
            // Overflow menu
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: textColor),
              onSelected: (v) {
                switch (v) {
                  case 'reminder': _pickReminder(); break;
                  case 'color': _pickColor(); break;
                  case 'bg': _pickBackgroundImage(); break;
                  case 'bg_opacity': _showOpacitySlider(); break;
                  case 'bg_clear':
                    setState(() { _bgImagePath = null; _bgOpacity = 0.3; });
                    break;
                  case 'notebook': _pickNotebook(notebooks); break;
                  case 'tag': _pickTags(tags); break;
                  case 'image': _insertImage(); break;
                  case 'read_preview':
                    if (!_isNew && widget.note != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditScreen(note: _working, readOnly: true),
                        ),
                      );
                    }
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'reminder',
                  child: Row(children: [
                    Icon(_reminder == null ? Icons.alarm_add : Icons.alarm_on,
                        size: 20, color: _reminder != null ? scheme.primary : null),
                    const SizedBox(width: 12),
                    Text(_reminder == null ? 'Set Pengingat' : 'Ubah Pengingat'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'image',
                  child: Row(children: [
                    Icon(Icons.image_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Tambah Gambar'),
                  ]),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'color',
                  child: Row(children: [
                    Icon(Icons.palette_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Warna Catatan'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'bg',
                  child: Row(children: [
                    Icon(Icons.wallpaper_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Background Gambar'),
                  ]),
                ),
                if (_bgImagePath != null) ...[
                  const PopupMenuItem(
                    value: 'bg_opacity',
                    child: Row(children: [
                      Icon(Icons.opacity, size: 20),
                      SizedBox(width: 12),
                      Text('Transparansi BG'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'bg_clear',
                    child: Row(children: [
                      Icon(Icons.clear, size: 20),
                      SizedBox(width: 12),
                      Text('Hapus Background'),
                    ]),
                  ),
                ],
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'notebook',
                  child: Row(children: [
                    Icon(Icons.folder_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Notebook'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'tag',
                  child: Row(children: [
                    Icon(Icons.label_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Tag'),
                  ]),
                ),
                if (!_isNew) ...[
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'read_preview',
                    child: Row(children: [
                      Icon(Icons.menu_book_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Mode Baca'),
                    ]),
                  ),
                ],
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            // Background image
            if (_bgImagePath != null && _bgImagePath!.isNotEmpty)
              Positioned.fill(
                child: Opacity(
                  opacity: _bgOpacity,
                  child: Image.file(
                    File(_bgImagePath!),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    cacheWidth: 1080,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
            // Main content (dengan bg semi-transparan)
            Container(
              color: editorBg.withOpacity(_bgImagePath != null ? 0.7 : 1.0),
              child: Column(
              children: [
                if (_reminder != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _titleCtrl,
                    cursorColor: textColor,
                    decoration: InputDecoration(
                      hintText: 'Judul...',
                      hintStyle: TextStyle(color: textColor.withOpacity(0.55)),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ),
                Divider(color: dividerColor),
                quill.QuillSimpleToolbar(
                  configurations: quill.QuillSimpleToolbarConfigurations(
                    controller: _contentCtrl,
                    multiRowsDisplay: false,
                    showUndo: true,
                    showRedo: true,
                    showBoldButton: true,
                    showItalicButton: true,
                    showUnderLineButton: true,
                    showStrikeThrough: true,
                    showListBullets: true,
                    showListNumbers: true,
                    showListCheck: true,
                    showHeaderStyle: true,
                    showInlineCode: false,
                    showClearFormat: true,
                    showQuote: true,
                    showLink: true,
                    showCodeBlock: true,
                    showIndent: true,
                    showAlignmentButtons: true,
                    showColorButton: true,
                    showBackgroundColorButton: true,
                    showSubscript: false,
                    showSuperscript: false,
                  ),
                ),
                Divider(height: 1, color: dividerColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: quill.QuillEditor.basic(
                      focusNode: _focusNode,
                      scrollController: _scrollCtrl,
                      configurations: quill.QuillEditorConfigurations(
                        controller: _contentCtrl,
                        placeholder: widget.readOnly ? '' : 'Tulis catatan di sini...',
                        padding: EdgeInsets.zero,
                        autoFocus: false,
                        expands: true,
                        embedBuilders: [LocalImageEmbedBuilder()],
                      ),
                    ),
                  ),
                ),
                if (_working.tagIds.isNotEmpty) _tagChips(tags, textColor),
              ],
            ),
            ),
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _working.tagIds
            .where(map.containsKey)
            .map((id) {
              final tag = map[id]!;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Chip(
                  label: Text(tag.name, style: TextStyle(color: textColor, fontSize: 12)),
                  backgroundColor: textColor.withOpacity(0.15),
                  deleteIcon: Icon(Icons.close, size: 14, color: textColor),
                  onDeleted: () => setState(() => _working.tagIds.remove(id)),
                ),
              );
            })
            .toList(),
      ),
    );
  }


  Future<void> _shareReadOnly(BuildContext context) async {
    if (widget.note == null) return;
    final content = widget.note!.title.isEmpty
        ? widget.note!.plainText
        : '${widget.note!.title}\n\n${widget.note!.plainText}';
    await Clipboard.setData(ClipboardData(text: content));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tersalin ke clipboard'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final initial = _reminder ?? now.add(const Duration(minutes: 5));
    final date = await showDatePicker(
      context: context, initialDate: initial, firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context, initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute, 0, 0, 0);
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
      const Color(0xFF6750A4), const Color(0xFFE57373),
      const Color(0xFFFFB74D), const Color(0xFFFFF176),
      const Color(0xFF81C784), const Color(0xFF64B5F6),
      const Color(0xFFBA68C8), const Color(0xFFA1887F),
    ];
    final picked = await showDialog<Color?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Warna'),
        content: Wrap(
          spacing: 10, runSpacing: 10,
          children: [
            ...colors.map((c) => GestureDetector(
                  onTap: () => Navigator.pop(ctx, c),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: c, shape: BoxShape.circle,
                      border: Border.all(color: Colors.black26),
                    ),
                  ),
                )),
            GestureDetector(
              onTap: () => Navigator.pop(ctx, Colors.transparent),
              child: Container(
                width: 44, height: 44,
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
                  leading: CircleAvatar(radius: 10, backgroundColor: Color(nb.color)),
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
                const Text('Tag', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      spacing: 8, runSpacing: 8,
                      children: tp.tags.map((Tag t) {
                        final sel = _working.tagIds.contains(t.id);
                        return FilterChip(
                          label: Text(t.name),
                          selected: sel,
                          onSelected: (v) => setState(() {
                            if (v) { _working.tagIds.add(t.id); }
                            else { _working.tagIds.remove(t.id); }
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
