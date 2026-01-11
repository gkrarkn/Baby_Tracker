import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/page_appbar_title.dart';
import '../widgets/history_card.dart';
import '../ads/anchored_adaptive_banner.dart';

import 'package:baby_tracker/core/app_globals.dart';

class FeedingPage extends StatefulWidget {
  const FeedingPage({super.key});

  @override
  State<FeedingPage> createState() => _FeedingPageState();
}

class _FeedingPageState extends State<FeedingPage> {
  FeedingType _selectedType = FeedingType.formula;
  double _mlValue = 90;

  SolidUnit _foodUnit = SolidUnit.gr;
  late final TextEditingController _foodAmountController;
  late final TextEditingController _foodNoteController;

  final List<String> _feedingLogs = [];
  static const String _prefsKey = 'feedingLogs';

  @override
  void initState() {
    super.initState();
    _foodAmountController = TextEditingController();
    _foodNoteController = TextEditingController();
    _loadLogs();
  }

  @override
  void dispose() {
    _foodAmountController.dispose();
    _foodNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logs = prefs.getStringList(_prefsKey) ?? <String>[];
    if (!mounted) return;
    setState(() {
      _feedingLogs
        ..clear()
        ..addAll(logs);
    });
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _feedingLogs);
  }

  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    if (!mounted) return;
    setState(_feedingLogs.clear);
  }

  void _saveFeeding() {
    final timestamp = getCurrentDateTime();
    final entry = _buildLogEntry(timestamp);
    if (entry == null) return;

    setState(() => _feedingLogs.insert(0, entry));
    _saveLogs();
  }

  String? _buildLogEntry(String timestamp) {
    switch (_selectedType) {
      case FeedingType.breastMilk:
      case FeedingType.formula:
        final icon = _selectedType == FeedingType.breastMilk ? '❤️' : '🍼';
        return "$icon ${_selectedType.label} - ${_mlValue.round()} ml|$timestamp";

      case FeedingType.solid:
        final amount = _foodAmountController.text.trim();
        if (amount.isEmpty) return null;

        final note = _foodNoteController.text.trim();
        final noteText = note.isEmpty ? '' : ' ($note)';

        _foodAmountController.clear();
        _foodNoteController.clear();

        return "🥣 Ek Gıda - $amount ${_foodUnit.label}$noteText|$timestamp";
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return "${now.day}.${now.month}.${now.year}";
  }

  int _todayTotalMl() {
    final today = _todayKey();
    int total = 0;

    for (final log in _feedingLogs) {
      final parts = log.split('|');
      if (parts.length < 2) continue;
      if (!parts[1].startsWith(today)) continue;

      final match = RegExp(r'(\d+)\s*ml').firstMatch(parts[0]);
      if (match != null) total += int.parse(match.group(1)!);
    }
    return total;
  }

  int _todaySolidCount() {
    final today = _todayKey();
    int count = 0;

    for (final log in _feedingLogs) {
      final parts = log.split('|');
      if (parts.length < 2) continue;
      if (!parts[1].startsWith(today)) continue;

      if (parts[0].startsWith('🥣 Ek Gıda')) count++;
    }
    return count;
  }

  Widget _buildTodaySummaryCard(Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.insights, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bugün',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Toplam: ${_todayTotalMl()} ml  •  Ek gıda: ${_todaySolidCount()}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = appThemeColor.value;

    return Scaffold(
      appBar: AppBar(
        title: const PageAppBarTitle(
          title: 'Beslenme',
          icon: Icons.restaurant_rounded,
        ),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _clearAll,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      bottomNavigationBar: const AnchoredAdaptiveBanner(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 12),
            _buildTodaySummaryCard(Colors.orange),
            const SizedBox(height: 16),

            _selectedType == FeedingType.solid
                ? _buildSolidFoodInputs()
                : _buildMlSelector(),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saveFeeding,
              icon: const Icon(Icons.save),
              label: const Text('KAYDET'),
            ),
            const SizedBox(height: 24),

            Text(
              'Geçmiş Beslenmeler',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),

            _buildLogList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogList() {
    if (_feedingLogs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Henüz kayıt yok.', textAlign: TextAlign.center),
      );
    }

    return Column(
      children: _feedingLogs.asMap().entries.map((entry) {
        final index = entry.key;
        final raw = entry.value;
        final parts = raw.split('|');

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Dismissible(
            key: ValueKey(raw),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              setState(() => _feedingLogs.removeAt(index));
              _saveLogs();
            },
            child: HistoryCard(
              title: parts[0],
              subtitle: parts.length > 1 ? parts[1] : '',
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: FeedingType.values.map((t) {
        return ChoiceChip(
          label: Text(t.label),
          selected: _selectedType == t,
          onSelected: (_) => setState(() => _selectedType = t),
        );
      }).toList(),
    );
  }

  Widget _buildMlSelector() {
    return Column(
      children: [
        Text(
          '${_mlValue.round()} ml',
          style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
        ),
        Slider(
          value: _mlValue,
          min: 0,
          max: 300,
          divisions: 30,
          onChanged: (v) => setState(() => _mlValue = v),
        ),
      ],
    );
  }

  Widget _buildSolidFoodInputs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _foodAmountController,
                decoration: const InputDecoration(labelText: 'Miktar'),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<SolidUnit>(
              value: _foodUnit,
              items: SolidUnit.values
                  .map((u) => DropdownMenuItem(value: u, child: Text(u.label)))
                  .toList(),
              onChanged: (v) => setState(() => _foodUnit = v!),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _foodNoteController,
          decoration: const InputDecoration(labelText: 'Not (opsiyonel)'),
        ),
      ],
    );
  }
}

enum FeedingType { breastMilk, formula, solid }

extension FeedingTypeX on FeedingType {
  String get label {
    switch (this) {
      case FeedingType.breastMilk:
        return 'Anne Sütü';
      case FeedingType.formula:
        return 'Mama';
      case FeedingType.solid:
        return 'Ek Gıda';
    }
  }
}

enum SolidUnit { gr, spoon, piece }

extension SolidUnitX on SolidUnit {
  String get label {
    switch (this) {
      case SolidUnit.gr:
        return 'gr';
      case SolidUnit.spoon:
        return 'kaşık';
      case SolidUnit.piece:
        return 'adet';
    }
  }
}
