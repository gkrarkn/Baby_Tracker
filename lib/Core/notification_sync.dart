// lib/core/notification_sync.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../attacks/attack_calculator.dart';
import '../attacks/attack_data.dart';
import '../core/app_globals.dart';
import '../core/notification_service.dart';
import '../pages/settings/notification_prefs.dart';
import 'vaccine_schedule.dart';

/// Tek yerden "prefs -> schedule" senkronizasyonu.
/// UI sadece prefs yazar; bu sınıf schedule/cancel yönetir.
class NotificationSync {
  NotificationSync._();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// App açılışında (init sonrası) çağır.
  static Future<void> syncAll() async {
    final prefs = await NotificationPrefs.loadAll();
    await syncFeeding(prefs.feeding);
    await syncAttack(prefs.attack);
    await syncVaccine(prefs.vaccine);
  }

  /// Settings değişince sadece ilgili modülü sync etmek için.
  static Future<void> syncFeeding(FeedingPrefs prefs) async {
    await NotificationService.instance.scheduleDailyFeedingReminder(
      time: prefs.time,
      enabled: prefs.enabled,
    );
  }

  static Future<void> syncAttack(AttackPrefs prefs) async {
    if (!prefs.enabled) {
      await NotificationService.instance.cancelAttackWeek();
      return;
    }

    final dates = await _readBabyDates();
    final birth = dates.birthDate;
    if (birth == null) {
      // Doğum tarihi yoksa schedule edemeyiz.
      await NotificationService.instance.cancelAttackWeek();
      return;
    }

    final due = dates.dueDate;
    final nextStart = _nextAttackWeekStart(
      birthDate: birth,
      dueDate: due,
      now: DateTime.now(),
      userTime: prefs.time,
    );

    if (nextStart == null) {
      await NotificationService.instance.cancelAttackWeek();
      return;
    }

    await NotificationService.instance.scheduleAttackWeek(
      nextAttackWeekStart: nextStart,
      time: prefs.time,
      notifyOnStart: true,
      notifyDaily: prefs.dailyEnabled,
      days: 7,
    );
  }

  static Future<void> syncVaccine(VaccinePrefs prefs) async {
    final dates = await _readBabyDates();
    final birth = dates.birthDate;

    // Kapalıysa: tüm aşı bildirimlerini temizle.
    if (!prefs.enabled || birth == null) {
      for (final m in VaccineSchedule.milestones) {
        await NotificationService.instance.cancelVaccineReminders(m.id);
      }
      return;
    }

    // Açık + doğum tarihi var: tüm milestone'ları (yeniden) schedule et.
    for (final m in VaccineSchedule.milestones) {
      final dueDate = VaccineSchedule.dueDateFor(
        birthDate: birth,
        month: m.month,
      );

      await NotificationService.instance.scheduleVaccineReminders(
        vaccineId: m.id,
        vaccineName: m.title,
        dueDate: dueDate,
        remindTime: prefs.time,
        remind7DaysBefore: true,
        remind1DayBefore: true,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _combine(DateTime dateOnly, TimeOfDay t) =>
      DateTime(dateOnly.year, dateOnly.month, dateOnly.day, t.hour, t.minute);

  /// Atak "haftası" başlangıcını seçer:
  /// - Eğer bugün atak penceresinin içindeysek: bugün (ya da saat geçtiyse yarın)
  /// - Değilsek: gelecekteki en yakın pencere başlangıcı
  static DateTime? _nextAttackWeekStart({
    required DateTime birthDate,
    DateTime? dueDate,
    required DateTime now,
    required TimeOfDay userTime,
  }) {
    final base = AttackCalculator.ageBaseDate(
      birthDate: birthDate,
      dueDate: dueDate,
    );

    final today = _dateOnly(now);

    DateTime? best;

    for (final a in AttackData.items) {
      final target = _dateOnly(a.targetDate(base));
      final start = _dateOnly(
        target.subtract(Duration(days: a.windowStartDays)),
      );

      // Haftayı pencere başlangıcından itibaren 7 gün kabul ediyoruz.
      final end = _dateOnly(start.add(const Duration(days: 6)));

      DateTime candidate;

      if (!today.isBefore(start) && !today.isAfter(end)) {
        // Bugün pencerenin içindeyiz -> bugün bildir.
        final todayAtUserTime = _combine(today, userTime);
        candidate = todayAtUserTime.isAfter(now)
            ? today
            : today.add(const Duration(days: 1));
      } else if (!start.isBefore(today)) {
        // Gelecek pencere
        candidate = start;
      } else {
        continue;
      }

      if (best == null || candidate.isBefore(best)) best = candidate;
    }

    return best;
  }

  /// App-wide notifier'lar dolu değilse prefs'ten de okuyarak garanti eder.
  static Future<_BabyDates> _readBabyDates() async {
    DateTime? birth = babyBirthDate.value;
    DateTime? due = babyDueDate.value;

    if (birth != null || due != null) {
      return _BabyDates(birthDate: birth, dueDate: due);
    }

    final sp = await SharedPreferences.getInstance();
    birth = DateTime.tryParse(sp.getString(kBabyBirthDateKey) ?? '');
    due = DateTime.tryParse(sp.getString(kBabyDueDateKey) ?? '');

    return _BabyDates(birthDate: birth, dueDate: due);
  }
}

class _BabyDates {
  final DateTime? birthDate;
  final DateTime? dueDate;

  const _BabyDates({required this.birthDate, required this.dueDate});
}
