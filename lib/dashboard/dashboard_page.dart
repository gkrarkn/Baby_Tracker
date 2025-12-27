// lib/dashboard/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/analytics_service.dart';
import '../core/app_globals.dart';
import '../theme/theme_controller.dart';

import '../pages/settings_page.dart';
import '../pages/sleep_page.dart';
import '../pages/feeding_page.dart';
import '../pages/vaccine_page.dart';
import '../growth/growth_page.dart';
import '../pages/lullaby_page.dart';
import '../notes/notes_page.dart';

import 'dashboard_summary_repo.dart';
import 'dashboard_summary_sheet.dart';

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

  // Grid spacing (senin isteğine göre biraz açıldı)
  static const double _gridSpacing = 14;

  static const double _cardRadius = 18;
  static const String _userName = 'Göker';

  final DashboardSummaryRepo _repo = DashboardSummaryRepo();

  bool _isPremium = false;
  TodaySummary? _today;
  WeeklyFeedingSummary? _weeklyFeeding;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.appOpen();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final results = await Future.wait([
        _repo.getPremiumFlag(), // bool
        _repo.getTodaySummary(), // TodaySummary
        _repo.getWeeklyFeedingSummary(), // WeeklyFeedingSummary
      ]);

      if (!mounted) return;
      setState(() {
        _isPremium = results[0] as bool;
        _today = results[1] as TodaySummary;
        _weeklyFeeding = results[2] as WeeklyFeedingSummary;
      });
    } catch (_) {
      // Dashboard asla çökmesin.
      if (!mounted) return;
      setState(() {
        _isPremium = false;
        _today ??= TodaySummary.empty();
        _weeklyFeeding ??= WeeklyFeedingSummary.empty();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ValueListenableBuilder<Color>(
      valueListenable: appThemeColor,
      builder: (context, mainColor, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: mainColor,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
            title: _appBarTitlePill(),
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

                  // Grid alanı
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final availableH = constraints.maxHeight;
                        final availableW = constraints.maxWidth;

                        // Grid'e “nefes” payı (üstte çok az, altta biraz daha fazla)
                        const double gridTopPadding = 2;
                        const double gridBottomPadding = 22;

                        final usableH =
                            availableH - gridTopPadding - gridBottomPadding;

                        // 2 sütun, 3 satır
                        final tileW = (availableW - _gridSpacing) / 2;

                        // Kartları “bir tık küçült”
                        final tileH =
                            ((usableH - (_gridSpacing * 2)) / 3) * 0.95;

                        final ratio = tileW / tileH;

                        return GridView.count(
                          padding: const EdgeInsets.fromLTRB(
                            0,
                            gridTopPadding,
                            0,
                            gridBottomPadding,
                          ),
                          crossAxisCount: 2,
                          crossAxisSpacing: _gridSpacing,
                          mainAxisSpacing: _gridSpacing,
                          childAspectRatio: ratio,
                          physics: const NeverScrollableScrollPhysics(),
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
                              icon: Icons.queue_music_rounded,
                              title: 'Müzik Kutusu',
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
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // -------------------------
  // AppBar Title (Pill)
  // -------------------------
  Widget _appBarTitlePill() {
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
          fontWeight: FontWeight.w700,
          height: 1.12,
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
                const SizedBox(height: 6),
                Text(
                  'Bebeğin bugün nasıl?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 14.2,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurfaceVariant,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                _todaySummaryLine(context),
                const SizedBox(height: 10),
                _summaryChip(context),
              ],
            ),
          ),
          Icon(Icons.auto_awesome, color: mainColor.withValues(alpha: 0.55)),
        ],
      ),
    );
  }

  Widget _todaySummaryLine(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_today == null) {
      return Text(
        'Bugün: yükleniyor…',
        style: GoogleFonts.nunito(
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          color: cs.onSurfaceVariant,
        ),
      );
    }

    if (_today!.isEmpty) {
      return InkWell(
        onTap: () => _openSummarySheet(context),
        child: Text(
          'Bugün: Henüz kayıt yok',
          style: GoogleFonts.nunito(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
          ),
        ),
      );
    }

    final parts = <String>[];

    if (_today!.milkMl > 0) parts.add('🍼 ${_today!.milkMl} ml');
    if (_today!.solidCount > 0) parts.add('🍎 ${_today!.solidCount}');
    if (_today!.sleep != Duration.zero) {
      final h = _today!.sleep.inHours;
      final m = _today!.sleep.inMinutes.remainder(60);
      if (h > 0) {
        parts.add('🌙 ${h}s ${m}d');
      } else {
        parts.add('🌙 ${m}d');
      }
    }

    return InkWell(
      onTap: () => _openSummarySheet(context),
      child: Text(
        'Bugün: ${parts.join(' • ')}',
        style: GoogleFonts.nunito(
          fontSize: 13.5,
          fontWeight: FontWeight.w900,
          color: cs.onSurface,
        ),
      ),
    );
  }

  String _greetingByTime() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'Günaydın';
    if (hour >= 11 && hour < 18) return 'Merhaba';
    if (hour >= 18 && hour < 23) return 'İyi akşamlar';
    return 'İyi geceler';
  }

  // -------------------------
  // Summary Chip
  // -------------------------
  Widget _summaryChip(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _openSummarySheet(context),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        constraints: const BoxConstraints(minWidth: 110, maxWidth: 170),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.70),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 15,
              color: cs.onSurfaceVariant.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 6),
            Text(
              'Özet',
              style: GoogleFonts.nunito(
                fontSize: 12.2,
                fontWeight: FontWeight.w800,
                color: cs.onSurfaceVariant.withValues(alpha: 0.70),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: cs.onSurfaceVariant.withValues(alpha: 0.75),
            ),
          ],
        ),
      ),
    );
  }

  void _openSummarySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DashboardSummarySheet(
        today: _today ?? TodaySummary.empty(),
        weeklyFeeding: _weeklyFeeding ?? WeeklyFeedingSummary.empty(),
        isPremium: _isPremium,

        // Premium aksiyonu: detaylı trend/analiz (paywall/upgrade akışı)
        onTapUpgrade: () {
          Navigator.pop(context);
          _showPremiumInfo(context);
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  void _showPremiumInfo(BuildContext context) {
    // Şimdilik “soft gate”:
    // Detaylı haftalık trend / analiz metrikleri Premium ile açılır.
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Premium'),
        content: const Text(
          'Detaylı trend ve gelişmiş özetler Premium ile açılacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  // -------------------------
  // Menu Card (renkli/gradient)
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
