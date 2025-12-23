// lib/notes/notes_repository.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'note_model.dart';

class NotesRepository {
  static const String _kNotesKey = 'notes_list_v1';

  const NotesRepository();

  Future<List<Note>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kNotesKey);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      return Note.decodeList(raw);
    } catch (_) {
      // Bozuk veri varsa uygulama patlamasın
      return [];
    }
  }

  Future<void> save(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNotesKey, Note.encodeList(notes));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kNotesKey);
  }
}
