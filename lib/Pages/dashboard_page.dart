// lib/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_globals.dart';
import '../theme/theme_controller.dart';

import 'settings_page.dart';
import 'sleep_page.dart';
import 'feeding_page.dart';
import 'vaccine_page.dart';
import '../growth/growth_page.dart';
import 'lullaby_page.dart';
import '../notes/notes_page.dart';

class DashboardPage extends StatefulWidget {
  final ThemeController themeController;
  const DashboardPage({super.key, required this.themeController});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // ---- UI constants ----
  static const double _pageHPadding = 16;
  static const double _pageVPadding = 16;
  static const double _gridSpacing = 12;
  static const double _cardRadius = 18;

  // TODO: Prod’a çıkarken kendi adUnitId’n ile değiştir.
  static const String _adUnitIdIosTest =
      'ca-app-pub-3940256099942544/2934735716';

  BannerAd? _bannerAd;
  bool _isBannerReady = false;

  // İleride onboarding ile alabilirsin. Şimdilik placeholder.
  static const String _userName = 'Göker';

  @override
  void initState() {
    super.initState();
    _initBanner();
  }

  void _initBanner() {
    final ad = BannerAd(
      size: AdSize.banner,
      adUnitId: _adUnitIdIosTest,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() => _isBannerReady = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _isBannerReady = false;
            _bannerAd = null;
          });
          debugPrint('Banner error: $error');
        },
      ),
    );

    _bannerAd = ad;
    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // appThemeColor ValueNotifier: renk değişince dashboard da anlık güncellensin
    return ValueListenableBuilder<Color>(
      valueListenable: appThemeColor,
      builder: (context, mainColor, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: mainColor,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
            title: _appBarTitlePill(mainColor),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SettingsPage(themeController: widget.themeController),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [mainColor.withValues(alpha: 0.10), cs.surface],
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _pageHPadding,
                      _pageVPadding,
                      _pageHPadding,
                      12,
                    ),
                    child: Column(
                      children: [
                        _welcomeCard(context, mainColor),
                        const SizedBox(height: 16),
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: _gridSpacing,
                            mainAxisSpacing: _gridSpacing,
                            childAspectRatio: 1.05,
                            children: [
                              _menuCard(
                                context,
                                icon: Icons.bedtime,
                                title: 'Uyku',
                                accent: mainColor,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SleepPage(),
                                  ),
                                ),
                              ),
                              _menuCard(
                                context,
                                icon: Icons.restaurant,
                                title: 'Beslenme',
                                accent: Colors.orange,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const FeedingPage(),
                                  ),
                                ),
                              ),
                              _menuCard(
                                context,
                                icon: Icons.medical_services,
                                title: 'Aşı & İlaç',
                                accent: Colors.red,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const VaccinePage(),
                                  ),
                                ),
                              ),
                              _menuCard(
                                context,
                                icon: Icons.show_chart,
                                title: 'Gelişim',
                                accent: Colors.teal,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const GrowthPage(),
                                  ),
                                ),
                              ),
                              _menuCard(
                                context,
                                icon: Icons.music_note,
                                title: 'Ninniler',
                                accent: Colors.purpleAccent,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LullabyPage(),
                                  ),
                                ),
                              ),
                              _menuCard(
                                context,
                                icon: Icons.note_alt,
                                title: 'Notlar',
                                accent: const Color(0xFF6D8A8F),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotesPage(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Banner: sadece hazırsa çiz
                if (_isBannerReady && _bannerAd != null)
                  SafeArea(
                    top: false,
                    child: SizedBox(
                      height: _bannerAd!.size.height.toDouble(),
                      width: double.infinity,
                      child: AdWidget(ad: _bannerAd!),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------
  // AppBar Title (Pill)
  // -------------------------
  Widget _appBarTitlePill(Color mainColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.26),
            Colors.white.withValues(alpha: 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        'Bebek Takip',
        style: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w700, // w800 -> w700
          letterSpacing: 0.0, // 0.15 -> 0
          height: 1.12, // biraz daha “soft”
          color: Colors.white,
        ),
      ),
    );
  }

  // -------------------------
  // Welcome Card
  // -------------------------
  Widget _welcomeCard(BuildContext context, Color mainColor) {
    final cs = Theme.of(context).colorScheme;

    final greeting = _greetingByTime();
    final subtitle = 'Miniğin bugün nasıl?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            mainColor.withValues(alpha: 0.18),
            cs.surface.withValues(alpha: 0.98),
          ],
        ),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sol ikon kutusu (soft)
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  mainColor.withValues(alpha: 0.22),
                  mainColor.withValues(alpha: 0.10),
                ],
              ),
            ),
            child: Icon(Icons.child_care, color: mainColor, size: 30),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting $_userName',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _miniChip(
                      context,
                      icon: Icons.add,
                      label: 'Hızlı kayıt',
                      mainColor: mainColor,
                      onTap: () {
                        _showComingSoonSnack(context);
                      },
                    ),
                    _miniChip(
                      context,
                      icon: Icons.insights_outlined,
                      label: 'Özet',
                      mainColor: mainColor,
                      onTap: () {
                        _showComingSoonSnack(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          Icon(Icons.auto_awesome, color: mainColor.withValues(alpha: 0.55)),
        ],
      ),
    );
  }

  String _greetingByTime() {
    final hour = DateTime.now().hour;

    // 05:00–10:59
    if (hour >= 5 && hour < 11) return 'Günaydın';
    // 11:00–17:59
    if (hour >= 11 && hour < 18) return 'Merhaba';
    // 18:00–22:59
    if (hour >= 18 && hour < 23) return 'İyi akşamlar';
    // 23:00–04:59
    return 'İyi geceler';
  }

  void _showComingSoonSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bu özellik yakında.',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // -------------------------
  // Mini Chip
  // -------------------------
  Widget _miniChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color mainColor,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: mainColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12.8,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // Menu Card
  // -------------------------
  Widget _menuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(_cardRadius),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_cardRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.surface.withValues(alpha: 0.98),
              accent.withValues(alpha: 0.06),
            ],
          ),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // İkonu daire içine aldık
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
              ),
              child: Icon(icon, size: 30, color: accent),
            ),
            const SizedBox(height: 12),

            // Grid yazıları: 16px + w700
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
