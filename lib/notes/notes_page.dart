// lib/notes/notes_page.dart
import 'package:flutter/material.dart';

import '../core/app_globals.dart';
import '../ads/anchored_adaptive_banner.dart';
import 'notes_controller.dart';
import 'note_model.dart';
import 'note_tile.dart';
import 'note_editor_sheet.dart';
import 'note_reminder_picker.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late final NotesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NotesController()..load();
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = appThemeColor.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notlar'),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const AnchoredAdaptiveBanner(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: mainColor,
        onPressed: _openEditor,
        child: const Icon(Icons.add),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Column(
            children: [
              _searchBar(),
              Expanded(
                child: _controller.notes.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                        // Banner üstüne binmemesi için extra bottom padding
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16 + 96),
                        itemCount: _controller.notes.length,
                        itemBuilder: (_, index) {
                          final Note note = _controller.notes[index];

                          return Dismissible(
                            key: ValueKey(note.id),
                            direction: DismissDirection.endToStart,
                            background: _dismissBg(),
                            confirmDismiss: (_) => _confirmDelete(note),
                            onDismissed: (_) => _deleteWithUndo(note),
                            child: NoteTile(
                              note: note,
                              onTap: () => _openEditor(note: note),
                              onDelete: () => _deleteWithUndo(note),
                              onPin: () => _controller.togglePin(note),
                              onReminder: () => _pickReminder(note),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: TextField(
        onChanged: _controller.setSearch,
        decoration: InputDecoration(
          hintText: 'Notlarda ara...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.note_alt_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 10),
          Text('Henüz not yok', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _dismissBg() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.red),
    );
  }

  void _openEditor({Note? note}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return NoteEditorSheet(
          note: note,
          onSave: (saved) {
            if (saved.text.trim().isEmpty) return;

            if (note == null) {
              _controller.add(saved);
            } else {
              _controller.update(saved);
            }
          },
        );
      },
    );
  }

  Future<void> _pickReminder(Note note) async {
    final picked = await showReminderPicker(context, note.reminderAt);
    await _controller.setReminder(note, picked);
  }

  Future<bool> _confirmDelete(Note note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Silinsin mi?'),
        content: const Text('Bu not silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _deleteWithUndo(Note note) async {
    ScaffoldMessenger.of(context).clearSnackBars();

    final (removed, index) = await _controller.removeForUndo(note.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Not silindi.'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'GERİ AL',
          onPressed: () => _controller.undoRemove(removed, index),
        ),
      ),
    );
  }
}
