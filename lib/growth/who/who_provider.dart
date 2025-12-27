// lib/growth/who/who_provider.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import 'who_models.dart';

class WhoProvider {
  WhoProvider._();
  static final WhoProvider instance = WhoProvider._();

  final Map<String, WhoSeries> _cache = {};

  String _assetPath(WhoGender gender, WhoMetric metric) {
    final g = gender == WhoGender.boy ? 'boy' : 'girl';

    final m = switch (metric) {
      WhoMetric.weight => 'weight',
      WhoMetric.length => 'length',
      WhoMetric.head => 'head',
    };

    return 'assets/who/${g}_${m}_0_24m.json';
  }

  String _cacheKey(WhoGender gender, WhoMetric metric) =>
      '${gender.name}_${metric.name}_0_24m';

  Future<WhoSeries> load(WhoGender gender, WhoMetric metric) async {
    final key = _cacheKey(gender, metric);
    final cached = _cache[key];
    if (cached != null) return cached;

    final path = _assetPath(gender, metric);
    final raw = await rootBundle.loadString(path);

    final decoded = jsonDecode(raw);
    final list =
        (decoded as List)
            .map((e) => WhoPoint.fromMap(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => a.ageDays.compareTo(b.ageDays));

    final series = WhoSeries(list);
    _cache[key] = series;
    return series;
  }

  /// Mikro metin: Normal / Üst sınır / Alt sınır / Sınır dışı
  /// Basit ve etkili: p3-p97 bandı
  Future<String?> statusText({
    required WhoGender gender,
    required WhoMetric metric,
    required int ageDays,
    required double value,
  }) async {
    final series = await load(gender, metric);
    final p = series.nearest(ageDays);
    if (p == null) return null;

    // çok “basit” sınıflandırma (ürün MVP için yeterli)
    if (value < p.p3) return 'Alt sınırın altında';
    if (value > p.p97) return 'Üst sınırın üstünde';

    // band içinde: p50’ye yakınlığını da “mikro” hissiyat için kullan
    final mid = p.p50;
    final dist = (value - mid).abs();

    // eşik: bandın %15'i kadar yakınsa "Normal aralıkta"
    final band = (p.p97 - p.p3).abs();
    final near = band == 0 ? 0 : dist / band;

    if (near <= 0.15) return 'Normal aralıkta';
    return 'Normal aralıkta';
  }
}
