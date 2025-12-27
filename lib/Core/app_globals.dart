// lib/core/app_globals.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------
// SharedPreferences Keys
// ---------------------------

const String kAnonDataKey = 'anonDataContributionEnabled';

const String kBabyBirthDateKey = 'babyBirthDateIso';
const String kBabyDueDateKey = 'babyDueDateIso';

// NEW (canonical key)
const String kBabyGenderKey = 'babyGender'; // 'none' | 'boy' | 'girl'

// LEGACY (senin mevcut SettingsPage’te kullandığın)
const String kLegacyGenderKey = 'gender';

// ---------------------------
// App-wide Notifiers
// ---------------------------

// Analytics opt-in
final ValueNotifier<bool> anonDataOptIn = ValueNotifier<bool>(true);

// Theme seed color
final ValueNotifier<Color> appThemeColor = ValueNotifier<Color>(
  Colors.deepPurple,
);

// Baby dates (used for leaps / corrected age)
final ValueNotifier<DateTime?> babyBirthDate = ValueNotifier<DateTime?>(null);
final ValueNotifier<DateTime?> babyDueDate = ValueNotifier<DateTime?>(null);

// Baby gender (WHO vs)
final ValueNotifier<String> babyGender = ValueNotifier<String>('none');

// ---------------------------
// Globals init (hydrate)
// ---------------------------

Future<void> loadAppGlobals() async {
  final prefs = await SharedPreferences.getInstance();

  // Analytics opt-in
  anonDataOptIn.value = prefs.getBool(kAnonDataKey) ?? true;

  // Baby dates (ISO)
  babyBirthDate.value = _readIsoDate(prefs.getString(kBabyBirthDateKey));
  babyDueDate.value = _readIsoDate(prefs.getString(kBabyDueDateKey));

  // Gender (canonical)
  String? g = prefs.getString(kBabyGenderKey);

  // Migration: legacy 'gender' -> 'babyGender'
  if (g == null) {
    final legacy = prefs.getString(kLegacyGenderKey);
    if (legacy != null && _isValidGender(legacy)) {
      g = legacy;
      await prefs.setString(kBabyGenderKey, legacy);
      // legacy key’i silmek zorunlu değil; istersen kaldırabilirsin:
      // await prefs.remove(kLegacyGenderKey);
    }
  }

  babyGender.value = _isValidGender(g) ? g! : 'none';
}

// ---------------------------
// Persist helpers (write)
// ---------------------------

Future<void> setAnonDataOptIn(bool value) async {
  anonDataOptIn.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kAnonDataKey, value);
}

Future<void> setBabyBirthDate(DateTime? value) async {
  babyBirthDate.value = value;
  final prefs = await SharedPreferences.getInstance();
  if (value == null) {
    await prefs.remove(kBabyBirthDateKey);
  } else {
    await prefs.setString(kBabyBirthDateKey, value.toIso8601String());
  }
}

Future<void> setBabyDueDate(DateTime? value) async {
  babyDueDate.value = value;
  final prefs = await SharedPreferences.getInstance();
  if (value == null) {
    await prefs.remove(kBabyDueDateKey);
  } else {
    await prefs.setString(kBabyDueDateKey, value.toIso8601String());
  }
}

Future<void> setBabyGender(String value) async {
  final v = _isValidGender(value) ? value : 'none';
  babyGender.value = v;

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(kBabyGenderKey, v);

  // legacy ile de uyumlu tut (istersen kaldırabilirsin)
  await prefs.setString(kLegacyGenderKey, v);
}

// ---------------------------
// Helpers
// ---------------------------

DateTime? _readIsoDate(String? iso) {
  if (iso == null || iso.trim().isEmpty) return null;
  return DateTime.tryParse(iso);
}

bool _isValidGender(String? g) => g == 'none' || g == 'boy' || g == 'girl';

String formatDateTr(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}.${d.year}';
}

// Used in VaccinePage logs, etc.
String getCurrentDateTime() {
  final now = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(now.day)}.${two(now.month)}.${now.year} - ${two(now.hour)}:${two(now.minute)}';
}
