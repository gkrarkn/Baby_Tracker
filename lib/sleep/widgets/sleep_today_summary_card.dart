import 'package:flutter/material.dart';

import '../sleep_controller.dart';
import '../sleep_formatters.dart';

class SleepTodaySummaryCard extends StatelessWidget {
  final SleepController controller;
  final Color mainColor;

  const SleepTodaySummaryCard({
    super.key,
    required this.controller,
    required this.mainColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final todayTotal = controller.todayTotalSleep(); // METHOD
    final last = controller.lastSleep(); // METHOD

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
                borderRadius: BorderRadius.circular(20),
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
                  Text(
                    'Bugün',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Toplam uyku: ${SleepFormatters.durationHM(todayTotal)}',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    last == null
                        ? 'Son uyku: -'
                        : 'Son uyku: ${SleepFormatters.durationHM(last.duration)} · ${SleepFormatters.dateTime(last.start)}',
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
            Icon(Icons.auto_awesome, color: mainColor.withValues(alpha: 0.55)),
          ],
        ),
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
