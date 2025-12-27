// lib/attacks/attack_calculator.dart
import 'attack_data.dart';
import 'attack_model.dart';

class AttackCalculator {
  /// Düzeltilmiş yaş için referans tarih:
  /// - Prematüre senaryosu: dueDate girilmişse ve birthDate < dueDate ise dueDate baz alınır.
  /// - Aksi halde birthDate baz alınır.
  static DateTime ageBaseDate({
    required DateTime birthDate,
    DateTime? dueDate,
  }) {
    if (dueDate != null && birthDate.isBefore(dueDate)) {
      return _dateOnly(dueDate);
    }
    return _dateOnly(birthDate);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static int correctedAgeInDays({
    required DateTime birthDate,
    DateTime? dueDate,
    DateTime? now,
  }) {
    final base = ageBaseDate(birthDate: birthDate, dueDate: dueDate);
    final t = _dateOnly(now ?? DateTime.now());
    final diff = t.difference(base).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Şu an pencereye denk gelen dönemi döndürür (yoksa null).
  static AttackModel? currentAttack({
    required DateTime birthDate,
    DateTime? dueDate,
    DateTime? now,
  }) {
    final base = ageBaseDate(birthDate: birthDate, dueDate: dueDate);
    final t = _dateOnly(now ?? DateTime.now());

    AttackModel? best;
    int bestDistance = 1 << 30;

    for (final a in AttackData.items) {
      final target = a.targetDate(base);
      final diffDays = t
          .difference(target)
          .inDays; // + ise geçti, - ise yaklaşmakta

      final start = -a.windowStartDays;
      final end = a.windowEndDays;

      if (diffDays >= start && diffDays <= end) {
        final dist = diffDays.abs();
        if (dist < bestDistance) {
          best = a;
          bestDistance = dist;
        }
      }
    }

    return best;
  }

  static bool isAttackPossible({
    required DateTime birthDate,
    DateTime? dueDate,
    DateTime? now,
  }) {
    return currentAttack(birthDate: birthDate, dueDate: dueDate, now: now) !=
        null;
  }

  /// UI için kısa durum etiketi (privacy-safe).
  static String statusLabel({
    required DateTime? birthDate,
    DateTime? dueDate,
    DateTime? now,
  }) {
    if (birthDate == null) return 'Atak takibi için doğum tarihini ekleyin';
    final a = currentAttack(birthDate: birthDate, dueDate: dueDate, now: now);
    if (a == null) return 'Şu an belirgin atak penceresi yok';
    return '${a.month}. ay civarı';
  }

  static String calcNote({required DateTime birthDate, DateTime? dueDate}) {
    final prem = (dueDate != null && birthDate.isBefore(dueDate));
    if (!prem) return 'Hesaplama doğum tarihine göre yapılır.';
    return 'Hesaplama beklenen doğum tarihine göre düzeltilmiş yaş ile yapılır.';
  }
}
