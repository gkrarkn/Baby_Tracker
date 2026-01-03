// lib/pages/sleep_page.dart
import 'package:flutter/material.dart';

import 'package:baby_tracker/core/app_globals.dart';
import 'package:baby_tracker/core/analytics_service.dart';
import 'package:baby_tracker/sleep/widgets/sleep_today_summary_card.dart';

import 'package:baby_tracker/sleep/sleep_controller.dart';
import 'package:baby_tracker/sleep/sleep_entry.dart';
import 'package:baby_tracker/sleep/sleep_formatters.dart';

import 'package:baby_tracker/sleep/widgets/sleep_timer_card.dart';
import 'package:baby_tracker/sleep/widgets/sleep_window_premium_card.dart';

import '../widgets/page_appbar_title.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  static const double _radius = 18;
  late final SleepController _controller;

  bool _isPremium = false; // 👈 şimdilik manuel (Recipes ile aynı)

  @override
  void initState() {
    super.initState();
    _controller = SleepController(
      ageInMonths: () => 14, // şimdilik sabit, birazdan bağlarız
    )..load();

    AnalyticsService.instance.log('screen_view', params: {'screen': 'sleep'});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ValueListenableBuilder<Color>(
      valueListenable: appThemeColor,
      builder: (context, mainColor, _) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Scaffold(
              appBar: AppBar(
                centerTitle: true,
                title: const PageAppBarTitle(
                  title: 'Uyku',
                  icon: Icons.bedtime_rounded,
                ),
                backgroundColor: mainColor,
                foregroundColor: Colors.white,
              ),
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [mainColor.withValues(alpha: 0.10), cs.surface],
                  ),
                ),
                child: _controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          SleepTodaySummaryCard(
                            controller: _controller,
                            mainColor: mainColor,
                          ),
                          const SizedBox(height: 14),

                          // Sleep Timer
                          SleepTimerCard(
                            controller: _controller,
                            mainColor: mainColor,
                            onToggleSleep: _controller.toggleSleep,
                          ),

                          // Sleep Window (Premium)
                          const SizedBox(height: 12),
                          SleepWindowPremiumCard(
                            isPremium: _isPremium,
                            enabled: _controller.sleepWindowReminderEnabled,
                            windowRangeText:
                                _controller.recommendedSleepRangeText,
                            onToggle: (v) {
                              _controller.setSleepWindowReminderEnabled(v);
                            },
                            onUpgradeTap: _showPremiumSheet,
                          ),

                          const SizedBox(height: 18),

                          Text(
                            'Geçmiş Uykular',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_controller.entries.isEmpty)
                            Text(
                              'Henüz kayıt yok.',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            )
                          else
                            ..._controller.entries.map(_historyTile),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }

  // --------------------------------------------------
  // PREMIUM BOTTOM SHEET (Recipes ile AYNI)
  // --------------------------------------------------

  void _showPremiumSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Premium',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Uyku penceresi hatırlatıcısı\n'
                '• Akıllı uyku zamanları\n'
                '• Gelişmiş analizler',
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isPremium = true);
                  Navigator.pop(context);
                },
                child: const Text('Premium’a Geç'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------
  // Helpers
  // --------------------------------------------------

  Widget _historyTile(SleepEntry e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _surfaceCard(
        child: ListTile(
          title: Text(
            'Uyku: ${SleepFormatters.durationHM(e.duration)}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            '${SleepFormatters.dateTime(e.start)} → ${SleepFormatters.time(e.end)}',
          ),
        ),
      ),
    );
  }

  Widget _surfaceCard({required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }
}
