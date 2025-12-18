import 'package:flutter/material.dart';

import 'note_model.dart';
import 'note_reminder_picker.dart';
import 'note_date_formatter.dart';

class NoteEditorSheet extends StatefulWidget {
  final Note? note;
  final ValueChanged<Note> onSave;

  const NoteEditorSheet({super.key, this.note, required this.onSave});

  @override
  State<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<NoteEditorSheet> {
  late final TextEditingController _controller;
  bool _pinned = false;
  DateTime? _reminder;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note?.text ?? '');
    _pinned = widget.note?.pinned ?? false;
    _reminder = widget.note?.reminderAt;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSave => _controller.text.trim().isNotEmpty;

  void _handleSave() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();

    final note =
        (widget.note ??
                Note(
                  id: now.millisecondsSinceEpoch.toString(),
                  text: '',
                  createdAt: now,
                ))
            .copyWith(
              text: text,
              pinned: _pinned,
              reminderAt: _reminder,
              // notificationId: controller tarafında artık kullanılmıyor (null bırakıyoruz)
              notificationId: null,
            );

    widget.onSave(note);
    Navigator.pop(context);
  }

  Future<void> _pickReminder() async {
    final picked = await showReminderPicker(context, _reminder);
    if (!mounted) return;
    setState(() => _reminder = picked);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.note == null ? 'Yeni Not' : 'Notu Düzenle';

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // küçük "handle"
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _canSave ? _handleSave : null,
                  child: const Text('Kaydet'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _controller,
              maxLines: null,
              autofocus: true,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Not yaz...',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                IconButton(
                  tooltip: _pinned ? 'Sabitlemeyi kaldır' : 'Sabitle',
                  icon: Icon(
                    _pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  ),
                  onPressed: () => setState(() => _pinned = !_pinned),
                ),
                IconButton(
                  tooltip: _reminder == null
                      ? 'Hatırlatıcı ekle'
                      : 'Hatırlatıcıyı değiştir',
                  icon: Icon(
                    _reminder == null ? Icons.alarm_add_outlined : Icons.alarm,
                  ),
                  onPressed: _pickReminder,
                ),
                const Spacer(),
                if (_reminder != null)
                  TextButton.icon(
                    onPressed: () => setState(() => _reminder = null),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Kaldır'),
                  ),
              ],
            ),

            if (_reminder != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '⏰ ${formatReminderDateTR(_reminder!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.70),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}
