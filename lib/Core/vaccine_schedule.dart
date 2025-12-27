// lib/core/vaccine_schedule.dart
/// 0–24 ay için "Aşı kontrolü" milestone listesi.
/// - dueDate = doğum tarihine göre ay eklenmiş tarih
/// - Bildirimler NotificationService.scheduleVaccineReminders() ile:
///   -7 gün ve -1 gün şeklinde planlanır.
class VaccineSchedule {
  VaccineSchedule._();

  /// Basit ve stabil id: ay numarası (0..24).
  /// İleride genişletmek istersen: (month * 100 + index) gibi genişletilebilir.
  static final List<VaccineMilestone> milestones = List.generate(
    25,
    (i) => VaccineMilestone(
      id: i,
      month: i,
      title: i == 0 ? 'Aşı kontrolü: Doğum (0. ay)' : 'Aşı kontrolü: $i. ay',
    ),
  );

  static DateTime dueDateFor({
    required DateTime birthDate,
    required int month,
  }) {
    return _addMonthsSafe(_dateOnly(birthDate), month);
  }

  // ---------------------------------------------------------------------------
  // Date helpers
  // ---------------------------------------------------------------------------

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _addMonthsSafe(DateTime d, int monthsToAdd) {
    final int newMonth0 = (d.month - 1) + monthsToAdd;
    final int newYear = d.year + (newMonth0 ~/ 12);
    final int newMonth = (newMonth0 % 12) + 1;

    final int lastDay = _daysInMonth(newYear, newMonth);
    final int newDay = d.day <= lastDay ? d.day : lastDay;

    return DateTime(newYear, newMonth, newDay);
  }

  static int _daysInMonth(int year, int month) {
    final nextMonth = (month == 12)
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    final lastDay = nextMonth.subtract(const Duration(days: 1));
    return lastDay.day;
  }
}

class VaccineMilestone {
  final int id;
  final int month;
  final String title;

  const VaccineMilestone({
    required this.id,
    required this.month,
    required this.title,
  });
}
