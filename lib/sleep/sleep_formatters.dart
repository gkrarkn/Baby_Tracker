// lib/sleep/sleep_formatters.dart
import 'package:flutter/material.dart';

class SleepFormatters {
  static String _two(int n) => n.toString().padLeft(2, '0');

  /// 00:00:00 (timer)
  static String timer(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${_two(h)}:${_two(m)}:${_two(s)}';
  }

  /// 0dk / 2s / 2s 15dk
  static String durationHM(Duration d) {
    final totalMin = d.inMinutes;
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    if (h <= 0) return '${m}dk';
    if (m == 0) return '${h}s';
    return '${h}s ${m}dk';
  }

  /// 15:22
  static String time(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  /// 18.12.2025 - 15:22
  static String dateTime(DateTime d) {
    return '${_two(d.day)}.${_two(d.month)}.${d.year} - ${time(d)}';
  }

  /// 18.12
  static String dateDM(DateTime d) => '${_two(d.day)}.${_two(d.month)}';

  /// Pzt / Sal / Çar / Per / Cum / Cmt / Paz
  static String dayShortTR(DateTime d) {
    switch (d.weekday) {
      case DateTime.monday:
        return 'Pzt';
      case DateTime.tuesday:
        return 'Sal';
      case DateTime.wednesday:
        return 'Çar';
      case DateTime.thursday:
        return 'Per';
      case DateTime.friday:
        return 'Cum';
      case DateTime.saturday:
        return 'Cmt';
      case DateTime.sunday:
        return 'Paz';
      default:
        return '';
    }
  }

  /// 15:22
  static String timeOfDay(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';
}
