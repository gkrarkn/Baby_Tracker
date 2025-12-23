// lib/pages/feeding_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:baby_tracker/core/app_globals.dart';
import 'package:baby_tracker/recipes/widgets/recipes_section.dart';
import '../ads/anchored_adaptive_banner.dart';

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

  bool _isPremium = false;

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
    final logs = prefs.getStringList(_prefsKey) ?? const <String>[];
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

        final entry =
            "🥣 Ek Gıda - $amount ${_foodUnit.label}$noteText|$timestamp";

        _foodAmountController.clear();
        _foodNoteController.clear();
        return entry;
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
    final totalMl = _todayTotalMl();
    final solidCount = _todaySolidCount();

    return Container(
      width: double.infinity,
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
                  'Toplam: $totalMl ml  •  Ek gıda: $solidCount',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _babyMonthsFromBirth(DateTime birthDate) {
    final now = DateTime.now();
    int months =
        (now.year - birthDate.year) * 12 + (now.month - birthDate.month);
    if (now.day < birthDate.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  void _openRecipesSheet({required int babyMonths, required Color accent}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.restaurant_menu, color: accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tarifler • $babyMonths. ay',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Kapat'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: RecipesSection(
                      babyMonths: babyMonths,
                      isPremium: _isPremium,
                      onUpgradeTap: _showPremiumSheet,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecipesCtaCard({
    required int babyMonths,
    required Color accent,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openRecipesSheet(babyMonths: babyMonths, accent: accent),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.28),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bebeğiniz İçin Pratik Tarifler',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$babyMonths. ay • Ek gıdaya uygun 16 tarif',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.65),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 27,
              color: Colors.blueGrey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  void _showPremiumSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Premium',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Tüm tarifler\n'
                '• Yaşa göre akıllı öneriler\n'
                '• Yeni içerikler',
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isPremium = true);
                  Navigator.pop(context);
                },
                child: const Text('Premium’u Aç (Debug)'),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _isPremium = false);
                  Navigator.pop(context);
                },
                child: const Text('Premium’u Kapat (Debug)'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = appThemeColor.value;

    // TODO: later bind to real baby profile
    final babyBirthDate = DateTime(2024, 11, 18);
    final babyMonths = _babyMonthsFromBirth(babyBirthDate);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Beslenme 🍽️'),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _clearAll,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Tümünü sil',
          ),
        ],
      ),
      bottomNavigationBar: const AnchoredAdaptiveBanner(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                // ✅ anchored banner için ekstra alt boşluk
                96 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTypeSelector(),
                    const SizedBox(height: 12),
                    _buildTodaySummaryCard(Colors.orange),
                    const SizedBox(height: 16),
                    if (_selectedType == FeedingType.solid) ...[
                      _buildRecipesCtaCard(
                        babyMonths: babyMonths,
                        accent: mainColor,
                      ),
                      const SizedBox(height: 12),
                      _buildSolidFoodInputs(),
                    ] else ...[
                      _buildMlSelector(),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _saveFeeding,
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'KAYDET',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Geçmiş Beslenmeler',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLogList(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: FeedingType.values.map((t) {
        final selected = _selectedType == t;
        return ChoiceChip(
          label: Text(t.label),
          selected: selected,
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
          label: _mlValue.round().toString(),
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Miktar',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<SolidUnit>(
              value: _foodUnit,
              items: SolidUnit.values
                  .map((u) => DropdownMenuItem(value: u, child: Text(u.label)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _foodUnit = v);
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _foodNoteController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Not (opsiyonel)',
            hintText: 'örn: yoğurt + muz',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildLogList() {
    if (_feedingLogs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Henüz kayıt yok.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _feedingLogs.length,
      itemBuilder: (context, index) {
        final log = _feedingLogs[index];
        final parts = log.split('|');

        return Dismissible(
          key: ValueKey(log),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            final removed = _feedingLogs[index];
            setState(() => _feedingLogs.removeAt(index));
            _saveLogs();

            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Beslenme silindi'),
                action: SnackBarAction(
                  label: 'Geri al',
                  onPressed: () {
                    final insertIndex = index.clamp(0, _feedingLogs.length);
                    setState(() => _feedingLogs.insert(insertIndex, removed));
                    _saveLogs();
                  },
                ),
              ),
            );
          },
          child: Card(
            child: ListTile(
              title: Text(parts[0]),
              subtitle: parts.length > 1 ? Text(parts[1]) : null,
            ),
          ),
        );
      },
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
