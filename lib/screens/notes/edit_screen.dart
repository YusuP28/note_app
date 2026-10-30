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
  final String? searchQuery; // Kata kunci untuk highlight
  const EditScreen({super.key, this.note, this.readOnly = false, this.searchQuery});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> with WidgetsBindingObserver {
  late TextEditingController _titleCtrl;
  late quill.QuillController _contentCtrl;
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  late Note _working;
  bool _isNew = false;
  bool _saving = false;
  bool _dirty = false;
  DateTime? _reminder;
  String? _bgImagePath;
  double _bgOpacity = 0.3;
  Timer? _draftTimer;
  String? _searchQuery; // Kata kunci pencarian untuk highlight
  List<int> _highlightPositions = []; // Posisi offset dari highlight
  int _currentHighlightIndex = 0; // Index highlight saat ini

  String get _draftKeyTitle => 'draft_${_working.id}_title';
  String get _draftKeyContent => 'draft_${_working.id}_content';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isNew = widget.note == null;
    _working = widget.note ??
        Note(id: '', createdAt: DateTime.now(), updatedAt: DateTime.now());
    _titleCtrl = TextEditingController(text: _working.title);
    _contentCtrl = _buildQuillController(_working.content);
    if (widget.readOnly) _contentCtrl.readOnly = true;

    _reminder = _working.reminderAt;
    _bgImagePath = _working.bgImagePath;
    _bgOpacity = _working.bgOpacity;

    // Simpan search query
    _searchQuery = widget.searchQuery;

    // Force re-render setelah frame pertama (fix bg image kadang tidak muncul)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _bgImagePath != null) {
        setState(() {});
      }
      // Apply highlight jika ada search query
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        _applySearchHighlight();
      }
    });

    _titleCtrl.addListener(_onDraftChange);
    _contentCtrl.addListener(_onDraftChange);
    if (!widget.readOnly) _restoreDraft();
  }

  /// Terapkan highlight kuning pada semua kemunculan _searchQuery
  void _applySearchHighlight() {
    if (_searchQuery == null || _searchQuery!.isEmpty) return;
    final query = _searchQuery!.toLowerCase();
    final plainText = _contentCtrl.document.toPlainText().toLowerCase();
    _highlightPositions.clear();

    int index = 0;
    while (true) {
      index = plainText.indexOf(query, index);
      if (index == -1) break;
      _highlightPositions.add(index);
      index += query.length;
    }

    if (_highlightPositions.isNotEmpty) {
      // Terapkan background kuning pada setiap posisi
      const yellowHex = '#FFFF00';
      for (final pos in _highlightPositions) {
        _contentCtrl.formatText(pos, query.length,
            quill.Attribute(quill.Attribute.background.key, yellowHex, 'inline'),
            quill.ChangeSource.local);
      }
      // Scroll ke kemunculan pertama
      _scrollToHighlight(0);
    }
  }

  /// Scroll ke highlight tertentu
  void _scrollToHighlight(int index) {
    if (index < 0 || index >= _highlightPositions.length) return;
    _currentHighlightIndex = index;
    final offset = _highlightPositions[index];
    // Gunakan setSelection untuk scroll ke posisi
    _contentCtrl.updateSelection(
      TextSelection.collapsed(offset: offset),
      quill.ChangeSource.local,
    );
    // Scroll controller juga
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          offset.toDouble() * 20.0, // Estimasi tinggi per karakter
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
    final doc = quill.Document();
    if (content.isNotEmpty) doc.insert(0, content);
    return quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftTimer?.cancel();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _draftTimer?.cancel();
      _saveDraft();
    }
  }

  Future<void> _restoreDraft() async {
    final p = await SharedPreferences.getInstance();
    final hasTitle = p.containsKey(_draftKeyTitle);
    final hasContent = p.containsKey(_draftKeyContent);
    if (!hasTitle && !hasContent) return;

    final t = p.getString(_draftKeyTitle) ?? '';
    final c = p.getString(_draftKeyContent) ?? '';
    if (!mounted) return;

    final oldCtrl = _contentCtrl;
    // Cek mounted lagi di dalam setState untuk menghindari race condition
    setState(() {
      if (!mounted) return;
      _titleCtrl.text = t;
      if (hasContent) {
        _contentCtrl = _buildQuillController(c);
        _contentCtrl.addListener(_onDraftChange);
      }
      _dirty = true;
    });
    // Cek mounted lagi sebelum dispose controller lama
    if (!mounted) return;
    if (!identical(oldCtrl, _contentCtrl)) {
      oldCtrl.dispose();
    }

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft dipulihkan'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  void _onDraftChange() {
    if (widget.readOnly) return;
    _dirty = true;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(seconds: 3), _saveDraft);
  }

  Future<void> _saveDraft() async {
    if (widget.readOnly || !_dirty) return;
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
    _draftTimer?.cancel();

    final p = context.read<NoteProvider>();
    final title = _titleCtrl.text.trim();
    final delta = _deltaJson();
    final plain = _plainText();
    final blankTitleKey = _isNew ? _draftKeyTitle : null;
    final blankContentKey = _isNew ? _draftKeyContent : null;

    if (_isNew && title.isEmpty && plain.isEmpty && _bgImagePath == null) {
      await _clearDraft();
      _dirty = false;
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
      _dirty = false;
      await _clearDraft();
      if (blankTitleKey != null && blankContentKey != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(blankTitleKey);
        await prefs.remove(blankContentKey);
      }
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

  // ═══════════════════════════════════════════════════════════
  //  NAVIGASI KURSOR — Arrow Keys
  // ═══════════════════════════════════════════════════════════

  /// Geser kursor 1 karakter (kiri/kanan)
  void _moveCursor(int delta) {
    final sel = _contentCtrl.selection;
    final doc = _contentCtrl.document;
    final maxOffset = doc.length - 1;
    final newOffset = (sel.baseOffset + delta).clamp(0, maxOffset);
    if (newOffset != sel.baseOffset) {
      _contentCtrl.updateSelection(
        TextSelection.collapsed(offset: newOffset),
        quill.ChangeSource.local,
      );
    }
  }

  /// Geser kursor 1 baris (atas/bawah)
  void _moveLine(int direction) {
    final sel = _contentCtrl.selection;
    final doc = _contentCtrl.document;
    final text = doc.toPlainText();
    if (text.isEmpty) return;

    final currentOffset = sel.baseOffset;
    final lineStart = text.lastIndexOf('\n', currentOffset - 1) + 1;

    int newOffset;
    if (direction < 0) {
      // Ke atas
      if (lineStart == 0) return;
      final prevLineEnd = lineStart - 1;
      final prevLineStart = text.lastIndexOf('\n', prevLineEnd - 1) + 1;
      final col = currentOffset - lineStart;
      newOffset = (prevLineStart + col).clamp(prevLineStart, prevLineEnd);
    } else {
      // Ke bawah
      final lineEnd = text.indexOf('\n', currentOffset);
      if (lineEnd == -1) return;
      final nextLineStart = lineEnd + 1;
      if (nextLineStart >= text.length) return;
      final nextLineEnd = text.indexOf('\n', nextLineStart);
      final col = currentOffset - lineStart;
      final limit = nextLineEnd == -1 ? text.length : nextLineEnd;
      newOffset = (nextLineStart + col).clamp(nextLineStart, limit);
    }

    _contentCtrl.updateSelection(
      TextSelection.collapsed(offset: newOffset),
      quill.ChangeSource.local,
    );
  }

  /// Pindah ke awal baris
  void _moveHome() {
    final sel = _contentCtrl.selection;
    final text = _contentCtrl.document.toPlainText();
    final lineStart = text.lastIndexOf('\n', sel.baseOffset - 1) + 1;
    _contentCtrl.updateSelection(
      TextSelection.collapsed(offset: lineStart),
      quill.ChangeSource.local,
    );
  }

  /// Pindah ke akhir baris
  void _moveEnd() {
    final sel = _contentCtrl.selection;
    final text = _contentCtrl.document.toPlainText();
    final lineEnd = text.indexOf('\n', sel.baseOffset);
    final target = lineEnd == -1 ? text.length : lineEnd;
    _contentCtrl.updateSelection(
      TextSelection.collapsed(offset: target),
      quill.ChangeSource.local,
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
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
        // Save background — non-blocking
        _save(silent: true).catchError((_) => false);
        }
      },
      child: Scaffold(
        backgroundColor: editorBg,
        // Background tidak boleh ikut ter-resize saat keyboard muncul.
        resizeToAvoidBottomInset: false,
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
                child: SizedBox(
                  // Kunci tinggi ke layar penuh agar tidak bergerak saat keyboard muncul.
                  height: MediaQuery.of(context).size.height,
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
              ),
            // Main content (dengan bg semi-transparan)
            // Hanya area ini yang turun/bergeser mengikuti keyboard.
            Positioned.fill(
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
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
