import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/note_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/note_card.dart';
import '../notes/edit_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChange(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      context.read<NoteProvider>().search(v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<NoteProvider>();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Cari catatan...',
            border: InputBorder.none,
          ),
          onChanged: _onChange,
        ),
        actions: [
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _ctrl.clear();
                context.read<NoteProvider>().search('');
              },
            ),
        ],
      ),
      body: p.query.isEmpty
          ? const EmptyState(
              icon: Icons.search,
              title: 'Ketik untuk mencari',
              subtitle: 'Cari di judul & isi catatan',
            )
          : p.notes.isEmpty
              ? const EmptyState(icon: Icons.search_off, title: 'Tidak ditemukan')
              : ListView.builder(
                  itemCount: p.notes.length,
                  itemBuilder: (_, i) {
                    final n = p.notes[i];
                    return NoteCard(
                      note: n,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EditScreen(note: n)),
                      ),
                      onLongPress: () {},
                    );
                  },
                ),
    );
  }
}
