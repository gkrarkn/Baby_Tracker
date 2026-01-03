// lib/sleep/wake_window_table.dart

class WakeWindowTable {
  static int minutesForAge(int ageInMonths) {
    if (ageInMonths <= 1) return 45;
    if (ageInMonths == 2) return 60;
    if (ageInMonths == 3) return 75;
    if (ageInMonths == 4) return 90;
    if (ageInMonths == 5) return 105;
    if (ageInMonths == 6) return 120;
    if (ageInMonths <= 8) return 135;
    if (ageInMonths <= 10) return 150;
    return 165; // 11–12+
  }
}
