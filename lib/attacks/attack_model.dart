// lib/attacks/attack_model.dart
class AttackModel {
  /// Ay bazlı (düzeltilmiş yaş) dönem tanımı.
  /// month: 4 => 4. ay dönemi gibi.
  final int month;

  /// Pencere gün cinsinden (hedef tarihten önce/sonra)
  final int windowStartDays; // targetDate - windowStartDays
  final int windowEndDays; // targetDate + windowEndDays

  final String title;
  final String description;
  final List<String> symptoms;
  final List<String> tips;

  const AttackModel({
    required this.month,
    required this.windowStartDays,
    required this.windowEndDays,
    required this.title,
    required this.description,
    required this.symptoms,
    required this.tips,
  });

  /// Düzeltilmiş yaş için baz tarih üzerine "month" ay ekleyerek hedef tarihi üretir.
  DateTime targetDate(DateTime baseDate) {
    return _addMonthsSafe(
      DateTime(baseDate.year, baseDate.month, baseDate.day),
      month,
    );
  }

  static DateTime _addMonthsSafe(DateTime d, int monthsToAdd) {
    final int newMonth0 = (d.month - 1) + monthsToAdd;
    final int newYear = d.year + (newMonth0 ~/ 12);
    final int newMonth = (newMonth0 % 12) + 1;

    final int lastDay = _daysInMonth(newYear, newMonth);
    final int newDay = (d.day <= lastDay) ? d.day : lastDay;

    return DateTime(newYear, newMonth, newDay);
  }

  static int _daysInMonth(int year, int month) {
    // month+1, day 0 => verilen ayın son günü
    return DateTime(year, month + 1, 0).day;
  }
}
