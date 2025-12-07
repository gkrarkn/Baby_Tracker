// lib/core/app_globals.dart
import 'package:flutter/material.dart';

ValueNotifier<Color> appThemeColor = ValueNotifier<Color>(Colors.deepPurple);

String getCurrentDateTime() {
  final now = DateTime.now();
  final date = "${now.day}.${now.month}.${now.year}";
  final time =
      "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  return "$date - $time";
}
