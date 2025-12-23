// lib/sleep/widgets/sleep_timer_card.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../sleep_controller.dart';
import '../sleep_formatters.dart';

import '../../core/app_globals.dart';
import '../../attacks/attack_calculator.dart';
import '../../attacks/attack_model.dart';

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

class _SleepTimerCardState extends State<SleepTimerCard>
    with SingleTickerProviderStateMixin {
  Timer? _ticker;

  late final AnimationController _pulseC;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();

    _pulseC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseC, curve: Curves.easeInOut));

    widget.controller.addListener(_onChanged);
    _syncTicker();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant SleepTimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
      _syncTicker();
      _syncPulse();
    }
  }

  void _onChanged() {
    if (!mounted) return;
    _syncTicker();
    _syncPulse();
    setState(() {});
  }

  void _syncTicker() {
    final shouldTick =
        widget.controller.isSleeping && widget.controller.currentStart != null;

    if (shouldTick && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {});
      });
    } else if (!shouldTick && _ticker != null) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _syncPulse() {
    if (widget.controller.isSleeping) {
      if (!_pulseC.isAnimating) _pulseC.repeat(reverse: true);
    } else {
      if (_pulseC.isAnimating) {
        _pulseC.stop();
        _pulseC.value = 0;
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _ticker?.cancel();
    _pulseC.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    HapticFeedback.selectionClick();

    final wasSleeping = widget.controller.isSleeping;
    await widget.controller.toggleSleep();
    widget.onToggleSleep();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(wasSleeping ? 'Uyku kaydı tamamlandı' : 'Uyku başladı'),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  // -------------------------
  // Attack bottom sheets
  // -------------------------

  void _showAttackInfo(BuildContext context, AttackModel a) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(a.description),
                const SizedBox(height: 14),
                _bullets(context, 'Sık Görülenler', a.symptoms),
                const SizedBox(height: 14),
                _bullets(context, 'Destek Önerileri', a.tips),
                const SizedBox(height: 12),
                const Divider(),
                ValueListenableBuilder<DateTime?>(
                  valueListenable: babyBirthDate,
                  builder: (_, birth, __) {
                    return ValueListenableBuilder<DateTime?>(
                      valueListenable: babyDueDate,
                      builder: (_, due, __) {
                        if (birth == null) return const SizedBox.shrink();
                        return Text(
                          AttackCalculator.calcNote(
                            birthDate: birth,
                            dueDate: due,
                          ),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.55),
                              ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDueDateInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Beklenen Doğum Tarihi (opsiyonel)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              const Text(
                'Erken doğan bebeklerde gelişim dönemleri doğum tarihine göre sapabilir. '
                'Beklenen doğum tarihini girerseniz atak haftası tahminlerini “düzeltilmiş yaş” '
                'mantığıyla daha isabetli hesaplarız.\n\n'
                'Bu bilgi yalnızca cihazınızda saklanır, kimliğinizle ilişkilendirilmez ve paylaşılmaz.',
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bullets(BuildContext context, String title, List<String> items) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: t.titleMedium),
        const SizedBox(height: 6),
        ...items.map(
          (x) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(child: Text(x)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------
  // Build
  // -------------------------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final isSleeping = widget.controller.isSleeping;
    final start = widget.controller.currentStart;

    final elapsed = (isSleeping && start != null)
        ? DateTime.now().difference(start)
        : Duration.zero;

    final bg = Color.alphaBlend(
      widget.mainColor.withValues(alpha: isSleeping ? 0.12 : 0.06),
      cs.surface,
    );

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ATTACK BAR (her zaman görünür)
          ValueListenableBuilder<DateTime?>(
            valueListenable: babyBirthDate,
            builder: (_, birth, __) {
              return ValueListenableBuilder<DateTime?>(
                valueListenable: babyDueDate,
                builder: (_, due, __) {
                  AttackModel? a;
                  if (birth != null) {
                    a = AttackCalculator.currentAttack(
                      birthDate: birth,
                      dueDate: due,
                    );
                  }

                  final hasAttack = a != null;

                  final title = hasAttack
                      ? 'Atak haftası olabilir • ${a.month}. Ay'
                      : 'Atak takvimi için doğum tarihini gir';

                  return InkWell(
                    onTap: () {
                      if (hasAttack) {
                        _showAttackInfo(context, a!);
                      } else {
                        _showDueDateInfo(context);
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: widget.mainColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          _AttackPulseIcon(color: widget.mainColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Icon(
                            Icons.info_outline_rounded,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 14),

          // STATUS
          Row(
            children: [
              _PulsingBubble(
                icon: isSleeping
                    ? Icons.nights_stay_rounded
                    : Icons.wb_sunny_rounded,
                color: widget.mainColor,
                pulse: isSleeping,
                pulseScale: _pulseScale,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Durum',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  Text(
                    isSleeping ? 'Uykuda' : 'Uyanık',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // BIG TIMER (aksiyon odağı)
          Center(
            child: Text(
              SleepFormatters.timer(elapsed),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // PRIMARY CTA
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _toggle,
              style: FilledButton.styleFrom(
                backgroundColor: widget.mainColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(isSleeping ? Icons.stop : Icons.play_arrow),
              label: Text(isSleeping ? 'UYANDIR' : 'UYUT'),
            ),
          ),

          const SizedBox(height: 10),

          // SECONDARY INFO
          if (isSleeping && start != null)
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: 'Uyku başladı: ${SleepFormatters.time(start)}',
                      ),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Başlangıç kopyalandı'),
                        duration: Duration(milliseconds: 700),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Başlangıcı kopyala'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Başlangıç: ${SleepFormatters.time(start)}',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// -------------------------
// UI helpers
// -------------------------

class _PulsingBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool pulse;
  final Animation<double> pulseScale;

  const _PulsingBubble({
    required this.icon,
    required this.color,
    required this.pulse,
    required this.pulseScale,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color),
    );

    if (!pulse) return child;

    return AnimatedBuilder(
      animation: pulseScale,
      builder: (_, __) =>
          Transform.scale(scale: pulseScale.value, child: child),
    );
  }
}

class _AttackPulseIcon extends StatefulWidget {
  final Color color;
  const _AttackPulseIcon({required this.color});

  @override
  State<_AttackPulseIcon> createState() => _AttackPulseIconState();
}

class _AttackPulseIconState extends State<_AttackPulseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _scale = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Icon(Icons.flash_on_rounded, color: widget.color),
      ),
    );
  }
}
