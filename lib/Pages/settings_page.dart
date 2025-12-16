import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';
import '../core/app_globals.dart'; // appThemeColor

class SettingsPage extends StatelessWidget {
  final ThemeController themeController;
  const SettingsPage({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    final mainColor = appThemeColor.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle('Görünüm'),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Sistem'),
                  value: ThemeMode.system,
                  groupValue: themeController.mode,
                  onChanged: (v) {
                    if (v == null) return;
                    themeController.setThemeMode(v);
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Açık'),
                  value: ThemeMode.light,
                  groupValue: themeController.mode,
                  onChanged: (v) {
                    if (v == null) return;
                    themeController.setThemeMode(v);
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Koyu'),
                  value: ThemeMode.dark,
                  groupValue: themeController.mode,
                  onChanged: (v) {
                    if (v == null) return;
                    themeController.setThemeMode(v);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const _SectionTitle('Bebeğin Cinsiyeti / Tema Rengi'),
          ValueListenableBuilder<Color>(
            valueListenable: appThemeColor,
            builder: (context, color, _) {
              return Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.female, color: Colors.pink.shade200),
                      title: const Text('Kız Bebek'),
                      trailing: _check(color == Colors.pink.shade200),
                      onTap: () => themeController.setGender('girl'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.male, color: Colors.blue),
                      title: const Text('Erkek Bebek'),
                      trailing: _check(color == Colors.blue),
                      onTap: () => themeController.setGender('boy'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.palette,
                        color: Colors.deepPurple,
                      ),
                      title: const Text('Varsayılan (Mor)'),
                      trailing: _check(color == Colors.deepPurple),
                      onTap: () => themeController.setGender('none'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _check(bool on) => on
      ? const Icon(Icons.check, color: Colors.green)
      : const SizedBox.shrink();
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
