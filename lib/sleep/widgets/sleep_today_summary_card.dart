// lib/sleep/widgets/sleep_today_summary_card.dart
import 'package:flutter/material.dart';

import '../sleep_controller.dart';
import '../sleep_formatters.dart';

class SleepTodaySummaryCard extends StatelessWidget {
  final SleepController controller;
  final Color mainColor;

  /// Napper/Apple Health hissi için: günlük hedef (dakika).
  /// Şimdilik sabit; sonra Settings’ten alırız.
  final int targetMinutes;

  const SleepTodaySummaryCard({
    super.key,
    required this.controller,
    required this.mainColor,
    this.targetMinutes = 12 * 60, // 12 saat
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final todayTotal = controller.todayTotalSleep(); // Duration
    final last = controller
        .lastSleep(); // SleepEntry? (duration/start bekleniyor)

    final target = Duration(minutes: targetMinutes);
    final progress = _progress01(todayTotal, target);

    final remaining = (target - todayTotal);
    final remainingText = remaining.isNegative
        ? 'Hedef aşıldı'
        : 'Kalan: ${SleepFormatters.durationHM(remaining)}';

    final lastDurationText = last == null
        ? '-'
        : SleepFormatters.durationHM(last.duration);

    final lastTimeText = last == null ? '-' : _timeHM(last.start);

    return _surfaceCard(
      context,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Bugün',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.nightlight_round,
                  size: 18,
                  color: todayTotal.inMinutes == 0
                      ? cs.onSurfaceVariant.withValues(alpha: 0.35)
                      : mainColor.withValues(alpha: 0.75),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Big number row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  SleepFormatters.durationHM(todayTotal),
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                    fontSize: 40,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'toplam uyku',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress + microcopy
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: cs.surfaceContainerHighest.withValues(
                  alpha: 0.6,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  mainColor.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Hedef: ${SleepFormatters.durationHM(target)}',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  remainingText,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Two small tiles
            Row(
              children: [
                Expanded(
                  child: _miniTile(
                    context,
                    icon: Icons.access_time_rounded,
                    iconColor: mainColor,
                    title: 'Son uyku',
                    value: lastDurationText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _miniTile(
                    context,
                    icon: Icons.trending_up_rounded,
                    iconColor: mainColor,
                    title: 'Hedef',
                    value: SleepFormatters.durationHM(target),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Bottom line (Napper gibi kısa)
            Text(
              last == null
                  ? 'Son uyku: -'
                  : 'Son uyku: $lastDurationText • $lastTimeText',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: cs.onSurfaceVariant,
                fontSize: 13,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _progress01(Duration value, Duration target) {
    if (target.inMinutes <= 0) return 0;
    final v = value.inMinutes / target.inMinutes;
    if (v.isNaN || v.isInfinite) return 0;
    return v.clamp(0.0, 1.0);
  }

  static String _timeHM(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static Widget _miniTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: cs.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _surfaceCard(BuildContext context, {required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
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
