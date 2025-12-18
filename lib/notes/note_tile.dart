import 'package:flutter/material.dart';
import 'note_model.dart';
import 'note_date_formatter.dart';

class NoteTile extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final VoidCallback onReminder;

  const NoteTile({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
    required this.onPin,
    required this.onReminder,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(note.text),
        subtitle: note.reminderAt != null
            ? Text(
                '⏰ ${formatReminderDateTR(note.reminderAt!)}',
                style: const TextStyle(fontSize: 12),
              )
            : null,
        onTap: onTap,
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              icon: Icon(
                note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
              ),
              onPressed: onPin,
            ),
            IconButton(
              icon: Icon(
                note.reminderAt != null
                    ? Icons.alarm
                    : Icons.alarm_add_outlined,
              ),
              onPressed: onReminder,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
