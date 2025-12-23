// lib/growth/growth_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../ads/anchored_adaptive_banner.dart';
import 'growth_controller.dart';
import 'growth_entry.dart';

class GrowthPage extends StatefulWidget {
  const GrowthPage({super.key});

  @override
  State<GrowthPage> createState() => _GrowthPageState();
}

class _GrowthPageState extends State<GrowthPage>
    with SingleTickerProviderStateMixin {
  late final GrowthController _controller;
  late final TabController _tab;

  final _weightCtrl = TextEditingController(); // gram
  final _lengthCtrl = TextEditingController(); // cm
  final _headCtrl = TextEditingController(); // cm

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = GrowthController();
    _tab = TabController(length: 3, vsync: this);

    _controller.load().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _weightCtrl.dispose();
    _lengthCtrl.dispose();
    _headCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  int? _parseInt(String s) {
    final cleaned = s.trim();
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  double? _parseDouble(String s) {
    final cleaned = s.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _prettyDate(DateTime d) {
    const months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _save() async {
    final weightGr = _parseInt(_weightCtrl.text);
    final lengthCm = _parseDouble(_lengthCtrl.text);
    final headCm = _parseDouble(_headCtrl.text);

    if (weightGr == null && lengthCm == null && headCm == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('En az bir ölçüm girin.')));
      return;
    }

    final entry = GrowthEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: _dateOnly(_selectedDate),
      weightGr: weightGr,
      lengthCm: lengthCm,
      headCm: headCm,
    );

    await _controller.add(entry);

    _weightCtrl.clear();
    _lengthCtrl.clear();
    _headCtrl.clear();

    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Kaydedildi.')));
  }

  Future<void> _delete(GrowthEntry entry) async {
    final ok = await _confirmDelete();
    if (!ok) return;

    await _controller.deleteById(entry.id);

    if (!mounted) return;
    setState(() {});
  }

  Future<bool> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Silinsin mi?'),
        content: const Text('Bu ölçüm kalıcı olarak silinecek. Emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final entries = _controller.entriesSorted;

    return Scaffold(
      appBar: AppBar(title: const Text('Gelişim')),
      bottomNavigationBar: const AnchoredAdaptiveBanner(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.primary.withValues(alpha: 0.10), cs.surface],
          ),
        ),
        child: ListView(
          // ✅ anchored banner varken alttan ekstra boşluk
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            _surfaceCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TabBar(
                    controller: _tab,
                    isScrollable: true,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    labelColor: cs.primary,
                    unselectedLabelColor: cs.onSurfaceVariant,
                    indicatorColor: cs.primary,
                    tabs: const [
                      Tab(text: 'Kilo'),
                      Tab(text: 'Boy'),
                      Tab(text: 'Baş Çevresi'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 190,
                    child: TabBarView(
                      controller: _tab,
                      children: [
                        _chart(
                          context,
                          entries: entries,
                          selector: (e) => e.weightKg,
                          unit: 'kg',
                        ),
                        _chart(
                          context,
                          entries: entries,
                          selector: (e) => e.lengthCm,
                          unit: 'cm',
                        ),
                        _chart(
                          context,
                          entries: entries,
                          selector: (e) => e.headCm,
                          unit: 'cm',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _surfaceCard(
              context,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Yeni Ölçüm',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _fieldRow(
                      context,
                      label: 'Kilo (g)',
                      hint: 'Örn: 3250',
                      controller: _weightCtrl,
                      trailing: IconButton(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _fieldRow(
                      context,
                      label: 'Boy (cm)',
                      hint: 'Örn: 52.5',
                      controller: _lengthCtrl,
                      trailing: const SizedBox(width: 40),
                    ),
                    const SizedBox(height: 12),
                    _fieldRow(
                      context,
                      label: 'Baş çevresi (cm)',
                      hint: 'Örn: 35.2',
                      controller: _headCtrl,
                      trailing: const SizedBox(width: 40),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _prettyDate(_selectedDate),
                      style: TextStyle(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _save,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Kaydet'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Geçmiş Ölçümler',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            if (entries.isEmpty)
              Text(
                'Henüz kayıt yok.',
                style: TextStyle(color: cs.onSurfaceVariant),
              )
            else
              ...entries.map((e) => _historyTile(context, e)),
          ],
        ),
      ),
    );
  }

  Widget _fieldRow(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    required Widget trailing,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            trailing,
          ],
        ),
      ],
    );
  }

  Widget _historyTile(BuildContext context, GrowthEntry e) {
    final cs = Theme.of(context).colorScheme;

    final parts = <String>[];
    if (e.weightKg != null) parts.add('${e.weightKg!.toStringAsFixed(2)} kg');
    if (e.lengthCm != null)
      parts.add('${e.lengthCm!.toStringAsFixed(1)} cm boy');
    if (e.headCm != null) parts.add('${e.headCm!.toStringAsFixed(1)} cm baş');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _surfaceCard(
        context,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Icon(Icons.monitor_heart, color: cs.primary),
          ),
          title: Text(
            parts.isEmpty ? '-' : parts.join(' • '),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            _prettyDate(e.date),
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(e),
          ),
        ),
      ),
    );
  }

  Widget _chart(
    BuildContext context, {
    required List<GrowthEntry> entries,
    required double? Function(GrowthEntry) selector,
    required String unit,
  }) {
    final cs = Theme.of(context).colorScheme;

    final filtered = <GrowthEntry>[];
    for (final e in entries) {
      final v = selector(e);
      if (v == null) continue;
      filtered.add(e);
    }

    filtered.sort((a, b) => a.date.compareTo(b.date));

    final points = <FlSpot>[];
    for (var i = 0; i < filtered.length; i++) {
      points.add(FlSpot(i.toDouble(), selector(filtered[i])!));
    }

    if (points.length < 2) {
      return Center(
        child: Text(
          'Grafik için en az 2 kayıt gerekli.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    final minY = points.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    final maxY = points.map((p) => p.y).reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) == 0 ? 1.0 : (maxY - minY) * 0.15;

    return LineChart(
      LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(1),
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= filtered.length) {
                  return const SizedBox.shrink();
                }
                final d = filtered[idx].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${d.day}.${d.month}',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: points,
            isCurved: true,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: true),
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
