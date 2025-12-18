import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_globals.dart';

class FeedingPage extends StatefulWidget {
  const FeedingPage({super.key});

  @override
  State<FeedingPage> createState() => _FeedingPageState();
}

class _FeedingPageState extends State<FeedingPage> {
  String _selectedType = 'Mama';

  // Mama / Anne sütü
  double _mlValue = 90;

  // Ek gıda
  String _foodUnit = 'gr';
  final TextEditingController _foodAmountController = TextEditingController();
  final TextEditingController _foodNoteController = TextEditingController();

  List<String> feedingLogs = [];

  @override
  void initState() {
    super.initState();
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
    setState(() {
      feedingLogs = prefs.getStringList('feedingLogs') ?? [];
    });
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('feedingLogs', feedingLogs);
  }

  void _saveFeeding() {
    final timeStamp = getCurrentDateTime();
    String entry = '';

    if (_selectedType == 'Mama' || _selectedType == 'Anne Sütü') {
      final icon = _selectedType == 'Anne Sütü' ? '❤️' : '🍼';
      entry = "$icon $_selectedType - ${_mlValue.round()} ml|$timeStamp";
    }

    if (_selectedType == 'Ek Gıda') {
      final amount = _foodAmountController.text.trim();
      if (amount.isEmpty) return;

      final note = _foodNoteController.text.trim();
      final noteText = note.isEmpty ? '' : ' ($note)';

      entry = "🥣 Ek Gıda - $amount $_foodUnit$noteText|$timeStamp";

      _foodAmountController.clear();
      _foodNoteController.clear();
    }

    if (entry.isEmpty) return;

    setState(() {
      feedingLogs.insert(0, entry);
    });
    _saveLogs();
  }

  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('feedingLogs');
    setState(() => feedingLogs.clear());
  }

  // ---------- TODAY SUMMARY ----------
  String _todayKey() {
    final now = DateTime.now();
    return "${now.day}.${now.month}.${now.year}";
  }

  int _todayTotalMl() {
    final today = _todayKey();
    int total = 0;

    for (final log in feedingLogs) {
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

    for (final log in feedingLogs) {
      final parts = log.split('|');
      if (parts.length < 2) continue;
      if (!parts[1].startsWith(today)) continue;

      if (parts[0].startsWith("🥣 Ek Gıda")) count++;
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
                  "Bugün",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  "Toplam: $totalMl ml  •  Ek gıda: $solidCount",
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

  @override
  Widget build(BuildContext context) {
    final mainColor = appThemeColor.value;

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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTypeSelector(),
                    const SizedBox(height: 12),
                    _buildTodaySummaryCard(Colors.orange),
                    const SizedBox(height: 20),

                    if (_selectedType != 'Ek Gıda') _buildMlSelector(),
                    if (_selectedType == 'Ek Gıda') _buildSolidFoodInputs(),

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

  // ---------- UI PARTS ----------

  Widget _buildTypeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ['Anne Sütü', 'Mama', 'Ek Gıda'].map((type) {
        final selected = _selectedType == type;
        return ChoiceChip(
          label: Text(type),
          selected: selected,
          onSelected: (_) => setState(() => _selectedType = type),
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
            DropdownButton<String>(
              value: _foodUnit,
              items: const [
                DropdownMenuItem(value: 'gr', child: Text('gr')),
                DropdownMenuItem(value: 'kaşık', child: Text('kaşık')),
                DropdownMenuItem(value: 'adet', child: Text('adet')),
              ],
              onChanged: (v) => setState(() => _foodUnit = v!),
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
    if (feedingLogs.isEmpty) {
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
      itemCount: feedingLogs.length,
      itemBuilder: (context, index) {
        final log = feedingLogs[index];
        final parts = log.split('|');

        return Dismissible(
          key: ValueKey(log), // ✅ index bağımsız key
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            final removed = feedingLogs[index];
            setState(() => feedingLogs.removeAt(index));
            _saveLogs();

            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Beslenme silindi'),
                action: SnackBarAction(
                  label: 'Geri al',
                  onPressed: () {
                    final insertIndex = index.clamp(0, feedingLogs.length);
                    setState(() => feedingLogs.insert(insertIndex, removed));
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
