import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'sleep_entry.dart';
import 'sleep_keys.dart';
import 'sleep_mappers.dart';

class SleepStateSnapshot {
  final List<SleepEntry> entries; // newest first
  final DateTime? currentSleepStart;

  const SleepStateSnapshot({
    required this.entries,
    required this.currentSleepStart,
  });
}

class SleepRepository {
  const SleepRepository();

  Future<SleepStateSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();

    DateTime? currentStart;
    final current = prefs.getString(SleepKeys.currentStartV2);
    if (current != null && current.trim().isNotEmpty) {
      currentStart = DateTime.tryParse(current);
    }

    final entries = <SleepEntry>[];
    final raw = prefs.getString(SleepKeys.entriesV2);
    if (raw != null && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        entries.addAll(
          decoded.whereType<Map>().map(
            (m) => SleepMappers.fromMap(Map<String, dynamic>.from(m)),
          ),
        );
      }
    }

    entries.sort((a, b) => b.start.compareTo(a.start)); // newest first

    return SleepStateSnapshot(
      entries: entries,
      currentSleepStart: currentStart,
    );
  }

  Future<void> saveEntries(List<SleepEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      SleepKeys.entriesV2,
      jsonEncode(entries.map(SleepMappers.toMap).toList()),
    );
  }

  Future<void> saveCurrentStart(DateTime? start) async {
    final prefs = await SharedPreferences.getInstance();
    if (start == null) {
      await prefs.remove(SleepKeys.currentStartV2);
    } else {
      await prefs.setString(SleepKeys.currentStartV2, start.toIso8601String());
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(SleepKeys.entriesV2);
    await prefs.remove(SleepKeys.currentStartV2);
  }
}
