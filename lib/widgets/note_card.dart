import 'dart:io';
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../utils/date_utils.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool gridMode;
  final bool selected;
  final bool selectionMode;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
    this.gridMode = false,
    this.selected = false,
    this.selectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = note.color != null ? Color(note.color!) : scheme.surfaceContainerLow;

    return Card(
      color: bg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: scheme.primary.withOpacity(selected ? 1.0 : 0.5),
          width: selected ? 2.5 : 1.0,
        ),
      ),
      margin: EdgeInsets.symmetric(
        vertical: gridMode ? 2 : 4,
        horizontal: gridMode ? 2 : 8,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            // Background image
            if (note.bgImagePath != null && note.bgImagePath!.isNotEmpty)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Opacity(
                    opacity: note.bgOpacity,
                    child: Image.file(
                      File(note.bgImagePath!),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      cacheWidth: gridMode ? 400 : 800,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                ),
              ),
            // Content
            Padding(
          padding: EdgeInsets.all(gridMode ? 8 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (note.isPinned)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(Icons.push_pin, size: 14, color: scheme.primary),
                    ),
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? 'Tanpa Judul' : note.title,
                      maxLines: gridMode ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: gridMode ? 13 : 15,
                      ),
                    ),
                  ),
                  if (note.isLocked)
                    Icon(Icons.lock_outline, size: 14, color: scheme.primary),
                  if (selectionMode)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        selected ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 18,
                        color: selected ? scheme.primary : scheme.outline,
                      ),
                    ),
                ],
              ),
              if (note.plainText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  note.plainText,
                  maxLines: gridMode ? 3 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: gridMode ? 11 : 13,
                    height: 1.3,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    AppDate.short(note.updatedAt),
                    style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  if (note.reminderAt != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(Icons.alarm,
                          size: 13,
                          color: note.reminderAt!.isBefore(DateTime.now())
                              ? scheme.error
                              : scheme.primary),
                    ),
                  if (note.tagIds.isNotEmpty)
                    Icon(Icons.label_outline, size: 12, color: scheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
          ],
        ),
      ),
    );
  }
}
