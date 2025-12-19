import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'growth_entry.dart';

class GrowthController extends ChangeNotifier {
  /// Yeni format storage key (gram tabanlı)
  static const String _storageKey = 'growth_entries_v2_gr';

  /// Eğer eskiden kg ile tuttuysan (opsiyonel migrate için)
  static const String _legacyStorageKey = 'growth_entries_v1';

  final List<GrowthEntry> _entries = [];

  // growth_controller.dart içine EKLE (class GrowthController içinde)

  // En yeni en üstte (UI list için)
  List<GrowthEntry> get entriesSorted {
    final list = List<GrowthEntry>.from(_entries);
    list.sort((a, b) => b.date.compareTo(a.date)); // newest first
    return list;
  }

  /// İlk açılışta çağır
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // 1) Önce yeni formatı dene
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.trim().isNotEmpty) {
      _entries
        ..clear()
        ..addAll(_decodeList(raw));

      notifyListeners();
      return;
    }

    // 2) Yeni yoksa legacy dene (kg -> gr migrate)
    final legacyRaw = prefs.getString(_legacyStorageKey);
    if (legacyRaw != null && legacyRaw.trim().isNotEmpty) {
      final migrated = _decodeLegacyKgToGr(legacyRaw);

      _entries
        ..clear()
        ..addAll(migrated);

      await _persist(); // yeni formata yaz
      notifyListeners();
      return;
    }

    // boşsa
    _entries.clear();
    notifyListeners();
  }

  Future<void> add(GrowthEntry entry) async {
    _entries.add(entry);
    await _persist();
    notifyListeners();
  }

  Future<void> update(GrowthEntry entry) async {
    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx == -1) return;

    _entries[idx] = entry;
    await _persist();
    notifyListeners();
  }

  Future<void> deleteById(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _entries.clear();
    await _persist();
    notifyListeners();
  }

  // ---------------------------
  // Persistence
  // ---------------------------
  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_entries.map((e) => e.toMap()).toList());
    await prefs.setString(_storageKey, jsonStr);
  }

  List<GrowthEntry> _decodeList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((m) => GrowthEntry.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// Legacy format örneği varsayımı:
  /// { id, date, weightKg }  --> weightGr = round(weightKg * 1000)
  List<GrowthEntry> _decodeLegacyKgToGr(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded.whereType<Map>().map((m) {
      final map = Map<String, dynamic>.from(m);

      final id = (map['id'] ?? '').toString();
      final dateStr = (map['date'] ?? '').toString();

      // legacy: weightKg / weight / kg vb olasılıklar
      final num? kgNum =
          (map['weightKg'] as num?) ??
          (map['weight'] as num?) ??
          (map['kg'] as num?);

      final int weightGr = kgNum == null ? 0 : (kgNum * 1000).round();

      return GrowthEntry(
        id: id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : id,
        date: DateTime.tryParse(dateStr) ?? DateTime.now(),
        weightGr: weightGr,
      );
    }).toList();
  }
}
