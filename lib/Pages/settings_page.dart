import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'privacy_policy_webview_page.dart';

import '../core/app_globals.dart';
import '../theme/theme_controller.dart';

class SettingsPage extends StatefulWidget {
  final ThemeController themeController;
  const SettingsPage({super.key, required this.themeController});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _gender = 'none'; // none | boy | girl

  @override
  void initState() {
    super.initState();
    _loadGender();
  }

  Future<void> _loadGender() async {
    final prefs = await SharedPreferences.getInstance();
    final g = prefs.getString('gender') ?? 'none';
    if (!mounted) return;
    setState(() => _gender = g);
  }

  Future<void> _setGender(String value) async {
    setState(() => _gender = value);
    await widget.themeController.setGender(value);
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: babyBirthDate.value ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );
    if (picked == null) return;
    await setBabyBirthDate(picked);
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: babyDueDate.value ?? babyBirthDate.value ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      locale: const Locale('tr', 'TR'),
    );
    if (picked == null) return;
    await setBabyDueDate(picked);
  }

  void _showDueDateInfo() {
    _showInfoDialog(
      title: 'Beklenen Doğum Tarihi (opsiyonel)',
      content:
          'Erken doğan bebeklerde gelişim dönemleri doğum tarihine göre sapabilir. '
          'Beklenen doğum tarihini girerseniz atak haftası hesaplamaları '
          '“düzeltilmiş yaş” mantığıyla yapılır.',
    );
  }

  void _showMedicalDisclaimer() {
    _showInfoDialog(
      title: 'Bilgilendirme',
      content:
          'Bu uygulamada yer alan bilgiler yalnızca genel bilgilendirme '
          'amaçlıdır ve tıbbi tavsiye niteliği taşımaz.\n\n'
          'Tanı ve tedavi için mutlaka doktorunuza danışınız.',
    );
  }

  void _showInfoDialog({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: appThemeColor,
      builder: (_, mainColor, __) {
        return Scaffold(
          appBar: AppBar(title: const Text('Ayarlar')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _section('Profil'),
              _genderCard(mainColor),

              _section('Bebek Bilgileri'),
              _datesCard(mainColor),

              _section('Görünüm'),
              _themeModeCard(mainColor),

              _section('Gizlilik'),
              _privacySwitch(mainColor),
              const SizedBox(height: 8),
              _infoTile(
                icon: Icons.info_outline_rounded,
                text: 'Bilgilendirme',
                onTap: _showMedicalDisclaimer,
              ),
              const SizedBox(height: 8),
              _infoTile(
                icon: Icons.description_outlined,
                text: 'Gizlilik Politikası',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyWebViewPage(
                        title: 'Gizlilik Politikası',
                        assetPath: 'assets/privacy-policy-tr.html',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- UI PARTS ----------

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: Text(
      t,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
  );

  Widget _genderCard(Color c) => _card(
    child: Wrap(
      spacing: 10,
      children: [
        _chip('Belirtilmedi', 'none', c),
        _chip('Erkek', 'boy', c),
        _chip('Kız', 'girl', c),
      ],
    ),
  );

  Widget _chip(String t, String v, Color c) => ChoiceChip(
    label: Text(t),
    selected: _gender == v,
    onSelected: (_) => _setGender(v),
    selectedColor: c.withValues(alpha: 0.15),
  );

  Widget _datesCard(Color c) => _card(
    child: Column(
      children: [
        _dateTile(
          icon: Icons.cake_rounded,
          title: 'Doğum tarihi',
          date: babyBirthDate,
          onTap: _pickBirthDate,
        ),
        const Divider(),
        _dateTile(
          icon: Icons.event_available_rounded,
          title: 'Beklenen doğum tarihi',
          date: babyDueDate,
          onTap: _pickDueDate,
          infoTap: _showDueDateInfo,
        ),
      ],
    ),
  );

  Widget _dateTile({
    required IconData icon,
    required String title,
    required ValueNotifier<DateTime?> date,
    required VoidCallback onTap,
    VoidCallback? infoTap,
  }) => ValueListenableBuilder<DateTime?>(
    valueListenable: date,
    builder: (_, d, __) {
      return ListTile(
        leading: Icon(icon),
        title: Row(
          children: [
            Text(title),
            if (infoTap != null) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: infoTap,
                child: const Icon(Icons.info_outline_rounded, size: 18),
              ),
            ],
          ],
        ),
        subtitle: Text(d == null ? 'Opsiyonel' : formatDateTr(d)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      );
    },
  );

  Widget _themeModeCard(Color c) => _card(
    child: Wrap(
      spacing: 10,
      children: ThemeMode.values.map((m) {
        final label = switch (m) {
          ThemeMode.system => 'Sistem',
          ThemeMode.light => 'Açık',
          ThemeMode.dark => 'Koyu',
        };
        return ChoiceChip(
          label: Text(label),
          selected: widget.themeController.mode == m,
          onSelected: (_) => widget.themeController.setThemeMode(m),
          selectedColor: c.withValues(alpha: 0.15),
        );
      }).toList(),
    ),
  );

  Widget _privacySwitch(Color c) => _card(
    child: ValueListenableBuilder<bool>(
      valueListenable: anonDataOptIn,
      builder: (_, v, __) {
        return SwitchListTile(
          secondary: Icon(Icons.privacy_tip_rounded, color: c),
          title: const Text('Anonim kullanım verisi'),
          subtitle: const Text(
            'Uygulamayı iyileştirmek için anonim veri paylaşımı.',
          ),
          value: v,
          onChanged: setAnonDataOptIn,
        );
      },
    ),
  );

  Widget _infoTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) => _card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(text),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );

  Widget _card({required Widget child}) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(padding: const EdgeInsets.all(12), child: child),
  );
}
