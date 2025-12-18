import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_globals.dart';
import '../core/weight_formatter.dart';
import 'growth_controller.dart';
import 'growth_entry.dart';

class GrowthPage extends StatefulWidget {
  const GrowthPage({super.key});

  @override
  State<GrowthPage> createState() => _GrowthPageState();
}

class _GrowthPageState extends State<GrowthPage> {
  late final GrowthController _controller;

  final TextEditingController _weightGrCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = GrowthController();
    _init();
    _weightGrCtrl.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _init() async {
    await _controller.load();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _weightGrCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = appThemeColor.value;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gelişim'),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [mainColor.withValues(alpha: 0.10), cs.surface],
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_loading) {
              return const Center(child: CircularProgressIndicator());
            }

            final entries = _controller.entries;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _inputCard(context, mainColor),
                const SizedBox(height: 14),
                _sectionTitle(context, 'Geçmiş Ölçümler'),
                const SizedBox(height: 8),
                if (entries.isEmpty)
                  _emptyState(context)
                else
                  ...entries.map((e) => _entryTile(context, e)).toList(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _inputCard(BuildContext context, Color mainColor) {
    final cs = Theme.of(context).colorScheme;

    final parsedGr = int.tryParse(_weightGrCtrl.text.trim());
    final previewKg = (parsedGr != null && parsedGr > 0)
        ? WeightFormatter.format(parsedGr) // ✅ burada düzeldi
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Kilo (g)'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightGrCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*([.,]\d{0,3})?$'),
                    ),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Örn: 3250',
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Tarih seç',
                onPressed: () => _pickDate(context),
                icon: const Icon(Icons.calendar_month),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (previewKg != null)
            Text(
              '≈ $previewKg',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              'Gram gir (tek kaynak). Gösterimde kg otomatik hesaplanır.',
              style: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.90),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: mainColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _saveEntry,
              child: const Text(
                'Kaydet',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _entryTile(BuildContext context, GrowthEntry e) {
    final cs = Theme.of(context).colorScheme;

    final kgText = WeightFormatter.format(e.weightGr); // ✅ burada düzeldi
    final dateText = _formatDateTr(e.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primary.withValues(alpha: 0.12),
          child: Icon(Icons.monitor_weight, color: cs.primary),
        ),
        title: Text(
          '${e.weightGr} g',
          style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface),
        ),
        subtitle: Text(
          '$kgText • $dateText',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        trailing: IconButton(
          tooltip: 'Sil',
          icon: Icon(Icons.delete_outline, color: cs.onSurfaceVariant),
          onPressed: () => _confirmDelete(e),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.show_chart, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Henüz ölçüm yok. İlk kaydı üstten ekleyebilirsin.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: cs.onSurface.withValues(alpha: 0.90),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _saveEntry() async {
    final text = _weightGrCtrl.text.trim();
    final gr = int.tryParse(text);

    if (gr == null || gr <= 0) {
      _snack('Lütfen gram olarak geçerli bir değer gir.');
      return;
    }

    if (gr < 500 || gr > 30000) {
      _snack('Değer çok uç görünüyor. Eminsen kaydedebilirsin.');
    }

    final entry = GrowthEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      ),
      weightGr: gr,
    );

    await _controller.add(entry);
    _weightGrCtrl.clear();
    _snack('Kaydedildi');
  }

  Future<void> _confirmDelete(GrowthEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Silinsin mi?'),
        content: Text('${e.weightGr} g kaydı silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    await _controller.deleteById(e.id);
    _snack('Silindi');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDateTr(DateTime dt) {
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
    final d = dt.day.toString().padLeft(2, '0');
    final m = months[dt.month - 1];
    final y = dt.year.toString();
    return '$d $m $y';
  }
}
