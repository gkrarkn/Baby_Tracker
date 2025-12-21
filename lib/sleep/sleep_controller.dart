// lib/sleep/sleep_controller.dart
import 'package:flutter/foundation.dart';

import 'sleep_entry.dart';
import 'sleep_repository.dart';

class SleepController extends ChangeNotifier {
  final SleepRepository _repo;

  SleepController({SleepRepository? repository})
    : _repo = repository ?? const SleepRepository();

  bool _loading = true;
  bool get isLoading => _loading;

  final List<SleepEntry> _entries = []; // newest first
  List<SleepEntry> get entries => List.unmodifiable(_entries);

  DateTime? _currentStart; // null => awake
  DateTime? get currentStart => _currentStart;

  bool get isSleeping => _currentStart != null;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    final snap = await _repo.load();
    _entries
      ..clear()
      ..addAll(snap.entries);

    _currentStart = snap.currentSleepStart;

    _loading = false;
    notifyListeners();
  }

  Future<void> toggleSleep() async {
    if (_currentStart == null) {
      _currentStart = DateTime.now();
      notifyListeners();
      await _repo.saveCurrentStart(_currentStart);
      return;
    }

    final now = DateTime.now();
    final start = _currentStart!;
    if (now.isBefore(start)) {
      // clock skew / fail-safe
      _currentStart = null;
      notifyListeners();
      await _repo.saveCurrentStart(null);
      return;
    }

    final entry = SleepEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      start: DateTime(
        start.year,
        start.month,
        start.day,
        start.hour,
        start.minute,
        start.second,
      ),
      end: DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
        now.second,
      ),
    );

    _currentStart = null;
    _entries.insert(0, entry);
    _entries.sort((a, b) => b.start.compareTo(a.start)); // newest first
    notifyListeners();

    await _repo.saveEntries(_entries);
    await _repo.saveCurrentStart(null);
  }

  Future<void> deleteEntryById(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    await _repo.saveEntries(_entries);
  }

  Future<void> clearAll() async {
    _entries.clear();
    _currentStart = null;
    notifyListeners();
    await _repo.clearAll();
  }

  // -----------------------------
  // Derived (UI helpers)
  // -----------------------------
  Duration todayTotalSleep() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    Duration total = Duration.zero;

    for (final e in _entries) {
      final startDay = DateTime(e.start.year, e.start.month, e.start.day);
      if (startDay != todayStart) continue;
      total += e.duration;
    }

    if (_currentStart != null) {
      final s = _currentStart!;
      final sDay = DateTime(s.year, s.month, s.day);
      if (sDay == todayStart) {
        total += DateTime.now().difference(s);
      }
    }

    return total;
  }

  SleepEntry? lastSleep() => _entries.isEmpty ? null : _entries.first;

  Map<DateTime, Duration> last7DaysTotals() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final map = <DateTime, Duration>{};
    for (int i = 0; i < 7; i++) {
      final d = today.subtract(Duration(days: i));
      map[d] = Duration.zero;
    }

    for (final e in _entries) {
      final day = DateTime(e.start.year, e.start.month, e.start.day);
      if (!map.containsKey(day)) continue;
      map[day] = (map[day] ?? Duration.zero) + e.duration;
    }

    if (_currentStart != null) {
      final s = _currentStart!;
      final day = DateTime(s.year, s.month, s.day);
      if (map.containsKey(day)) {
        map[day] = (map[day] ?? Duration.zero) + DateTime.now().difference(s);
      }
    }

    return map;
  }
}
