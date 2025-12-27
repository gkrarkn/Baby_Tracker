// lib/pages/sleep_page.dart
import 'package:flutter/material.dart';
import '../widgets/page_appbar_title.dart';

import 'package:baby_tracker/core/app_globals.dart';
import 'package:baby_tracker/sleep/sleep_controller.dart';
import 'package:baby_tracker/sleep/sleep_entry.dart';
import 'package:baby_tracker/sleep/sleep_formatters.dart';
import 'package:baby_tracker/sleep/widgets/sleep_timer_card.dart';
import '../core/analytics_service.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  static const double _radius = 18;

  late final SleepController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SleepController()..load();

    // analytics
    AnalyticsService.instance.log('screen_view', params: {'screen': 'sleep'});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // -----------------------------
  // Confirm dialogs
  // -----------------------------
  Future<void> _confirmDeleteEntry(SleepEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Silinsin mi?'),
        content: const Text('Bu uyku kaydı kalıcı olarak silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true) await _controller.deleteEntryById(entry.id);
  }

  Future<void> _confirmClearAll() async {
    if (_controller.entries.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm kayıtlar silinsin mi?'),
        content: const Text('Tüm uyku geçmişi kalıcı olarak silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true) await _controller.clearAll();
  }

  // -----------------------------
  // Weekly Sheet (fixed overflow)
  // -----------------------------
  void _openWeeklySummarySheet() {
    if (_controller.isLoading) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 16 + MediaQuery.of(context).padding.bottom,
              ),
              child: _WeeklySummarySheet(controller: _controller),
            ),
          ),
        );
      },
    );
  }

  // -----------------------------
  // UI
  // -----------------------------
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
                title: const SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: PageAppBarTitle(
                      title: 'Uyku',
                      icon: Icons.bedtime_rounded,
                    ),
                  ),
                ),
                backgroundColor: mainColor,
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.insights_outlined),
                    onPressed: _openWeeklySummarySheet,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _confirmClearAll,
                    tooltip: 'Tümünü sil',
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
                child: _controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          _todaySummaryModern(mainColor),
                          const SizedBox(height: 14),
                          SleepTimerCard(
                            controller: _controller,
                            mainColor: mainColor,
                            onToggleSleep: () async {
                              // SnackBar mantığını istersen burada tutabilirsin.
                              // (toggle/haptic vb. SleepTimerCard içinde.)
                            },
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Geçmiş Uykular',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_controller.entries.isEmpty)
                            Text(
                              'Henüz kayıt yok.',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w700,
                                color: cs.onSurfaceVariant,
                              ),
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

  Widget _todaySummaryModern(Color mainColor) {
    final cs = Theme.of(context).colorScheme;

    final todayTotal = _controller.todayTotalSleep();
    final last = _controller.lastSleep();
    final avg7 = _avgLast7Days();

    return _surfaceCard(
      context,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
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
              child: Icon(Icons.bedtime_rounded, color: mainColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Bugün',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: mainColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: mainColor.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Text(
                          'Özet',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: mainColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Toplam: ${SleepFormatters.durationHM(todayTotal)}',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _miniMetric(
                          label: 'Son uyku',
                          value: last == null
                              ? '-'
                              : SleepFormatters.durationHM(last.duration),
                          icon: Icons.history_rounded,
                          accent: mainColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _miniMetric(
                          label: '7g ort.',
                          value: SleepFormatters.durationHM(avg7),
                          icon: Icons.show_chart_rounded,
                          accent: mainColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.auto_awesome, color: mainColor.withValues(alpha: 0.55)),
          ],
        ),
      ),
    );
  }

  Widget _miniMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Duration _avgLast7Days() {
    final map = _controller.last7DaysTotals();
    if (map.isEmpty) return Duration.zero;

    var sum = Duration.zero;
    for (final d in map.values) {
      sum += d;
    }
    return Duration(seconds: (sum.inSeconds / map.length).round());
  }

  Widget _historyTile(SleepEntry e) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _surfaceCard(
        context,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Icon(Icons.bedtime_rounded, color: cs.primary),
          ),
          title: Text(
            'Uyku: ${SleepFormatters.durationHM(e.duration)}',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            '${SleepFormatters.dateTime(e.start)} → ${SleepFormatters.time(e.end)}',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDeleteEntry(e),
          ),
        ),
      ),
    );
  }

  static Widget _surfaceCard(BuildContext context, {required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ============================================================================
// Weekly Summary Sheet Widget
// ============================================================================

class _WeeklySummarySheet extends StatelessWidget {
  final SleepController controller;
  const _WeeklySummarySheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mainColor = appThemeColor.value;

    final last7 = controller.last7DaysTotals(); // Map<DateTime, Duration>
    final items = last7.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)); // oldest -> newest

    Duration total = Duration.zero;
    for (final e in items) {
      total += e.value;
    }
    final avg = items.isEmpty
        ? Duration.zero
        : Duration(seconds: (total.inSeconds / items.length).round());

    // Best day
    MapEntry<DateTime, Duration>? best;
    for (final e in items) {
      if (best == null || e.value > best.value) best = e;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            color: cs.outlineVariant.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Haftalık Özet (7 Gün)',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ✅ Overflow fix burada
        _distributionCard(context, mainColor, items),

        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                context,
                icon: Icons.article_outlined,
                title: 'Toplam',
                value: SleepFormatters.durationHM(total),
                accent: mainColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                context,
                icon: Icons.show_chart_rounded,
                title: 'Ortalama',
                value: SleepFormatters.durationHM(avg),
                accent: mainColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _metricCardWide(
          context,
          icon: Icons.emoji_events_outlined,
          title: 'En iyi gün',
          value: best == null
              ? '-'
              : '${SleepFormatters.dateTime(best.key).split(" - ").first} • ${SleepFormatters.durationHM(best.value)}',
          accent: mainColor,
        ),
      ],
    );
  }

  Widget _distributionCard(
    BuildContext context,
    Color mainColor,
    List<MapEntry<DateTime, Duration>> items,
  ) {
    final cs = Theme.of(context).colorScheme;

    // max
    var maxSec = 1;
    for (final e in items) {
      if (e.value.inSeconds > maxSec) maxSec = e.value.inSeconds;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Uyku dağılımı',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                'son 7 gün',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ✅ Kritik: sabit yükseklik + içerde Expanded
          SizedBox(
            height: 118, // overflow fix
            child: Column(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final e in items)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: _bar(
                                mainColor: mainColor,
                                cs: cs,
                                ratio: e.value.inSeconds / maxSec,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _dayLabels(items),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar({
    required Color mainColor,
    required ColorScheme cs,
    required double ratio,
  }) {
    final r = ratio.clamp(0.0, 1.0);
    final h = 60.0 * r + 10.0; // min height

    return Container(
      height: h,
      decoration: BoxDecoration(
        color: mainColor.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _dayLabels(List<MapEntry<DateTime, Duration>> items) {
    // Gün kısaltmaları (TR)
    String dayShortTR(DateTime d) {
      switch (d.weekday) {
        case DateTime.monday:
          return 'Pzt';
        case DateTime.tuesday:
          return 'Sal';
        case DateTime.wednesday:
          return 'Çar';
        case DateTime.thursday:
          return 'Per';
        case DateTime.friday:
          return 'Cum';
        case DateTime.saturday:
          return 'Cmt';
        case DateTime.sunday:
          return 'Paz';
        default:
          return '';
      }
    }

    return Row(
      children: [
        for (final e in items)
          Expanded(
            child: Text(
              dayShortTR(e.key),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // ✅ taşmayı bitirir
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color accent,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCardWide(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color accent,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
