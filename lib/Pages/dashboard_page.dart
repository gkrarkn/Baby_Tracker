import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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
  BannerAd? _bannerAd;
  bool _isBannerReady = false;

  @override
  void initState() {
    super.initState();
    _initBanner();
  }

  void _initBanner() {
    final ad = BannerAd(
      size: AdSize.banner,
      adUnitId: 'ca-app-pub-3940256099942544/2934735716', // iOS TEST
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
    final Color mainColor = appThemeColor.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bebek Takip'),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
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
            colors: [
              mainColor.withValues(alpha: 0.10),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  children: [
                    _welcomeCard(mainColor),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.05,
                        children: [
                          _menuCard(
                            context,
                            icon: Icons.bedtime,
                            title: 'Uyku',
                            color: mainColor,
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
                            color: Colors.orange,
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
                            color: Colors.red,
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
                            color: Colors.teal,
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
                            color: Colors.purpleAccent,
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
                            color: const Color(0xFF6D8A8F),
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

            // Banner: sadece hazırsa çiz (UI'yi kilitleme riskini azaltır)
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
  }

  Widget _welcomeCard(Color mainColor) {
    final cs = Theme.of(context).colorScheme;

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
          // Avatar / icon
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: mainColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.child_care, color: mainColor, size: 30),
          ),
          const SizedBox(width: 14),

          // Metin + mini aksiyonlar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoş geldin',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Miniğin bugün nasıl?',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _miniChip(
                      icon: Icons.add,
                      label: 'Hızlı kayıt',
                      mainColor: mainColor,
                      onTap: () {
                        // İstersen burayı bottom sheet / quick actions’a bağlarız
                      },
                    ),
                    _miniChip(
                      icon: Icons.insights_outlined,
                      label: 'Özet',
                      mainColor: mainColor,
                      onTap: () {
                        // İstersen “bugün kaç kayıt” gibi bir özet sayfası
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sağ ikon (opsiyonel)
          Icon(Icons.auto_awesome, color: mainColor.withValues(alpha: 0.65)),
        ],
      ),
    );
  }

  Widget _miniChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.90),
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
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
