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
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2.5 : 0.6,
        ),
      ),
      margin: EdgeInsets.symmetric(
        vertical: 4,
        horizontal: gridMode ? 4 : 8,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
                  maxLines: gridMode ? 4 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
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
      ),
    );
  }
}
