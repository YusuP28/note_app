import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/note.dart';
import '../../providers/note_provider.dart';
import '../../providers/notebook_provider.dart';
import '../../providers/tag_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/lock_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/note_card.dart';
import '../../themes/neumo.dart';
import '../../widgets/note_context_sheet.dart';
import '../archive/archive_screen.dart';
import '../notebooks/notebooks_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import '../tags/tags_screen.dart';
import '../trash/trash_screen.dart';
import 'edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _initialized = false;
  bool _selectionMode = false;
  DateTime? _lastBackPress;
  final Set<String> _selectedIds = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final s = context.read<SettingsProvider>();
        final n = context.read<NoteProvider>();
        if (n.sortBy != s.sort) n.setSortBy(s.sort);
        await n.load();
        if (!mounted) return;
        await context.read<NotebookProvider>().load();
        if (!mounted) return;
        await context.read<TagProvider>().load();
      });
    }
  }

  Future<void> _openNote(Note? note) async {
    // Cek kalau catatan locked
    if (note != null && note.isLocked) {
      final lock = LockService();
      final enabled = await lock.isEnabled();
      if (enabled) {
        if (!mounted) return;
        final unlocked = await _promptUnlock(lock);
        if (!unlocked) return;
      }
    }

    if (!mounted) return;
    final nav = Navigator.of(context);
    if (!nav.mounted) return;
    final result = await nav.push<Note?>(
      MaterialPageRoute(builder: (_) => EditScreen(note: note)),
    );
    if (result != null && mounted) {
      await context.read<NoteProvider>().updateNote(result);
    }
  }

  Future<bool> _promptUnlock(LockService lock) async {
    // Coba fingerprint dulu kalau enabled
    final fpEnabled = await lock.isFingerprintEnabled();
    if (fpEnabled && await lock.canUseBiometric()) {
      final ok = await lock.authenticateBiometric();
      if (ok) return true;
    }

    if (!mounted) return false;
    final ctrl = TextEditingController();
    final hint = await lock.getHint();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Catatan Terkunci'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'PIN',
                hintText: hint != null ? 'Hint: $hint' : null,
                border: const OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'forgot'),
                  child: const Text('Lupa PIN?'),
                ),
                if (fpEnabled)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, 'bio'),
                    child: const Text('Fingerprint'),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Buka'),
          ),
        ],
      ),
    );

    if (result == null) return false;

    if (result == 'bio') {
      final ok = await lock.authenticateBiometric();
      return ok;
    }

    if (result == 'forgot') {
      if (!mounted) return false;
      return await _promptBackupCode(lock);
    }

    final valid = await lock.verifyPin(result);
    if (!valid && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN salah')),
      );
    }
    return valid;
  }

  Future<bool> _promptBackupCode(LockService lock) async {
    final codeCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan backup code + PIN baru'),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Backup Code',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'PIN Baru',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (ok != true) return false;

    final success = await lock.resetWithBackupCode(
      codeCtrl.text.trim(),
      newPinCtrl.text.trim(),
    );
    if (!mounted) return false;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN berhasil direset')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup code salah')),
      );
    }
    return false; // user harus buka ulang pakai PIN baru
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _enterSelectionMode(String id) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan?'),
        content: Text('${_selectedIds.length} catatan akan dipindah ke sampah.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final p = context.read<NoteProvider>();
    int count = 0;
    for (final id in _selectedIds) {
      final note = p.notes.firstWhere((n) => n.id == id, orElse: () => Note(id: '', createdAt: DateTime.now(), updatedAt: DateTime.now()));
      if (note.id.isNotEmpty) {
        await p.trash(note);
        count++;
      }
    }
    _exitSelectionMode();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count catatan dipindah ke sampah')),
      );
    }
  }

  Future<void> _archiveSelected() async {
    final p = context.read<NoteProvider>();
    int count = 0;
    for (final id in _selectedIds) {
      final note = p.notes.firstWhere((n) => n.id == id, orElse: () => Note(id: '', createdAt: DateTime.now(), updatedAt: DateTime.now()));
      if (note.id.isNotEmpty) {
        await p.archive(note, true);
        count++;
      }
    }
    _exitSelectionMode();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count catatan diarsipkan')),
      );
    }
  }

  Future<void> _pinSelected() async {
    final p = context.read<NoteProvider>();
    for (final id in _selectedIds) {
      final note = p.notes.firstWhere((n) => n.id == id, orElse: () => Note(id: '', createdAt: DateTime.now(), updatedAt: DateTime.now()));
      if (note.id.isNotEmpty) await p.togglePin(note);
    }
    _exitSelectionMode();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_selectedIds.length} catatan disematkan')),
      );
    }
  }

  Future<void> _showContextMenu(Note note) async {
    final action = await showNoteContextSheet(context, note);
    if (action == null || !mounted) return;
    await handleNoteAction(context, note, action);
  }

  Future<void> _confirmDelete(Note note) async {
    final p = context.read<NoteProvider>();
    final act = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(note.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
              title: Text(note.isPinned ? 'Lepas pin' : 'Sematkan'),
              onTap: () => Navigator.pop(ctx, 'pin'),
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Arsipkan'),
              onTap: () => Navigator.pop(ctx, 'archive'),
            ),
            ListTile(
              leading: Icon(note.isLocked ? Icons.lock_open : Icons.lock_outline),
              title: Text(note.isLocked ? 'Buka Kunci' : 'Kunci Catatan'),
              onTap: () => Navigator.pop(ctx, 'lock'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Pindah ke Sampah'),
              onTap: () => Navigator.pop(ctx, 'trash'),
            ),
          ],
        ),
      ),
    );
    if (act == 'pin') await p.togglePin(note);
    if (act == 'archive') await p.archive(note, true);
    if (act == 'trash') await p.trash(note);
    if (act == 'lock') {
      if (!mounted) return;
      await p.toggleLock(note);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(note.isLocked ? 'Catatan dikunci' : 'Kunci dibuka')),
      );
    }
  }

  void _openDrawerItem(Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _showSortMenu() async {
    final s = context.read<SettingsProvider>();
    final n = context.read<NoteProvider>();
    final picked = await showModalBottomSheet<SortBy>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Urutkan berdasarkan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            _sortTile(ctx, 'Terbaru diubah', SortBy.updatedDesc, s.sort),
            _sortTile(ctx, 'Terlama diubah', SortBy.updatedAsc, s.sort),
            _sortTile(ctx, 'Terbaru dibuat', SortBy.createdDesc, s.sort),
            _sortTile(ctx, 'Terlama dibuat', SortBy.createdAsc, s.sort),
            _sortTile(ctx, 'Judul A-Z', SortBy.titleAsc, s.sort),
            _sortTile(ctx, 'Judul Z-A', SortBy.titleDesc, s.sort),
          ],
        ),
      ),
    );
    if (picked != null) {
      await s.setSort(picked);
      n.setSortBy(picked);
    }
  }

  Widget _sortTile(BuildContext ctx, String label, SortBy value, SortBy current) {
    return ListTile(
      leading: Icon(
        value == current ? Icons.radio_button_checked : Icons.radio_button_off,
        color: value == current ? Theme.of(ctx).colorScheme.primary : null,
      ),
      title: Text(label),
      onTap: () => Navigator.pop(ctx, value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<NoteProvider>();
    final s = context.watch<SettingsProvider>();
    final title = switch (p.filter) {
      NoteFilter.all => 'Catatanku',
      NoteFilter.pinned => 'Disematkan',
      NoteFilter.archived => 'Arsip',
      NoteFilter.trashed => 'Sampah',
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress != null &&
            now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          if (mounted) Navigator.of(context).maybePop();
          return;
        }
        _lastBackPress = now;
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tekan sekali lagi untuk keluar'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: _selectionMode
          ? _buildSelectionAppBar(context, p)
          : AppBar(
          title: const SizedBox.shrink(),
        elevation: 0,
        backgroundColor: Neumo.bg(context),
        surfaceTintColor: Colors.transparent,
        shadowColor: Neumo.shadowDark(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist),
            tooltip: 'Pilih Banyak',
            onPressed: () => setState(() => _selectionMode = true),
          ),
          IconButton(
            icon: Icon(s.view == ViewMode.list ? Icons.grid_view : Icons.view_list),
            tooltip: s.view == ViewMode.list ? 'Grid' : 'List',
            onPressed: () => s.toggleView(),
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Urutkan',
            onPressed: _showSortMenu,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      drawer: _selectionMode ? null : _buildDrawer(context, p),
      body: p.loading
          ? const Center(child: CircularProgressIndicator())
          : p.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 56, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(p.error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => p.load(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : p.notes.isEmpty
                  ? const EmptyState(
                      icon: Icons.note_outlined,
                      title: 'Belum ada catatan',
                      subtitle: 'Tap tombol + untuk mulai',
                    )
                  : s.view == ViewMode.grid
                      ? GridView.builder(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 4),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: p.notes.length,
                          itemBuilder: (_, i) {
                            final n = p.notes[i];
                            return NoteCard(
                              note: n,
                              gridMode: true,
                              selected: _selectedIds.contains(n.id),
                              selectionMode: _selectionMode,
                              onTap: _selectionMode ? () => _toggleSelection(n.id) : () => _openNote(n),
                              onLongPress: _selectionMode ? () => _toggleSelection(n.id) : () => _showContextMenu(n),
                            );
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: p.notes.length,
                          itemBuilder: (_, i) {
                            final n = p.notes[i];
                            return NoteCard(
                              note: n,
                              selected: _selectedIds.contains(n.id),
                              selectionMode: _selectionMode,
                              onTap: _selectionMode ? () => _toggleSelection(n.id) : () => _openNote(n),
                              onLongPress: _selectionMode ? () => _toggleSelection(n.id) : () => _showContextMenu(n),
                            );
                          },
                        ),
      floatingActionButton: p.filter == NoteFilter.trashed ||
              p.filter == NoteFilter.archived
          ? null
          : NeumoFab(
              icon: Icons.add,
              onPressed: () => _openNote(null),
            ),
    );
    );
  }


  PreferredSizeWidget _buildSelectionAppBar(BuildContext context, NoteProvider p) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitSelectionMode,
      ),
      title: Text('${_selectedIds.length} dipilih'),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          tooltip: 'Pilih Semua',
          onPressed: () {
            setState(() {
              if (_selectedIds.length == p.notes.length) {
                _selectedIds.clear();
              } else {
                _selectedIds.addAll(p.notes.map((n) => n.id));
              }
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.push_pin_outlined),
          tooltip: 'Sematkan',
          onPressed: _selectedIds.isEmpty ? null : _pinSelected,
        ),
        IconButton(
          icon: const Icon(Icons.archive_outlined),
          tooltip: 'Arsipkan',
          onPressed: _selectedIds.isEmpty ? null : _archiveSelected,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Hapus',
          onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
        ),
      ],
    );
  }
  Widget _buildDrawer(BuildContext context, NoteProvider p) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.note_alt_outlined,
                      color: Theme.of(context).colorScheme.primary, size: 28),
                  const SizedBox(width: 10),
                  const Text('Catatanku',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Divider(height: 1),
            _tile(Icons.notes, 'Semua', NoteFilter.all, p),
            _tile(Icons.push_pin_outlined, 'Disematkan', NoteFilter.pinned, p),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Notebook'),
              onTap: () => _openDrawerItem(const NotebooksScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.label_outline),
              title: const Text('Tag'),
              onTap: () => _openDrawerItem(const TagsScreen()),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Arsip'),
              onTap: () => _openDrawerItem(const ArchiveScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Sampah'),
              onTap: () => _openDrawerItem(const TrashScreen()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String text, NoteFilter f, NoteProvider p) {
    final selected = p.filter == f;
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
      onTap: () {
        p.setNotebookFilter(null);
        p.setTagFilter(null);
        p.setFilter(f);
        Navigator.pop(context);
      },
    );
  }
}
