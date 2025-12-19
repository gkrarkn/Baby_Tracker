// lib/pages/sleep_page.dart
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_globals.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  // ---- Storage keys ----
  static const String _kSleepEntries = 'sleep_entries_v2';
  static const String _kCurrentSleepStart = 'sleep_current_start_v2';

  // ---- UI constants ----
  static const double _radius = 18;
  static const double _gridRadius = 20;

  final List<SleepEntry> _entries = [];
  DateTime? _sleepStart; // null => awake
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // -----------------------------
  // Persistence
  // -----------------------------
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final current = prefs.getString(_kCurrentSleepStart);
    if (current != null && current.trim().isNotEmpty) {
      _sleepStart = DateTime.tryParse(current);
    }

    final raw = prefs.getString(_kSleepEntries);
    if (raw != null && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _entries
          ..clear()
          ..addAll(
            decoded.whereType<Map>().map(
              (m) => SleepEntry.fromMap(Map<String, dynamic>.from(m)),
            ),
          );
      }
    }

    // newest first
    _entries.sort((a, b) => b.start.compareTo(a.start));

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kSleepEntries,
      jsonEncode(_entries.map((e) => e.toMap()).toList()),
    );

    if (_sleepStart == null) {
      await prefs.remove(_kCurrentSleepStart);
    } else {
      await prefs.setString(
        _kCurrentSleepStart,
        _sleepStart!.toIso8601String(),
      );
    }
  }

  // -----------------------------
  // Actions
  // -----------------------------
  Future<void> _toggleSleep() async {
    if (_sleepStart == null) {
      setState(() => _sleepStart = DateTime.now());
      await _persist();
      return;
    }

    final now = DateTime.now();
    final start = _sleepStart!;
    if (now.isBefore(start)) {
      setState(() => _sleepStart = null);
      await _persist();
      return;
    }

    final entry = SleepEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      start: DateTime(
        start.year,
        start.month,
        start.day,
        start.hour,
        start.minute,
        start.second,
      ),
      end: DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
        now.second,
      ),
    );

    setState(() {
      _sleepStart = null;
      _entries.insert(0, entry);
      _entries.sort((a, b) => b.start.compareTo(a.start));
    });

    await _persist();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Uyku kaydı eklendi.')));
  }

  Future<void> _confirmDeleteEntry(SleepEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
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
        );
      },
    );

    if (ok != true) return;

    setState(() => _entries.removeWhere((e) => e.id == entry.id));
    await _persist();
  }

  Future<void> _confirmClearAll() async {
    if (_entries.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
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
        );
      },
    );

    if (ok != true) return;

    setState(() => _entries.clear());
    await _persist();
  }

  void _openWeeklySummarySheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        final avg = _weeklyAvgSleep();
        final best = _weeklyBestDay();
        final routine = _weeklyRoutine();

        final series = _last7DaysSeriesOldestFirst();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '7 Gün Özeti',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),

              _surfaceCard(
                context,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Trend (son 7 gün)',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 64,
                        child: SleepSparkline(
                          minutes: series.map((e) => e.$2.inMinutes).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(series.first.$1),
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDate(series.last.$1),
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              _miniRow('Günlük ortalama', _formatDurationHM(avg)),
              const SizedBox(height: 10),
              _miniRow(
                'En iyi gün',
                best == null
                    ? '-'
                    : '${_formatDate(best.$1)} · ${_formatDurationHM(best.$2)}',
              ),
              const SizedBox(height: 10),
              _miniRow(
                'Rutin (ort.)',
                routine == null
                    ? '-'
                    : '${_formatTimeOfDay(routine.$1)} → ${_formatTimeOfDay(routine.$2)}',
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  // -----------------------------
  // Derived data
  // -----------------------------
  Duration _todayTotalSleep() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    Duration total = Duration.zero;

    for (final e in _entries) {
      final startDay = DateTime(e.start.year, e.start.month, e.start.day);
      if (startDay != todayStart) continue;
      total += e.duration;
    }

    if (_sleepStart != null) {
      final s = _sleepStart!;
      final sDay = DateTime(s.year, s.month, s.day);
      if (sDay == todayStart) {
        total += DateTime.now().difference(s);
      }
    }

    return total;
  }

  SleepEntry? _lastSleep() {
    if (_entries.isEmpty) return null;
    return _entries.first;
  }

  Map<DateTime, Duration> _last7DaysTotals() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final map = <DateTime, Duration>{};
    for (int i = 0; i < 7; i++) {
      final d = today.subtract(Duration(days: i));
      map[d] = Duration.zero;
    }

    for (final e in _entries) {
      final day = DateTime(e.start.year, e.start.month, e.start.day);
      if (!map.containsKey(day)) continue;
      map[day] = (map[day] ?? Duration.zero) + e.duration;
    }

    if (_sleepStart != null) {
      final s = _sleepStart!;
      final day = DateTime(s.year, s.month, s.day);
      if (map.containsKey(day)) {
        map[day] = (map[day] ?? Duration.zero) + DateTime.now().difference(s);
      }
    }

    return map;
  }

  List<(DateTime, Duration)> _last7DaysSeriesOldestFirst() {
    final totals = _last7DaysTotals();
    final keys = totals.keys.toList()..sort((a, b) => a.compareTo(b));
    return keys.map((k) => (k, totals[k] ?? Duration.zero)).toList();
  }

  Duration _weeklyAvgSleep() {
    final totals = _last7DaysTotals().values.toList();
    if (totals.isEmpty) return Duration.zero;
    final totalMin = totals.fold<int>(0, (p, d) => p + d.inMinutes);
    return Duration(minutes: (totalMin / totals.length).round());
  }

  (DateTime, Duration)? _weeklyBestDay() {
    final totals = _last7DaysTotals();
    if (totals.isEmpty) return null;

    DateTime? bestDay;
    Duration best = Duration.zero;

    for (final e in totals.entries) {
      if (e.value > best) {
        best = e.value;
        bestDay = e.key;
      }
    }

    if (bestDay == null) return null;
    return (bestDay, best);
  }

  (TimeOfDay, TimeOfDay)? _weeklyRoutine() {
    final since = DateTime.now().subtract(const Duration(days: 7));

    final starts = <int>[];
    final ends = <int>[];

    for (final e in _entries) {
      if (e.start.isBefore(since)) continue;
      starts.add(e.start.hour * 60 + e.start.minute);
      ends.add(e.end.hour * 60 + e.end.minute);
    }

    if (starts.length < 2 || ends.length < 2) return null;

    int avg(List<int> xs) => (xs.reduce((a, b) => a + b) / xs.length).round();

    final sAvg = avg(starts);
    final eAvg = avg(ends);

    return (
      TimeOfDay(hour: sAvg ~/ 60, minute: sAvg % 60),
      TimeOfDay(hour: eAvg ~/ 60, minute: eAvg % 60),
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
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Uyku Takibi',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
              ),
            ),
            backgroundColor: mainColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: '7 Gün Özeti',
                icon: const Icon(Icons.insights_outlined),
                onPressed: _openWeeklySummarySheet,
              ),
              IconButton(
                tooltip: 'Tümünü sil',
                icon: const Icon(Icons.delete_outline),
                onPressed: _confirmClearAll,
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _todaySummaryCard(context, mainColor),
                      const SizedBox(height: 14),
                      _timerCard(context, mainColor),
                      const SizedBox(height: 18),
                      Text(
                        'Geçmiş Uykular',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_entries.isEmpty)
                        Text(
                          'Henüz kayıt yok.',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            color: cs.onSurfaceVariant,
                          ),
                        )
                      else
                        ..._entries.map((e) => _historyTile(context, e)),
                      const SizedBox(height: 10),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _todaySummaryCard(BuildContext context, Color mainColor) {
    final cs = Theme.of(context).colorScheme;
    final todayTotal = _todayTotalSleep();
    final last = _lastSleep();

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
                borderRadius: BorderRadius.circular(_gridRadius),
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
                    'Toplam uyku: ${_formatDurationHM(todayTotal)}',
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
                        : 'Son uyku: ${_formatDurationHM(last.duration)} · ${_formatDateTime(last.start)}',
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

  Widget _timerCard(BuildContext context, Color mainColor) {
    final cs = Theme.of(context).colorScheme;
    final sleeping = _sleepStart != null;

    final stateTitle = sleeping ? 'Uyuyor' : 'Uyanık';
    final stateIcon = sleeping
        ? Icons.nightlight_round
        : Icons.wb_sunny_rounded;

    final elapsed = sleeping
        ? DateTime.now().difference(_sleepStart!)
        : Duration.zero;

    return _surfaceCard(
      context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (sleeping ? Colors.indigo : Colors.orange).withValues(
                  alpha: 0.12,
                ),
              ),
              child: Icon(
                stateIcon,
                size: 34,
                color: sleeping ? Colors.indigo : Colors.orange,
              ),
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
              _formatTimer(elapsed),
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 44,
                color: cs.onSurface,
                letterSpacing: 1.2,
              ),
            ),
            if (sleeping) ...[
              const SizedBox(height: 8),
              Text(
                'Başlangıç: ${_formatDateTime(_sleepStart!)}',
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
                onPressed: _toggleSleep,
                icon: Icon(
                  sleeping
                      ? Icons.notifications_active
                      : Icons.play_arrow_rounded,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: sleeping
                      ? Colors.amber.shade700
                      : Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                label: Text(
                  sleeping ? 'UYANDIR' : 'UYUT',
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

  Widget _historyTile(BuildContext context, SleepEntry e) {
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
            'Uyku: ${_formatDurationHM(e.duration)}',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            '${_formatDateTime(e.start)} → ${_formatTime(e.end)}',
            style: TextStyle(fontFamily: 'Nunito', color: cs.onSurfaceVariant),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDeleteEntry(e),
          ),
        ),
      ),
    );
  }

  Widget _miniRow(String left, String right) {
    final cs = Theme.of(context).colorScheme;
    return _surfaceCard(
      context,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                left,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ),
            Text(
              right,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
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

  // -----------------------------
  // Format helpers
  // -----------------------------
  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _formatTimer(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${_two(h)}:${_two(m)}:${_two(s)}';
  }

  static String _formatDurationHM(Duration d) {
    final totalMin = d.inMinutes;
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    if (h <= 0) return '${m}dk';
    if (m == 0) return '${h}s';
    return '${h}s ${m}dk';
  }

  static String _formatTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  static String _formatDate(DateTime d) => '${_two(d.day)}.${_two(d.month)}';

  static String _formatTimeOfDay(TimeOfDay t) =>
      '${_two(t.hour)}:${_two(t.minute)}';

  static String _formatDateTime(DateTime d) {
    return '${_two(d.day)}.${_two(d.month)}.${d.year} - ${_formatTime(d)}';
  }
}

// -----------------------------
// Sparkline
// -----------------------------
class SleepSparkline extends StatelessWidget {
  final List<int> minutes; // 7 point
  const SleepSparkline({super.key, required this.minutes});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _SparklinePainter(
        values: minutes,
        lineColor: cs.primary,
        fillColor: cs.primary.withValues(alpha: 0.12),
        gridColor: cs.outlineVariant.withValues(alpha: 0.35),
        labelColor: cs.onSurfaceVariant,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<int> values;

  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final Color labelColor;

  _SparklinePainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final vMin = values.reduce(math.min);
    final vMax = values.reduce(math.max);

    final topPad = 8.0;
    final bottomPad = 10.0;
    final leftPad = 0.0;
    final rightPad = 0.0;

    final w = size.width - leftPad - rightPad;
    final h = size.height - topPad - bottomPad;

    double norm(int v) {
      if (vMax == vMin) return 0.5;
      return (v - vMin) / (vMax - vMin);
    }

    Offset pointAt(int idx) {
      final x =
          leftPad +
          (values.length == 1 ? w / 2 : (w * idx / (values.length - 1)));
      final y = topPad + (h * (1 - norm(values[idx])));
      return Offset(x, y);
    }

    // Grid single line
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(leftPad, topPad + h / 2),
      Offset(leftPad + w, topPad + h / 2),
      gridPaint,
    );

    final path = Path();
    final fillPath = Path();

    final p0 = pointAt(0);
    path.moveTo(p0.dx, p0.dy);

    for (int i = 1; i < values.length; i++) {
      final p = pointAt(i);
      final prev = pointAt(i - 1);
      final mid = Offset((prev.dx + p.dx) / 2, (prev.dy + p.dy) / 2);

      path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);

      if (i == values.length - 1) {
        path.quadraticBezierTo(mid.dx, mid.dy, p.dx, p.dy);
      }
    }

    fillPath.addPath(path, Offset.zero);
    fillPath.lineTo(leftPad + w, topPad + h);
    fillPath.lineTo(leftPad, topPad + h);
    fillPath.close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = lineColor;
    for (int i = 0; i < values.length; i++) {
      canvas.drawCircle(pointAt(i), 3.2, dotPaint);
    }

    final textStyle = TextStyle(
      fontFamily: 'Nunito',
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: labelColor,
    );

    final maxText = '${vMax} dk';
    final minText = '${vMin} dk';

    final tpMax = TextPainter(
      text: TextSpan(text: maxText, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    final tpMin = TextPainter(
      text: TextSpan(text: minText, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    tpMax.paint(canvas, const Offset(0, 0));
    tpMin.paint(canvas, Offset(0, size.height - tpMin.height));
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    if (oldDelegate.values.length != values.length) return true;
    for (int i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}

// -----------------------------
// Model
// -----------------------------
class SleepEntry {
  final String id;
  final DateTime start;
  final DateTime end;

  const SleepEntry({required this.id, required this.start, required this.end});

  Duration get duration => end.difference(start);

  Map<String, dynamic> toMap() => {
    'id': id,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
  };

  factory SleepEntry.fromMap(Map<String, dynamic> map) {
    return SleepEntry(
      id: (map['id'] ?? '').toString(),
      start:
          DateTime.tryParse((map['start'] ?? '').toString()) ?? DateTime.now(),
      end: DateTime.tryParse((map['end'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
