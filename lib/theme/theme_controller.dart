import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const _kThemeMode = 'themeMode'; // system/light/dark
  static const _kGender = 'gender'; // girl/boy/none

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  final ValueNotifier<Color> seedColor; // appThemeColor gönderilecek

  ThemeController({required this.seedColor});

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // ThemeMode
    final modeStr = prefs.getString(_kThemeMode) ?? 'system';
    _mode = switch (modeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    // Gender -> seedColor
    final gender = prefs.getString(_kGender);
    seedColor.value = _colorForGender(gender);

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final str = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await prefs.setString(_kThemeMode, str);
  }

  Future<void> setGender(String genderKey) async {
    seedColor.value = _colorForGender(genderKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGender, genderKey);
  }

  Color _colorForGender(String? key) {
    if (key == 'girl') return Colors.pink.shade200;
    if (key == 'boy') return Colors.blue;
    return Colors.deepPurple;
  }
}
