import 'package:flutter/material.dart';

import '../core/app_globals.dart'; // appThemeColor (ValueNotifier<Color>)
import '../theme/theme_controller.dart';
import 'privacy_policy_webview_page.dart';

class SettingsPage extends StatelessWidget {
  final ThemeController themeController;
  const SettingsPage({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mainColor = appThemeColor.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const _SectionTitle('Görünüm'),
          _surfaceCard(
            context,
            child: Column(
              children: [
                _themeModeTile(
                  context,
                  icon: Icons.settings_suggest,
                  title: 'Sistem',
                  subtitle: 'Cihaz ayarlarını takip eder',
                  value: ThemeMode.system,
                ),
                _divider(context),
                _themeModeTile(
                  context,
                  icon: Icons.light_mode,
                  title: 'Açık',
                  subtitle: 'Her zaman açık tema',
                  value: ThemeMode.light,
                ),
                _divider(context),
                _themeModeTile(
                  context,
                  icon: Icons.dark_mode,
                  title: 'Koyu',
                  subtitle: 'Her zaman koyu tema',
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const _SectionTitle('Bebeğin Cinsiyeti / Tema Rengi'),
          ValueListenableBuilder<Color>(
            valueListenable: appThemeColor,
            builder: (context, color, _) {
              return _surfaceCard(
                context,
                child: Column(
                  children: [
                    _genderTile(
                      context,
                      title: 'Kız Bebek',
                      icon: Icons.female,
                      iconColor: Colors.pink.shade300,
                      selected: color.value == Colors.pink.shade200.value,
                      onTap: () => themeController.setGender('girl'),
                    ),
                    _divider(context),
                    _genderTile(
                      context,
                      title: 'Erkek Bebek',
                      icon: Icons.male,
                      iconColor: Colors.blue,
                      selected: color.value == Colors.blue.value,
                      onTap: () => themeController.setGender('boy'),
                    ),
                    _divider(context),
                    _genderTile(
                      context,
                      title: 'Varsayılan',
                      icon: Icons.palette,
                      iconColor: Colors.deepPurple,
                      selected: color.value == Colors.deepPurple.value,
                      onTap: () => themeController.setGender('none'),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          const _SectionTitle('Gizlilik'),
          _surfaceCard(
            context,
            child: Column(
              children: [
                _simpleTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  iconColor: cs.primary,
                  title: 'Gizlilik Politikası',
                  subtitle: 'Politikayı uygulama içinden görüntüleyin',
                  onTap: () => _openPrivacyPolicy(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const _SectionTitle('Bilgilendirme'),
          _surfaceCard(
            context,
            child: Column(
              children: [
                _simpleTile(
                  context,
                  icon: Icons.info_outline,
                  iconColor: cs.primary,
                  title: 'Bilgilendirme',
                  subtitleWidget: _disclaimerSubtitle(context),
                  onTap: () => _showDisclaimerDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Actions ----------------

  void _openPrivacyPolicy(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();

    // GitHub Pages (çalışan link)
    const trUrl =
        'https://gkrarkn.github.io/Baby_Tracker/privacy-policy-tr.html';
    const enUrl =
        'https://gkrarkn.github.io/Baby_Tracker/privacy-policy-en.html';

    final url = (lang == 'tr') ? trUrl : enUrl;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrivacyPolicyWebViewPage(
          url: url,
          title: (lang == 'tr') ? 'Gizlilik Politikası' : 'Privacy Policy',
        ),
      ),
    );
  }

  static void _showDisclaimerDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('Bilgilendirme', style: TextStyle(color: cs.onSurface)),
        content: Text(
          'Uygulama içeriği bilgilendirme amaçlıdır; tıbbi tanı veya tedavi önerisi değildir.\n\n'
          'Bebeğinizle ilgili ilaç/uyku/beslenme gibi konularda nihai kararları çocuk doktorunuzla değerlendiriniz.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  // ---------------- UI helpers ----------------

  static Widget _disclaimerSubtitle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return RichText(
      text: TextSpan(
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        children: [
          const TextSpan(text: 'Uygulama tıbbi tavsiye yerine geçmez'),
          TextSpan(
            text: ' • Devamını oku',
            style: TextStyle(fontWeight: FontWeight.w700, color: cs.primary),
          ),
        ],
      ),
    );
  }

  Widget _themeModeTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeMode value,
  }) {
    final cs = Theme.of(context).colorScheme;

    return RadioListTile<ThemeMode>(
      value: value,
      groupValue: themeController.mode,
      onChanged: (v) {
        if (v == null) return;
        themeController.setThemeMode(v);
      },
      activeColor: cs.primary,
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
      ),
      subtitle: Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant)),
      secondary: CircleAvatar(
        backgroundColor: cs.primary.withValues(alpha: 0.12),
        child: Icon(icon, color: cs.primary),
      ),
    );
  }

  static Widget _genderTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.primary.withValues(alpha: 0.12),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
      ),
      trailing: selected
          ? const Icon(Icons.check, color: Colors.green)
          : const SizedBox.shrink(),
      onTap: onTap,
    );
  }

  static Widget _simpleTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? subtitleWidget,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.primary.withValues(alpha: 0.12),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
      ),
      subtitle:
          subtitleWidget ??
          (subtitle == null
              ? null
              : Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant))),
      trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
      onTap: onTap,
    );
  }

  static Widget _surfaceCard(BuildContext context, {required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  static Widget _divider(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      thickness: 1,
      color: cs.outlineVariant.withValues(alpha: 0.30),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: cs.onSurface.withValues(alpha: 0.90),
        ),
      ),
    );
  }
}
