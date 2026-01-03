// lib/sleep/sleep_window_calculator.dart

import 'wake_window_table.dart';

class SleepWindowCalculator {
  static DateTime calculateTargetSleep({
    required DateTime lastWakeTime,
    required int ageInMonths,
  }) {
    final minutes = WakeWindowTable.minutesForAge(ageInMonths);
    return lastWakeTime.add(Duration(minutes: minutes));
  }

  /// Örn: 19:10 – 19:40
  static String formatRecommendedRange({
    required DateTime lastWakeTime,
    required int ageInMonths,
    int windowMinutes = 15,
  }) {
    final target = calculateTargetSleep(
      lastWakeTime: lastWakeTime,
      ageInMonths: ageInMonths,
    );

    final start = target.subtract(Duration(minutes: windowMinutes));
    final end = target.add(Duration(minutes: windowMinutes));

    String f(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return '${f(start)}–${f(end)}';
  }
}
