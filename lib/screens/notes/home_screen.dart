import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/note.dart';
import '../../providers/note_provider.dart';
import '../../providers/notebook_provider.dart';
import '../../providers/tag_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/note_card.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final s = context.read<SettingsProvider>();
        final n = context.read<NoteProvider>();
        n.setSortBy(s.sort);
        await n.load();
        if (!mounted) return;
        await context.read<NotebookProvider>().load();
        if (!mounted) return;
        await context.read<TagProvider>().load();
      });
    }
  }

  Future<void> _openNote(Note? note) async {
    final result = await Navigator.push<Note?>(
      context,
      MaterialPageRoute(builder: (_) => EditScreen(note: note)),
    );
    if (result != null && mounted) {
      await context.read<NoteProvider>().updateNote(result);
    }
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

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
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
      drawer: _buildDrawer(context, p),
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
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 240,
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
                              onTap: () => _openNote(n),
                              onLongPress: () => _confirmDelete(n),
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
                              onTap: () => _openNote(n),
                              onLongPress: () => _confirmDelete(n),
                            );
                          },
                        ),
      floatingActionButton: p.filter == NoteFilter.trashed ||
              p.filter == NoteFilter.archived
          ? null
          : FloatingActionButton(
              onPressed: () => _openNote(null),
              child: const Icon(Icons.add),
            ),
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
