// lib/sleep/widgets/sleep_timer_card.dart
import 'dart:async';
import 'package:flutter/material.dart';

import '../sleep_controller.dart';
import '../sleep_formatters.dart';

class SleepTimerCard extends StatefulWidget {
  final SleepController controller;
  final Color mainColor;
  final VoidCallback onToggleSleep;

  const SleepTimerCard({
    super.key,
    required this.controller,
    required this.mainColor,
    required this.onToggleSleep,
  });

  @override
  State<SleepTimerCard> createState() => _SleepTimerCardState();
}

class _SleepTimerCardState extends State<SleepTimerCard> {
  static const double _radius = 18;

  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _syncTicker(); // ilk state'e göre başlat/durdur
  }

  @override
  void didUpdateWidget(covariant SleepTimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _stopTicker();
      _syncTicker();
    }
  }

  void _onControllerChanged() {
    _syncTicker(); // uyku başladı/bitti
  }

  bool get _shouldTick =>
      widget.controller.isSleeping && widget.controller.currentStart != null;

  void _syncTicker() {
    if (_shouldTick) {
      _startTickerIfNeeded();
    } else {
      _stopTicker(redraw: true);
    }
  }

  void _startTickerIfNeeded() {
    if (_ticker != null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {}); // sadece bu kart yeniden çizilir
    });
  }

  void _stopTicker({bool redraw = false}) {
    _ticker?.cancel();
    _ticker = null;
    if (redraw && mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _stopTicker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final sleeping = widget.controller.isSleeping;
    final start = widget.controller.currentStart;

    final elapsed = (sleeping && start != null)
        ? DateTime.now().difference(start)
        : Duration.zero;

    final stateTitle = sleeping ? 'Uyuyor' : 'Uyanık';
    final stateIcon = sleeping
        ? Icons.nightlight_round
        : Icons.wb_sunny_rounded;

    // mainColor kullanımı (uygulama temasıyla hizalı)
    final iconBg = widget.mainColor.withValues(alpha: 0.12);
    final iconFg = widget.mainColor;

    final buttonBg = sleeping
        ? widget.mainColor.withValues(alpha: 0.92)
        : widget.mainColor;
    final buttonIcon = sleeping
        ? Icons.notifications_active
        : Icons.play_arrow_rounded;
    final buttonText = sleeping ? 'UYANDIR' : 'UYUT';

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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
              child: Icon(stateIcon, size: 34, color: iconFg),
            ),
            const SizedBox(height: 12),
            Text(
              'Miniğin şu anda',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stateTitle,
              style: TextStyle(
                fontFamily: 'Nunito',
                color: cs.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              SleepFormatters.timer(elapsed),
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 44,
                color: cs.onSurface,
                letterSpacing: 1.2,
              ),
            ),
            if (sleeping && start != null) ...[
              const SizedBox(height: 8),
              Text(
                'Başlangıç: ${SleepFormatters.dateTime(start)}',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.onToggleSleep,
                icon: Icon(buttonIcon),
                style: FilledButton.styleFrom(
                  backgroundColor: buttonBg,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                label: Text(
                  buttonText,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
