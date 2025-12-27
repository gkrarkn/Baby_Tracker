// lib/pages/settings/notification_prefs.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores notification preferences in SharedPreferences.
/// Time is stored as (hour, minute) pairs so user can pick any time.
///
/// Modules:
/// - Feeding (daily reminder)
/// - Vaccine (alerts before due date; time is "delivery time" for those alerts)
/// - Attacks (week entry alert + optional daily reminder during the week)
class NotificationPrefs {
  // -----------------------------
  // Keys
  // -----------------------------
  static const _kFeedingEnabled = 'notif_feeding_enabled';
  static const _kFeedingHour = 'notif_feeding_hour';
  static const _kFeedingMinute = 'notif_feeding_minute';

  static const _kVaccineEnabled = 'notif_vaccine_enabled';
  static const _kVaccineHour = 'notif_vaccine_hour';
  static const _kVaccineMinute = 'notif_vaccine_minute';

  static const _kAttackEnabled = 'notif_attack_enabled';
  static const _kAttackDailyEnabled = 'notif_attack_daily_enabled';
  static const _kAttackHour = 'notif_attack_hour';
  static const _kAttackMinute = 'notif_attack_minute';

  // -----------------------------
  // Defaults (app policy)
  // -----------------------------
  static const TimeOfDay _defaultFeedingTime = TimeOfDay(hour: 20, minute: 0);
  static const TimeOfDay _defaultVaccineTime = TimeOfDay(hour: 10, minute: 0);
  static const TimeOfDay _defaultAttackTime = TimeOfDay(hour: 9, minute: 0);

  // -----------------------------
  // Public API: FEEDING
  // -----------------------------
  static Future<FeedingPrefs> loadFeeding() async {
    final sp = await SharedPreferences.getInstance();
    final enabled = sp.getBool(_kFeedingEnabled) ?? false;
    final time = _readTime(
      sp,
      _kFeedingHour,
      _kFeedingMinute,
      _defaultFeedingTime,
    );
    return FeedingPrefs(enabled: enabled, time: time);
  }

  static Future<void> saveFeeding(FeedingPrefs prefs) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kFeedingEnabled, prefs.enabled);
    await _writeTime(sp, _kFeedingHour, _kFeedingMinute, prefs.time);
  }

  // -----------------------------
  // Public API: VACCINE
  // -----------------------------
  static Future<VaccinePrefs> loadVaccine() async {
    final sp = await SharedPreferences.getInstance();
    final enabled = sp.getBool(_kVaccineEnabled) ?? true;
    final time = _readTime(
      sp,
      _kVaccineHour,
      _kVaccineMinute,
      _defaultVaccineTime,
    );
    return VaccinePrefs(enabled: enabled, time: time);
  }

  static Future<void> saveVaccine(VaccinePrefs prefs) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kVaccineEnabled, prefs.enabled);
    await _writeTime(sp, _kVaccineHour, _kVaccineMinute, prefs.time);
  }

  // -----------------------------
  // Public API: ATTACKS
  // -----------------------------
  static Future<AttackPrefs> loadAttack() async {
    final sp = await SharedPreferences.getInstance();
    final enabled = sp.getBool(_kAttackEnabled) ?? true;
    final dailyEnabled = sp.getBool(_kAttackDailyEnabled) ?? false;
    final time = _readTime(
      sp,
      _kAttackHour,
      _kAttackMinute,
      _defaultAttackTime,
    );
    return AttackPrefs(
      enabled: enabled,
      dailyEnabled: dailyEnabled,
      time: time,
    );
  }

  static Future<void> saveAttack(AttackPrefs prefs) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kAttackEnabled, prefs.enabled);
    await sp.setBool(_kAttackDailyEnabled, prefs.dailyEnabled);
    await _writeTime(sp, _kAttackHour, _kAttackMinute, prefs.time);
  }

  // -----------------------------
  // Utilities: Generic
  // -----------------------------

  /// Single call if you want to present all prefs at once (settings screen load).
  static Future<AllNotificationPrefs> loadAll() async {
    final feeding = await loadFeeding();
    final vaccine = await loadVaccine();
    final attack = await loadAttack();
    return AllNotificationPrefs(
      feeding: feeding,
      vaccine: vaccine,
      attack: attack,
    );
  }

  /// Optional: reset everything to defaults.
  static Future<void> resetAllToDefaults() async {
    final sp = await SharedPreferences.getInstance();

    await sp.setBool(_kFeedingEnabled, false);
    await _writeTime(sp, _kFeedingHour, _kFeedingMinute, _defaultFeedingTime);

    await sp.setBool(_kVaccineEnabled, true);
    await _writeTime(sp, _kVaccineHour, _kVaccineMinute, _defaultVaccineTime);

    await sp.setBool(_kAttackEnabled, true);
    await sp.setBool(_kAttackDailyEnabled, false);
    await _writeTime(sp, _kAttackHour, _kAttackMinute, _defaultAttackTime);
  }

  static TimeOfDay _readTime(
    SharedPreferences sp,
    String hourKey,
    String minuteKey,
    TimeOfDay fallback,
  ) {
    final h = sp.getInt(hourKey);
    final m = sp.getInt(minuteKey);
    if (h == null || m == null) return fallback;

    // Guard rails (defensive)
    if (h < 0 || h > 23) return fallback;
    if (m < 0 || m > 59) return fallback;

    return TimeOfDay(hour: h, minute: m);
  }

  static Future<void> _writeTime(
    SharedPreferences sp,
    String hourKey,
    String minuteKey,
    TimeOfDay time,
  ) async {
    await sp.setInt(hourKey, time.hour);
    await sp.setInt(minuteKey, time.minute);
  }
}

// ------------------------------------------------------------
// Models (strongly typed, cleaner than tuples)
// ------------------------------------------------------------

class FeedingPrefs {
  final bool enabled;
  final TimeOfDay time;

  const FeedingPrefs({required this.enabled, required this.time});

  FeedingPrefs copyWith({bool? enabled, TimeOfDay? time}) =>
      FeedingPrefs(enabled: enabled ?? this.enabled, time: time ?? this.time);
}

class VaccinePrefs {
  final bool enabled;
  final TimeOfDay time;

  const VaccinePrefs({required this.enabled, required this.time});

  VaccinePrefs copyWith({bool? enabled, TimeOfDay? time}) =>
      VaccinePrefs(enabled: enabled ?? this.enabled, time: time ?? this.time);
}

class AttackPrefs {
  final bool enabled;
  final bool dailyEnabled;
  final TimeOfDay time;

  const AttackPrefs({
    required this.enabled,
    required this.dailyEnabled,
    required this.time,
  });

  AttackPrefs copyWith({bool? enabled, bool? dailyEnabled, TimeOfDay? time}) =>
      AttackPrefs(
        enabled: enabled ?? this.enabled,
        dailyEnabled: dailyEnabled ?? this.dailyEnabled,
        time: time ?? this.time,
      );
}

class AllNotificationPrefs {
  final FeedingPrefs feeding;
  final VaccinePrefs vaccine;
  final AttackPrefs attack;

  const AllNotificationPrefs({
    required this.feeding,
    required this.vaccine,
    required this.attack,
  });
}
