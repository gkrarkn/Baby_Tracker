import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_summary_repo.dart';

class DashboardSummarySheet extends StatelessWidget {
  final TodaySummary today;
  final WeeklyFeedingSummary weeklyFeeding;

  final bool isPremium;
  final VoidCallback onTapUpgrade;
  final VoidCallback onClose;

  const DashboardSummarySheet({
    super.key,
    required this.today,
    required this.weeklyFeeding,
    required this.isPremium,
    required this.onTapUpgrade,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(context),
            const SizedBox(height: 14),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Bugün',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _todayCards(context),

            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Son 7 Gün',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _weeklySection(context),

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            'Özet',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close),
          tooltip: 'Kapat',
        ),
      ],
    );
  }

  Widget _todayCards(BuildContext context) {
    final milkText = today.milkMl > 0 ? '${today.milkMl} ml' : '—';
    final solidText = today.solidCount > 0 ? '${today.solidCount}' : '—';
    final sleepText = _formatDuration(today.sleep);

    return Row(
      children: [
        Expanded(
          child: _metricCard(
            context,
            title: 'Süt',
            value: milkText,
            icon: Icons.local_drink,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            context,
            title: 'Ek Gıda',
            value: solidText,
            icon: Icons.apple,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            context,
            title: 'Uyku',
            value: (today.sleep == Duration.zero) ? '—' : sleepText,
            icon: Icons.bedtime,
            subtitle: 'V9.2',
            muted: true,
          ),
        ),
      ],
    );
  }

  Widget _weeklySection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Repo 7 günü default 0’larla başlatıyor olabilir; bu yüzden “gerçek veri var mı?”
    final hasAnyData =
        weeklyFeeding.totalMilkMl > 0 || weeklyFeeding.totalSolidCount > 0;

    if (!hasAnyData) {
      return _box(
        context,
        child: Text(
          'Son 7 gün için henüz kayıt yok.',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            color: cs.onSurfaceVariant,
          ),
        ),
      );
    }

    final milkList = weeklyFeeding.milkByDay; // 7 eleman (0 olabilir)
    final labels = weeklyFeeding.milkByDayKeys; // map key’leri (0..7) olabilir
    final solidList = weeklyFeeding.solidByDay;

    // Premium olmayan kullanıcı: toplu özet + sparkline + premium gate
    if (!isPremium) {
      return Column(
        children: [
          _box(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Toplam süt: ${weeklyFeeding.totalMilkMl} ml',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Toplam ek gıda: ${weeklyFeeding.totalSolidCount}',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // Sparkline (milk)
                _sparklineBlock(
                  context,
                  title: 'Süt (son 7 gün)',
                  values: milkList,
                ),

                const SizedBox(height: 12),
                _premiumGate(context),
              ],
            ),
          ),
        ],
      );
    }

    // Premium: sparkline + trend + tablo
    final trendText = weeklyFeeding.milkTrendDelta == 0
        ? 'Süt trendi stabil.'
        : (weeklyFeeding.milkTrendDelta > 0
              ? 'Süt trendi artışta.'
              : 'Süt trendi düşüşte.');

    return Column(
      children: [
        _box(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sparklineBlock(
                context,
                title: 'Süt (son 7 gün)',
                values: milkList,
              ),
              const SizedBox(height: 12),
              Text(
                'Ortalama süt/gün: ${weeklyFeeding.avgMilkPerDay.toStringAsFixed(0)} ml',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ortalama ek gıda/gün: ${weeklyFeeding.avgSolidPerDay.toStringAsFixed(1)}',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                trendText,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _dailyTable(
          context,
          labels: labels,
          milkList: milkList,
          solidList: solidList,
        ),
      ],
    );
  }

  Widget _dailyTable(
    BuildContext context, {
    required List<String> labels,
    required List<int> milkList,
    required List<int> solidList,
  }) {
    final cs = Theme.of(context).colorScheme;

    // güvenli min-length
    final count = [
      labels.length,
      milkList.length,
      solidList.length,
    ].reduce((a, b) => a < b ? a : b);

    return _box(
      context,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Gün',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
              ),
              SizedBox(
                width: 88,
                child: Text(
                  'Süt',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 72,
                child: Text(
                  'Ek',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _shortDate(labels[i]),
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 88,
                    child: Text(
                      milkList[i] == 0 ? '—' : '${milkList[i]} ml',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 72,
                    child: Text(
                      solidList[i] == 0 ? '—' : '${solidList[i]}',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sparklineBlock(
    BuildContext context, {
    required String title,
    required List<int> values,
  }) {
    final cs = Theme.of(context).colorScheme;

    final maxV = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    final minV = values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          width: double.infinity,
          child: CustomPaint(
            painter: _SparklinePainter(
              values: values.map((e) => e.toDouble()).toList(),
              lineColor: cs.primary,
              gridColor: cs.outlineVariant.withValues(alpha: 0.35),
              fillColor: cs.primary.withValues(alpha: 0.10),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          maxV == 0 ? '—' : 'Min: $minV ml • Max: $maxV ml',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _premiumGate(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: cs.surface.withValues(alpha: 0.9),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Detaylı günlük kırılım ve trend analizi Premium ile açılır.',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: onTapUpgrade, child: const Text('Premium')),
        ],
      ),
    );
  }

  // -------------------------
  // UI helpers
  // -------------------------
  Widget _box(BuildContext context, {required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cs.surface,
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

  Widget _metricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    String? subtitle,
    bool muted = false,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cs.surface,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 12.2,
              fontWeight: FontWeight.w900,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: muted
                  ? cs.onSurfaceVariant.withValues(alpha: 0.65)
                  : cs.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.nunito(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: cs.onSurfaceVariant.withValues(alpha: 0.55),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h <= 0 && m <= 0) return '—';
    if (h > 0) return '${h}s ${m}d';
    return '${m}d';
  }

  String _shortDate(String key) {
    // "YYYY-MM-DD" -> "MM/DD"
    final parts = key.split('-');
    if (parts.length != 3) return key;
    return '${parts[1]}/${parts[2]}';
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color gridColor;
  final Color fillColor;

  _SparklinePainter({
    required this.values,
    required this.lineColor,
    required this.gridColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    // Tüm değerler 0 ise (ya da tekil), çok “düz” görünmesin diye baseline çizelim.
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);

    final hasRange = (maxV - minV).abs() > 0.0001;

    // light grid (tek çizgi)
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final midY = size.height * 0.65;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), gridPaint);

    // normalize
    final leftPad = 2.0;
    final rightPad = 2.0;
    final topPad = 2.0;
    final bottomPad = 2.0;

    final w = size.width - leftPad - rightPad;
    final h = size.height - topPad - bottomPad;

    double nx(int i) {
      if (values.length == 1) return leftPad + w / 2;
      return leftPad + (w * (i / (values.length - 1)));
    }

    double ny(double v) {
      if (!hasRange) {
        // hepsi aynıysa ortada çiz
        return topPad + h * 0.55;
      }
      final t = (v - minV) / (maxV - minV); // 0..1
      return topPad + (h * (1 - t));
    }

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final p = Offset(nx(i), ny(values[i]));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    // fill
    final fillPath = Path.from(path)
      ..lineTo(nx(values.length - 1), topPad + h)
      ..lineTo(nx(0), topPad + h)
      ..close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // line
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // last dot
    final last = Offset(nx(values.length - 1), ny(values.last));
    final dotPaint = Paint()..color = lineColor;
    canvas.drawCircle(last, 2.8, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.fillColor != fillColor;
  }
}
