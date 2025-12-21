// lib/sleep/sleep_formatters.dart
import 'package:flutter/material.dart';

class SleepFormatters {
  static String _two(int n) => n.toString().padLeft(2, '0');

  static String timer(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${_two(h)}:${_two(m)}:${_two(s)}';
  }

  static String durationHM(Duration d) {
    final totalMin = d.inMinutes;
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    if (h <= 0) return '${m}dk';
    if (m == 0) return '${h}s';
    return '${h}s ${m}dk';
  }

  static String time(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  static String dateTime(DateTime d) {
    // 18.12.2025 - 15:22
    return '${_two(d.day)}.${_two(d.month)}.${d.year} - ${time(d)}';
  }

  static String timeOfDay(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';
}
