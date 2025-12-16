import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/app_globals.dart';
import '../theme/theme_controller.dart';

import 'settings_page.dart';
import 'sleep_page.dart';
import 'feeding_page.dart';
import 'vaccine_page.dart';
import 'growth_page.dart';
import 'lullaby_page.dart';
import 'notes_page.dart';

// --- ANA MENÜ (DASHBOARD) ---
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
    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: 'ca-app-pub-3940256099942544/2934735716', // iOS TEST
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerReady = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner error: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = appThemeColor.value;

    final bannerHeight = (_isBannerReady && _bannerAd != null)
        ? _bannerAd!.size.height.toDouble()
        : 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Bebek Takip 🐣'),
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

      // ✅ Grid yukarıda Expanded, banner altta ayrı alan
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: mainColor.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: mainColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.child_care,
                            size: 40,
                            color: mainColor,
                          ),
                        ),
                        const SizedBox(width: 15),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hoşgeldin!",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Miniğin bugün nasıl?",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      children: [
                        _buildMenuCard(
                          context,
                          Icons.bedtime,
                          "Uyku",
                          mainColor,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SleepPage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          context,
                          Icons.restaurant,
                          "Beslenme",
                          Colors.orange,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FeedingPage(),
                            ),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          Icons.medical_services,
                          "Aşı & İlaç",
                          Colors.red,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VaccinePage(),
                            ),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          Icons.show_chart,
                          "Gelişim",
                          Colors.teal,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GrowthPage(),
                            ),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          Icons.music_note,
                          "Ninniler",
                          Colors.purpleAccent,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LullabyPage(),
                            ),
                          ),
                        ),

                        _buildMenuCard(
                          context,
                          Icons.note_alt,
                          "Notlar",
                          const Color(0xFF6D8A8F),
                          () => Navigator.push(
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

          // ✅ Banner her zaman en altta, grid'i "kesmez"
          if (bannerHeight > 0)
            SafeArea(
              top: false,
              child: SizedBox(
                height: bannerHeight,
                width: double.infinity,
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 2,
              blurRadius: 5,
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
