// lib/notes/notes_controller.dart
import 'package:flutter/foundation.dart';

import 'note_model.dart';
import 'notes_repository.dart';

class NotesController extends ChangeNotifier {
  final NotesRepository _repo;

  NotesController({NotesRepository? repository})
    : _repo = repository ?? const NotesRepository();

  final List<Note> _all = [];
  String _query = '';

  bool _loading = false;
  bool get isLoading => _loading;

  /// UI bunu kullanır (arama + sıralama uygulanmış liste)
  List<Note> get notes {
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? List<Note>.from(_all)
        : _all.where((n) => n.text.toLowerCase().contains(q)).toList();

    filtered.sort(_noteSort);
    return filtered;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    final loaded = await _repo.load();
    _all
      ..clear()
      ..addAll(loaded);
    _all.sort(_noteSort);

    _loading = false;
    notifyListeners();
  }

  void setSearch(String v) {
    _query = v;
    notifyListeners();
  }

  Future<void> add(Note note) async {
    // boş not eklenmesin (tek satır güvenlik)
    if (note.text.trim().isEmpty) return;

    _all.insert(0, note);
    _all.sort(_noteSort);
    notifyListeners();
    await _repo.save(_all);
  }

  Future<void> update(Note updated) async {
    if (updated.text.trim().isEmpty) return;

    final idx = _all.indexWhere((n) => n.id == updated.id);
    if (idx == -1) return;

    _all[idx] = updated;
    _all.sort(_noteSort);
    notifyListeners();
    await _repo.save(_all);
  }

  Future<void> togglePin(Note note) async {
    final idx = _all.indexWhere((n) => n.id == note.id);
    if (idx == -1) return;

    _all[idx] = note.copyWith(pinned: !note.pinned);
    _all.sort(_noteSort);
    notifyListeners();
    await _repo.save(_all);
  }

  /// Swipe ile silince çağır: (removedNote, originalIndex) döner
  Future<(Note removed, int index)> removeForUndo(String noteId) async {
    final idx = _all.indexWhere((n) => n.id == noteId);
    if (idx == -1) {
      throw StateError('Note not found: $noteId');
    }
    final removed = _all.removeAt(idx);
    notifyListeners();
    await _repo.save(_all);
    return (removed, idx);
  }

  Future<void> undoRemove(Note note, int index) async {
    final safeIndex = index.clamp(0, _all.length);
    _all.insert(safeIndex, note);
    _all.sort(_noteSort);
    notifyListeners();
    await _repo.save(_all);
  }

  Future<void> delete(String noteId) async {
    _all.removeWhere((n) => n.id == noteId);
    notifyListeners();
    await _repo.save(_all);
  }

  Future<void> clearAll() async {
    _all.clear();
    notifyListeners();
    await _repo.clear();
  }

  int _noteSort(Note a, Note b) {
    // 1) pinned üstte
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    // 2) yeni olan üstte
    return b.createdAt.compareTo(a.createdAt);
  }

  // Hatırlatıcı fonksiyonların varsa şimdilik koruyorsun:
  Future<void> setReminder(Note note, DateTime? when) async {
    final idx = _all.indexWhere((n) => n.id == note.id);
    if (idx == -1) return;

    _all[idx] = note.copyWith(reminderAt: when);
    _all.sort(_noteSort);
    notifyListeners();
    await _repo.save(_all);
  }
}
