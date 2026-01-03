import 'package:flutter/foundation.dart';

import '../core/analytics_service.dart';
import 'sleep_entry.dart';
import 'sleep_repository.dart';
import 'sleep_window_calculator.dart';
import 'sleep_window_reminder_service.dart';

typedef BabyAgeInMonthsGetter = int Function();

class SleepController extends ChangeNotifier {
  final SleepRepository _repo;
  final BabyAgeInMonthsGetter _ageInMonths;

  SleepController({
    SleepRepository? repository,
    required BabyAgeInMonthsGetter ageInMonths,
  }) : _repo = repository ?? const SleepRepository(),
       _ageInMonths = ageInMonths;

  // --------------------------------------------------
  // Loading
  // --------------------------------------------------

  bool _loading = true;
  bool get isLoading => _loading;

  // --------------------------------------------------
  // Data
  // --------------------------------------------------

  final List<SleepEntry> _entries = []; // newest first
  List<SleepEntry> get entries => List.unmodifiable(_entries);

  DateTime? _currentStart; // null => awake
  DateTime? get currentStart => _currentStart;
  bool get isSleeping => _currentStart != null;

  // --------------------------------------------------
  // Sleep Window Reminder (Premium)
  // --------------------------------------------------

  DateTime? _lastWakeTime;
  DateTime? get lastWakeTime => _lastWakeTime;

  bool _sleepWindowReminderEnabled = true;
  bool get sleepWindowReminderEnabled => _sleepWindowReminderEnabled;

  void setSleepWindowReminderEnabled(bool value) {
    if (_sleepWindowReminderEnabled == value) return;

    _sleepWindowReminderEnabled = value;
    notifyListeners();

    if (!value) {
      SleepWindowReminderService.cancel();
    }
  }

  // --------------------------------------------------
  // Lifecycle
  // --------------------------------------------------

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

  // --------------------------------------------------
  // Main Action
  // --------------------------------------------------

  Future<void> toggleSleep() async {
    // ----------------------------
    // START (awake → sleeping)
    // ----------------------------
    if (_currentStart == null) {
      _currentStart = DateTime.now();
      notifyListeners();

      await AnalyticsService.instance.log(
        'sleep_toggle',
        params: {'action': 'start'},
      );

      await _repo.saveCurrentStart(_currentStart);
      return;
    }

    // ----------------------------
    // STOP (sleeping → awake)
    // ----------------------------
    final now = DateTime.now();
    final start = _currentStart!;

    if (now.isBefore(start)) {
      // fail-safe (clock skew)
      _currentStart = null;
      notifyListeners();
      await _repo.saveCurrentStart(null);
      return;
    }

    final entry = SleepEntry(
      id: now.millisecondsSinceEpoch.toString(),
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
    _entries.sort((a, b) => b.start.compareTo(a.start));
    notifyListeners();

    await AnalyticsService.instance.log(
      'sleep_toggle',
      params: {'action': 'stop'},
    );

    final minutes = entry.duration.inMinutes;
    if (minutes >= 1) {
      await AnalyticsService.instance.log(
        'sleep_entry_added',
        params: {'duration_min': minutes},
      );
    }

    await _repo.saveEntries(_entries);
    await _repo.saveCurrentStart(null);

    // ----------------------------
    // WAKE EVENT → Sleep Window
    // ----------------------------
    _lastWakeTime = now;

    final ageInMonths = _ageInMonths();
    if (_sleepWindowReminderEnabled && ageInMonths > 0) {
      await SleepWindowReminderService.schedule(
        lastWakeTime: _lastWakeTime!,
        ageInMonths: ageInMonths,
      );
    }
  }

  // --------------------------------------------------
  // Deletion / Reset
  // --------------------------------------------------

  Future<void> deleteEntryById(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    await _repo.saveEntries(_entries);
  }

  Future<void> clearAll() async {
    _entries.clear();
    _currentStart = null;
    _lastWakeTime = null;
    notifyListeners();
    await _repo.clearAll();
  }

  // --------------------------------------------------
  // Derived (UI helpers)
  // --------------------------------------------------

  Duration todayTotalSleep() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    Duration total = Duration.zero;

    for (final e in _entries) {
      final d = DateTime(e.start.year, e.start.month, e.start.day);
      if (d != today) continue;
      total += e.duration;
    }

    if (_currentStart != null) {
      final s = _currentStart!;
      final d = DateTime(s.year, s.month, s.day);
      if (d == today) {
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
      map[today.subtract(Duration(days: i))] = Duration.zero;
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

  // --------------------------------------------------
  // Sleep Window – Micro UI helpers
  // --------------------------------------------------

  /// Örn: "19:10 – 19:40"
  String? get recommendedSleepRangeText {
    if (_lastWakeTime == null) return null;

    final ageInMonths = _ageInMonths();
    if (ageInMonths <= 0) return null;

    final target = SleepWindowCalculator.calculateTargetSleep(
      lastWakeTime: _lastWakeTime!,
      ageInMonths: ageInMonths,
    );

    final start = target.subtract(const Duration(minutes: 15));
    final end = target.add(const Duration(minutes: 15));

    String fmt(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return '${fmt(start)} – ${fmt(end)}';
  }

  /// Örn: "19:25"
  String? get formattedSleepTarget {
    if (_lastWakeTime == null) return null;

    final ageInMonths = _ageInMonths();
    if (ageInMonths <= 0) return null;

    final target = SleepWindowCalculator.calculateTargetSleep(
      lastWakeTime: _lastWakeTime!,
      ageInMonths: ageInMonths,
    );

    return '${target.hour.toString().padLeft(2, '0')}:${target.minute.toString().padLeft(2, '0')}';
  }
}
