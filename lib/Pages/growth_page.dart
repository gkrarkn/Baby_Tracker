import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';

import '../core/app_globals.dart';

// --- GELİŞİM SAYFASI 📈 ---
class _GrowthSample {
  final double weight;
  final double height;
  final String label;

  _GrowthSample({
    required this.weight,
    required this.height,
    required this.label,
  });
}

class GrowthPage extends StatefulWidget {
  const GrowthPage({super.key});
  @override
  State<GrowthPage> createState() => _GrowthPageState();
}

class _GrowthPageState extends State<GrowthPage> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _headController = TextEditingController();
  List<String> growthLogs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _headController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      growthLogs = prefs.getStringList('growthLogs') ?? [];
    });
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('growthLogs', growthLogs);
  }

  void _saveEntry() {
    if (_weightController.text.isEmpty || _heightController.text.isEmpty) {
      return;
    }

    final weight = _weightController.text.replaceAll(',', '.');
    final height = _heightController.text.replaceAll(',', '.');
    final head = _headController.text.replaceAll(',', '.');
    final timeStamp = getCurrentDateTime();

    var entryText = "⚖️ $weight kg  -  📏 $height cm";
    if (head.isNotEmpty) entryText += "\n🧢 Baş Çevresi: $head cm";
    entryText += "|$timeStamp";

    setState(() {
      growthLogs.insert(0, entryText);
      _saveLogs();
      _weightController.clear();
      _heightController.clear();
      _headController.clear();
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('growthLogs');
    setState(() => growthLogs.clear());
  }

  List<_GrowthSample> _parseGrowthSamples() {
    final regexWeight = RegExp(r'⚖️\s*([\d.,]+)\s*kg');
    final regexHeight = RegExp(r'📏\s*([\d.,]+)\s*cm');
    final List<_GrowthSample> samples = [];

    for (int i = growthLogs.length - 1; i >= 0; i--) {
      final log = growthLogs[i];
      final parts = log.split('|');
      final text = parts[0];
      final rawDate = parts.length > 1 ? parts[1] : "";

      final matchW = regexWeight.firstMatch(text);
      final matchH = regexHeight.firstMatch(text);
      if (matchW == null || matchH == null) continue;

      final w = double.tryParse(matchW.group(1)!.replaceAll(',', '.'));
      final h = double.tryParse(matchH.group(1)!.replaceAll(',', '.'));
      if (w == null || h == null) continue;

      final datePart = rawDate.split(' - ').first;
      final pieces = datePart.split('.');
      String label;
      if (pieces.length == 3) {
        final day = pieces[0];
        final month = pieces[1];
        final year = pieces[2];
        final shortYear = year.length >= 2
            ? year.substring(year.length - 2)
            : year;
        label = "$day.$month.$shortYear";
      } else {
        label = datePart;
      }

      samples.add(_GrowthSample(weight: w, height: h, label: label));
    }
    return samples;
  }

  Widget _buildChartCard({
    required String title,
    required String unit,
    required List<FlSpot> spots,
    required List<String> labels,
    required Color color,
  }) {
    if (spots.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title ($unit)",
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, thickness: 1, color: Color(0x33000000)),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        int step = 1;
                        if (labels.length > 8) step = 2;
                        if (labels.length > 12) step = 3;
                        if (labels.length > 20) step = 4;
                        if (index % step != 0) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[index],
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final samples = _parseGrowthSamples();
    final List<FlSpot> weightSpots = [];
    final List<FlSpot> heightSpots = [];
    final List<String> labels = [];

    for (int i = 0; i < samples.length; i++) {
      final x = i.toDouble();
      weightSpots.add(FlSpot(x, samples[i].weight));
      heightSpots.add(FlSpot(x, samples[i].height));
      labels.add(samples[i].label);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Gelişim Takibi 📈"),
        backgroundColor: Colors.teal.shade100,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: _clearLogs,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: "Kilo (kg)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(
                          Icons.monitor_weight,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: "Boy (cm)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(
                          Icons.height,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _headController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: "Baş Çevresi (cm)",
                  hintText: "Opsiyonel",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.face, color: Colors.teal),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    "KAYDET",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (weightSpots.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildChartCard(
                  title: "Kilo",
                  unit: "kg",
                  spots: weightSpots,
                  labels: labels,
                  color: Colors.teal,
                ),
                _buildChartCard(
                  title: "Boy",
                  unit: "cm",
                  spots: heightSpots,
                  labels: labels,
                  color: Colors.orange,
                ),
              ],
              const SizedBox(height: 30),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Gelişim Geçmişi",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: growthLogs.length,
                itemBuilder: (context, index) {
                  final parts = growthLogs[index].split('|');
                  return Card(
                    color: Colors.teal.shade50,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      leading: const Icon(
                        Icons.show_chart,
                        color: Colors.teal,
                        size: 30,
                      ),
                      title: Text(
                        parts[0],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(parts.length > 1 ? parts[1] : ""),
                      trailing: const Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
