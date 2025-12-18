import 'package:flutter/material.dart';

import '../core/app_globals.dart';

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
      floatingActionButton: FloatingActionButton(
        backgroundColor: mainColor,
        onPressed: () => _openEditor(),
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
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                        itemCount: _controller.notes.length,
                        itemBuilder: (_, index) {
                          final Note note = _controller.notes[index];
                          return NoteTile(
                            note: note,
                            onTap: () => _openEditor(note: note),
                            onDelete: () => _controller.delete(note),
                            onPin: () => _controller.togglePin(note),
                            onReminder: () => _pickReminder(note),
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

  // ---------------------------
  // UI Helpers
  // ---------------------------

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

  // ---------------------------
  // Actions
  // ---------------------------

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
}
