import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/note.dart';
import '../../providers/note_provider.dart';
import '../../services/lock_guard.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/note_card.dart';
import '../notes/edit_screen.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  static const _kHintShown = 'trash_hint_shown_v1';
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<NoteProvider>().setFilter(NoteFilter.trashed);

      // Cek apakah hint sudah pernah ditampilkan
      final prefs = await SharedPreferences.getInstance();
      final shown = prefs.getBool(_kHintShown) ?? false;
      if (!shown && mounted) {
        setState(() => _showHint = true);
      }
    });
  }

  Future<void> _dismissHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHintShown, true);
    if (mounted) setState(() => _showHint = false);
  }

  Future<void> _restore(String id) async {
    final p = context.read<NoteProvider>();
    final n = p.notes.firstWhere((e) => e.id == id);
    await p.restore(n);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan dipulihkan'), duration: Duration(seconds: 2)),
      );
    }
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Permanen?'),
        content: const Text('Catatan ini tidak bisa dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<NoteProvider>().deletePermanently(id);
    }
  }

  Future<void> _openNote(Note note) async {
    if (!await assertUnlocked(context, note)) return;
    if (!mounted) return;
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditScreen(note: note)),
      );
    } catch (e) {
      debugPrint('trash openNote error: $e');
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<NoteProvider>().emptyTrash();
    }
  }

  /// Bottom sheet long-press menu
  void _showTrashMenu(NoteProvider p, Note n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Judul
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.restore_from_trash, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      n.isLocked
                          ? 'Catatan terkunci'
                          : (n.title.isEmpty ? '(Tanpa judul)' : n.title),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Menu: Pulihkan
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.green),
              title: const Text('Pulihkan'),
              subtitle: const Text('Kembalikan ke catatan'),
              onTap: () {
                Navigator.pop(ctx);
                _restore(n.id);
              },
            ),

            // Menu: Buka
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.blue),
              title: const Text('Buka'),
              subtitle: const Text('Lihat/edit catatan'),
              onTap: () {
                Navigator.pop(ctx);
                _openNote(n);
              },
            ),

            // Menu: Hapus Permanen
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Hapus Permanen'),
              subtitle: const Text('Tidak bisa dikembalikan'),
              onTap: () {
                Navigator.pop(ctx);
                _delete(n.id);
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<NoteProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sampah'),
        actions: [
          if (p.notes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Kosongkan Sampah',
              onPressed: _empty,
            ),
        ],
      ),
      body: Column(
        children: [
          // Hint banner (muncul sekali)
          if (_showHint && p.notes.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates, color: Colors.blue.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cara memulihkan catatan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Swipe kanan untuk pulihkan, kiri untuk hapus. Atau long-press untuk menu.',
                          style: TextStyle(color: Colors.blue.shade800, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: Colors.blue.shade700,
                    onPressed: _dismissHint,
                    tooltip: 'Tutup',
                  ),
                ],
              ),
            ),

          // List catatan
          Expanded(
            child: p.notes.isEmpty
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
                          child: const Icon(Icons.restore, color: Colors.white, size: 28),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_forever, color: Colors.white, size: 28),
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
                          onTap: () => _openNote(n),
                          onLongPress: () => _showTrashMenu(p, n),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
