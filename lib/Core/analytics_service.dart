// lib/core/analytics_service.dart
import 'package:flutter/foundation.dart';

// Firebase eklediğinde aç:
// import 'package:firebase_analytics/firebase_analytics.dart';

import 'app_globals.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  bool get enabled => anonDataOptIn.value;

  /// Low-risk event logger (only runs if anonDataOptIn == true)
  Future<void> log(
    String name, {
    Map<String, Object?> params = const {},
  }) async {
    if (!enabled) return;

    final safeParams = _sanitize(params);

    // 🔹 Firebase eklendiğinde:
    // await FirebaseAnalytics.instance.logEvent(
    //   name: name,
    //   parameters: safeParams,
    // );

    // 🔹 Şimdilik debug çıktısı
    if (kDebugMode) {
      // ignore: avoid_print
      print('[analytics] $name $safeParams');
    }
  }

  /// Convenience helpers (optional but clean)
  Future<void> appOpen() => log('app_open');

  Future<void> screenView(String screen) =>
      log('screen_view', params: {'screen': screen});

  Future<void> sleepToggle({required String action}) => log(
    'sleep_toggle',
    params: {
      'action': action, // start | stop
    },
  );

  Future<void> sleepEntryAdded({required int durationMin}) =>
      log('sleep_entry_added', params: {'duration_min': durationMin});

  Future<void> settingsAnonToggle({required bool enabledNow}) =>
      log('settings_toggle_anon_analytics', params: {'enabled': enabledNow});

  Map<String, Object?> _sanitize(Map<String, Object?> params) {
    // Firebase tarafı için de güvenli tipler: String/num/bool
    final out = <String, Object?>{};
    params.forEach((k, v) {
      if (v == null) return;
      if (v is String || v is num || v is bool) {
        out[k] = v;
        return;
      }
      // diğer tipler string'e çevrilsin
      out[k] = v.toString();
    });
    return out;
  }
}
