import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/notification_service.dart';
import 'note_model.dart';

class NotesController extends ChangeNotifier {
  static const _storageKey = 'notes_v5';

  final List<Note> _notes = [];
  String _searchQuery = '';

  List<Note> get notes {
    final q = _searchQuery.trim().toLowerCase();

    final filtered = q.isEmpty
        ? List<Note>.from(_notes)
        : _notes.where((n) => n.text.toLowerCase().contains(q)).toList();

    filtered.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  String get searchQuery => _searchQuery;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;

    _notes
      ..clear()
      ..addAll(Note.decodeList(raw));

    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, Note.encodeList(_notes));
  }

  void setSearch(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  Future<void> add(Note note) async {
    _notes.add(note);
    await _persist();
    notifyListeners();
  }

  Future<void> update(Note note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index == -1) return;

    _notes[index] = note;
    await _persist();
    notifyListeners();
  }

  Future<void> delete(Note note) async {
    // Notes reminder deterministic id ile noteId’den üretildiği için
    // notificationId tutmaya gerek yok; direkt note.id üzerinden iptal ediyoruz.
    await NotificationService.instance.cancelNoteReminder(note.id);

    _notes.removeWhere((n) => n.id == note.id);
    await _persist();
    notifyListeners();
  }

  Future<void> togglePin(Note note) async {
    await update(note.copyWith(pinned: !note.pinned));
  }

  /// time == null => reminder kaldır
  Future<void> setReminder(Note note, DateTime? time) async {
    // Önce varsa iptal
    await NotificationService.instance.cancelNoteReminder(note.id);

    // Yeni reminder kurulacaksa schedule et
    if (time != null) {
      await NotificationService.instance.scheduleNoteReminder(
        noteId: note.id,
        title: 'Baby Tracker',
        body: note.text,
        when: time,
      );
    }

    // Modelde reminder state’i güncelle
    await update(
      note.copyWith(
        reminderAt: time,
        notificationId: null, // artık kullanılmıyor
      ),
    );
  }
}
