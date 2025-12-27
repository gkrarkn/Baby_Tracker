// lib/growth/growth_page.dart
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/app_globals.dart'
    show babyBirthDate, babyGender, formatDateTr, appThemeColor;

import '../ads/anchored_adaptive_banner.dart';
import '../core/app_globals.dart' show babyBirthDate, babyGender, formatDateTr;
import '../widgets/page_appbar_title.dart';
import 'growth_controller.dart';
import 'growth_entry.dart';
import 'who/who_models.dart' as who;
import 'who/who_provider.dart' as who_data;

enum GrowthTab { weight, length, head }

extension GrowthTabX on GrowthTab {
  String get label => switch (this) {
    GrowthTab.weight => 'Kilo',
    GrowthTab.length => 'Boy',
    GrowthTab.head => 'Baş Çevresi',
  };

  who.WhoMetric get whoMetric => switch (this) {
    GrowthTab.weight => who.WhoMetric.weight,
    GrowthTab.length => who.WhoMetric.length,
    GrowthTab.head => who.WhoMetric.head,
  };
}

class GrowthPage extends StatefulWidget {
  const GrowthPage({super.key});

  @override
  State<GrowthPage> createState() => _GrowthPageState();
}

class _GrowthPageState extends State<GrowthPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final GrowthController _controller = GrowthController();

  final TextEditingController _weightGrCtrl = TextEditingController();
  final TextEditingController _lengthCmCtrl = TextEditingController();
  final TextEditingController _headCmCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  final who_data.WhoProvider _who = who_data.WhoProvider.instance;

  // X ekseni: gün index (tarih label stabil)
  static final DateTime _epochDay = DateTime(1970, 1, 1);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller.load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _weightGrCtrl.dispose();
    _lengthCmCtrl.dispose();
    _headCmCtrl.dispose();
    super.dispose();
  }

  GrowthTab get _activeTab => GrowthTab.values[_tabController.index];

  // ---------------- Helpers ----------------

  who.WhoGender? _whoGenderFromPrefs(String g) {
    if (g == 'boy') return who.WhoGender.boy;
    if (g == 'girl') return who.WhoGender.girl;
    return null;
  }

  int? _ageDays(DateTime measurementDate) {
    final birth = babyBirthDate.value;
    if (birth == null) return null;
    return measurementDate.difference(birth).inDays;
  }

  double _xFromDate(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.difference(_epochDay).inDays.toDouble();
  }

  DateTime _dateFromX(double x) {
    return _epochDay.add(Duration(days: x.round()));
  }

  String _formatDateShort(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

  double? _valueForTab(GrowthEntry e, GrowthTab tab) {
    return switch (tab) {
      GrowthTab.weight => _weightKgOrNull(e),
      GrowthTab.length => _lengthCmOrNull(e),
      GrowthTab.head => _headCmOrNull(e),
    };
  }

  double? _weightKgOrNull(GrowthEntry e) {
    final wg = e.weightGr;
    if (wg == null || wg <= 0) return null;
    return wg / 1000.0;
  }

  double? _lengthCmOrNull(GrowthEntry e) {
    final lc = e.lengthCm;
    if (lc == null || lc <= 0) return null;
    return lc;
  }

  double? _headCmOrNull(GrowthEntry e) {
    final hc = e.headCm;
    if (hc == null || hc <= 0) return null;
    return hc;
  }

  List<FlSpot> _whoSpotsP(
    who.WhoSeries series,
    double Function(who.WhoPoint p) pick,
  ) {
    final birth = babyBirthDate.value!;
    return series.points.map((p) {
      final d = birth.add(Duration(days: p.ageDays));
      return FlSpot(_xFromDate(d), pick(p));
    }).toList();
  }

  Future<void> _pickMeasurementDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _saveMeasurement() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final weightGr = int.tryParse(_weightGrCtrl.text.trim());
    final lengthCm = double.tryParse(_lengthCmCtrl.text.trim());
    final headCm = double.tryParse(_headCmCtrl.text.trim());

    final entry = GrowthEntry(
      id: id,
      date: _selectedDate,
      weightGr: (weightGr == null || weightGr <= 0) ? null : weightGr,
      lengthCm: (lengthCm == null || lengthCm <= 0) ? null : lengthCm,
      headCm: (headCm == null || headCm <= 0) ? null : headCm,
    );

    if (entry.weightGr == null &&
        entry.lengthCm == null &&
        entry.headCm == null) {
      return;
    }

    await _controller.add(entry);

    _weightGrCtrl.clear();
    _lengthCmCtrl.clear();
    _headCmCtrl.clear();

    if (!mounted) return;
    setState(() => _selectedDate = DateTime.now());
  }

  void _showWhoInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('WHO referans aralığı'),
        content: const Text(
          'Grafikteki referans bant Dünya Sağlık Örgütü (WHO) büyüme standartlarına '
          'göre p3–p97 aralığını temsil eder.\n\n'
          'Bu karşılaştırma; doğum tarihi ve cinsiyet seçiliyse yaklaşık bir referans sağlar. '
          'Klinik değerlendirme için doktorunuza danışınız.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final mainColor = appThemeColor.value; // Theme.primary yerine bunu kullan

    return Scaffold(
      appBar: AppBar(
        title: const PageAppBarTitle(
          title: 'Gelişim',
          icon: Icons.show_chart_rounded,
        ),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _surfaceCard(
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: mainColor,
                      unselectedLabelColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.75),
                      indicatorColor: mainColor,
                      tabs: const [
                        Tab(text: 'Kilo'),
                        Tab(text: 'Boy'),
                        Tab(text: 'Baş Çevresi'),
                      ],
                      onTap: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    _buildChartBlock(mainColor),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _surfaceCard(child: _buildNewMeasurementForm(mainColor)),
              const SizedBox(height: 14),
              _surfaceCard(child: _buildRecordsList()),
              const SizedBox(height: 10),
              const AnchoredAdaptiveBanner(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChartBlock(Color mainColor) {
    final entriesOldestFirst = _controller.entriesOldestFirst;

    final measurementSpots = <FlSpot>[];
    for (final e in entriesOldestFirst) {
      final v = _valueForTab(e, _activeTab);
      if (v == null) continue;
      measurementSpots.add(FlSpot(_xFromDate(e.date), v));
    }

    final birth = babyBirthDate.value;
    final gender = _whoGenderFromPrefs(babyGender.value);
    final canWho = birth != null && gender != null;

    final latest = entriesOldestFirst.isEmpty ? null : entriesOldestFirst.last;
    final latestValue = latest == null
        ? null
        : _valueForTab(latest, _activeTab);
    final latestAgeDays = latest == null ? null : _ageDays(latest.date);

    return FutureBuilder<String?>(
      future: (canWho && latestAgeDays != null && latestValue != null)
          ? _who.statusText(
              gender: gender,
              metric: _activeTab.whoMetric,
              ageDays: latestAgeDays,
              value: latestValue,
            )
          : Future.value(null),
      builder: (_, snapText) {
        final status = snapText.data;

        final microText = canWho
            ? (status == null
                  ? 'WHO’ya göre: değerlendirme yapılamadı.'
                  : 'WHO’ya göre: $status')
            : 'WHO karşılaştırması için doğum tarihi + cinsiyet gerekli.';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    microText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (canWho)
                  IconButton(
                    onPressed: _showWhoInfoDialog,
                    icon: const Icon(Icons.info_outline_rounded),
                    tooltip: 'WHO bilgisi',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 230,
              child: _buildLineChart(
                mainColor: mainColor,
                measurementSpots: measurementSpots,
                canWho: canWho,
                gender: gender,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLineChart({
    required Color mainColor,
    required List<FlSpot> measurementSpots,
    required bool canWho,
    required who.WhoGender? gender,
  }) {
    if (measurementSpots.isEmpty) {
      return Center(
        child: Text(
          'Henüz ölçüm yok.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    double minX = measurementSpots.first.x;
    double maxX = measurementSpots.last.x;

    if (minX == maxX) {
      minX -= 1;
      maxX += 1;
    }

    double minY = measurementSpots.map((e) => e.y).reduce(math.min);
    double maxY = measurementSpots.map((e) => e.y).reduce(math.max);

    return FutureBuilder<who.WhoSeries?>(
      future: (canWho && gender != null)
          ? _who.load(gender, _activeTab.whoMetric)
          : Future.value(null),
      builder: (_, snapSeries) {
        final series = snapSeries.data;

        final bars = <LineChartBarData>[];

        if (canWho && series != null && babyBirthDate.value != null) {
          final p3 = _whoSpotsP(series, (p) => p.p3);
          final p50 = _whoSpotsP(series, (p) => p.p50);
          final p97 = _whoSpotsP(series, (p) => p.p97);

          bars.addAll([
            LineChartBarData(
              spots: p3,
              isCurved: true,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.20),
            ),
            LineChartBarData(
              spots: p97,
              isCurved: true,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.20),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            LineChartBarData(
              spots: p50,
              isCurved: true,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.12),
            ),
          ]);

          final allWhoY = [...p3, ...p50, ...p97].map((e) => e.y);
          if (allWhoY.isNotEmpty) {
            minY = math.min(minY, allWhoY.reduce(math.min));
            maxY = math.max(maxY, allWhoY.reduce(math.max));
          }
        }

        bars.add(
          LineChartBarData(
            spots: measurementSpots,
            isCurved: true,
            barWidth: 4,
            dotData: const FlDotData(show: true),
            color: mainColor.withValues(alpha: 0.75),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.18),
            ),
          ),
        );

        final yPadding = (maxY - minY).abs() * 0.15;
        final safeMinY = minY - (yPadding == 0 ? 1 : yPadding);
        final safeMaxY = maxY + (yPadding == 0 ? 1 : yPadding);

        final rangeDays = (maxX - minX).abs();
        final intervalDays = math.max(1, (rangeDays / 4).round()).toDouble();

        return LineChart(
          LineChartData(
            minX: minX,
            maxX: maxX,
            minY: safeMinY,
            maxY: safeMaxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              drawHorizontalLine: true,
              getDrawingHorizontalLine: (_) => FlLine(
                strokeWidth: 1,
                dashArray: [6, 6],
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.20),
              ),
              getDrawingVerticalLine: (_) => FlLine(
                strokeWidth: 1,
                dashArray: [6, 6],
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.20),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: bars,
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 38,
                  getTitlesWidget: (v, meta) => Text(
                    v.toStringAsFixed(0),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.70),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  interval: intervalDays,
                  getTitlesWidget: (v, meta) {
                    if ((v - v.round()).abs() > 0.0001) {
                      return const SizedBox.shrink();
                    }
                    if (v < meta.min - 0.01 || v > meta.max + 0.01) {
                      return const SizedBox.shrink();
                    }

                    final d = _dateFromX(v);

                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8,
                      child: Text(
                        _formatDateShort(d),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.70),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewMeasurementForm(Color mainColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yeni Ölçüm',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          'Kilo (g)',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        _inputWithCalendar(
          controller: _weightGrCtrl,
          hint: 'Örn: 3250',
          onCalendarTap: _pickMeasurementDate,
        ),
        const SizedBox(height: 12),
        Text(
          'Boy (cm)',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        _textField(
          controller: _lengthCmCtrl,
          hint: 'Örn: 52.5',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        Text(
          'Baş çevresi (cm)',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        _textField(
          controller: _headCmCtrl,
          hint: 'Örn: 35.0',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'Tarih: ${_formatDateShort(_selectedDate)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: _saveMeasurement,
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecordsList() {
    final items = _controller.entriesNewestFirst;

    if (items.isEmpty) {
      return Text('Kayıt yok.', style: Theme.of(context).textTheme.bodyMedium);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kayıtlar',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...items.map((e) {
          final w = _weightKgOrNull(e);
          final l = _lengthCmOrNull(e);
          final h = _headCmOrNull(e);

          final parts = <String>[];
          if (w != null) parts.add('Kilo: ${w.toStringAsFixed(2)} kg');
          if (l != null) parts.add('Boy: ${l.toStringAsFixed(1)} cm');
          if (h != null) parts.add('Baş: ${h.toStringAsFixed(1)} cm');

          return Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  formatDateTr(e.date),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(parts.join(' • ')),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () async => _controller.deleteById(e.id),
                ),
              ),
              if (e.id != items.last.id) const Divider(height: 1),
            ],
          );
        }),
      ],
    );
  }

  Widget _inputWithCalendar({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onCalendarTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: _textField(
            controller: controller,
            hint: hint,
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: onCalendarTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.20),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.calendar_month_rounded),
          ),
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _surfaceCard({required Widget child}) {
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
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }
}
