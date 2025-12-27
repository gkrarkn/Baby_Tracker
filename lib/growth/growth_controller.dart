// lib/growth/growth_controller.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'growth_entry.dart';

class GrowthController extends ChangeNotifier {
  static const String _kGrowthEntriesKey = 'growthEntries_v1';

  final List<GrowthEntry> _entries = [];
  bool _loaded = false;

  /// UI için: en yeni en üstte
  List<GrowthEntry> get entriesNewestFirst {
    final list = List<GrowthEntry>.from(_entries);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// İstersen kullan: en eski -> en yeni
  List<GrowthEntry> get entriesOldestFirst {
    final list = List<GrowthEntry>.from(_entries);
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kGrowthEntriesKey);

    _entries.clear();

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              _entries.add(
                GrowthEntry.fromMap(Map<String, dynamic>.from(item)),
              );
            }
          }
        }
      } catch (_) {
        // Bozuk JSON varsa sessizce sıfırla (crash olmasın)
        _entries.clear();
      }
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> add(GrowthEntry entry) async {
    // Güvenlik: load çağrılmadıysa önce yükle
    if (!_loaded) {
      await load();
    }

    // Aynı id varsa güncelle
    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      _entries[idx] = entry;
    } else {
      _entries.add(entry);
    }

    await _persist();
    notifyListeners();
  }

  Future<void> deleteById(String id) async {
    if (!_loaded) {
      await load();
    }

    _entries.removeWhere((e) => e.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _entries.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();

    // Tarihe göre stabil kayıt (en eski -> en yeni)
    final list = entriesOldestFirst.map((e) => e.toMap()).toList();

    final raw = jsonEncode(list);
    await prefs.setString(_kGrowthEntriesKey, raw);
  }
}
