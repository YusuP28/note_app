import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/note_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/note_card.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NoteProvider>().setFilter(NoteFilter.archived);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<NoteProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Arsip')),
      body: p.notes.isEmpty
          ? const EmptyState(icon: Icons.archive_outlined, title: 'Arsip kosong')
          : ListView.builder(
              itemCount: p.notes.length,
              itemBuilder: (_, i) {
                final n = p.notes[i];
                return Dismissible(
                  key: ValueKey(n.id),
                  background: Container(
                    color: Colors.orange,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.unarchive, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    await context.read<NoteProvider>().archive(n, false);
                    return false;
                  },
                  child: NoteCard(
                    note: n,
                    onTap: () {},
                    onLongPress: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Keluarkan dari Arsip?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal')),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Ya')),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        await context.read<NoteProvider>().archive(n, false);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
