// lib/pages/vaccine_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/page_appbar_title.dart';

import '../core/app_globals.dart'; // appThemeColor + getCurrentDateTime()

class VaccinePage extends StatefulWidget {
  const VaccinePage({super.key});

  @override
  State<VaccinePage> createState() => _VaccinePageState();
}

class _VaccinePageState extends State<VaccinePage> {
  // -----------------------------
  // Keys / constants
  // -----------------------------
  static const String _kLogsKey = 'healthLogs';
  static const String _kTypeVaccine = 'Aşı';
  static const String _kTypeMed = 'İlaç/Vitamin';

  static const String _tagVaccine = '💉 '; // MUST end with space
  static const String _tagMed = '💊 '; // MUST end with space

  // -----------------------------
  // State
  // -----------------------------
  String _selectedType = _kTypeVaccine;
  String? _selectedVaccine;
  final TextEditingController _medicineController = TextEditingController();

  List<String> _logs = []; // stored as: "<TAG><TITLE>|<timestamp>"

  // -----------------------------
  // Data sources
  // -----------------------------
  final List<String> _mandatoryVaccines = const [
    'Hepatit A',
    'Hepatit B',
    'BCG (Verem)',
    "5'li Karma",
    'KPA (Zatürre)',
    'KKK (Kızamık)',
    'Su Çiçeği',
  ];

  final List<String> _optionalVaccines = const [
    'Rota (Rotavirüs)',
    'Menenjit B',
    'Menenjit ACWY',
    'Grip Aşısı',
    'Hepatit E',
    'HPV',
  ];

  final Map<String, String> _vaccineInfo = const {
    'Hepatit A':
        'Rutin çocukluk aşı programında yer alan bir aşıdır. Kesin zamanlama için çocuk doktorunuza göre planlayınız.',
    'Hepatit B':
        'Doğumdan itibaren uygulanan temel aşılar arasındadır. Kesin zamanlama için çocuk doktorunuzla birlikte değerlendirme yapın.',
    'BCG (Verem)':
        'Verem hastalığına karşı koruma sağlar. Genellikle erken dönemde uygulanır. Kesin uygulama zamanını çocuk doktorunuz belirlemelidir.',
    "5'li Karma":
        'Difteri, tetanoz, boğmaca, polio ve Hib’e karşı koruma sağlar. Rutin aşılardandır. Doz aralıkları için doktorunuza danışın.',
    'KPA (Zatürre)':
        'Pnömokok enfeksiyonlarına karşı koruyucu bir aşıdır. Rutin çocukluk aşı takviminde yer alır. Kesin zamanlama doktor kontrolünde planlanmalıdır.',
    'KKK (Kızamık)':
        'Kızamık, kızamıkçık ve kabakulak hastalıklarına karşı korur. Zamanlama çocuğun yaşına göre netleşir. Doktorunuzdan yaşa uygun planlamayı alınız.',
    'Su Çiçeği':
        'Su çiçeği enfeksiyonuna karşı koruma sağlar. Rutin takvimde yer alan bir aşıdır. Uygulama aralığı doktor tarafından netleştirilmelidir.',
    'Rota (Rotavirüs)':
        'Rotavirüs ishallerine karşı koruma sağlar. Erken aylarda belirli aralıklarla uygulanır. Doz zamanlaması için çocuk doktorunuza danışın.',
    'Menenjit B':
        'Meningokok B bakterisine karşı koruma sağlar. Ülkeden ülkeye takvimi değişebilir. Uygulama kararını çocuk doktorunuzla birlikte veriniz.',
    'Menenjit ACWY':
        'A, C, W ve Y tipi meningokoklara karşı korur. Özellikle riskli bölgeler ve seyahatlerde önerilir. Zamanlama doktor tarafından belirlenmelidir.',
    'Grip Aşısı':
        'Mevsimsel gripten korunma sağlar. 6 ay üzeri çocuklarda uygulanabilir. Çocuğunuzun sağlık durumuna göre doktorunuz uygun zamanı belirler.',
    'Hepatit E':
        'Hepatit E virüsüne karşı koruma sağlar. Rutin takvimde yer almaz, risk durumuna göre uygulanır. Kararı çocuk doktorunuz vermelidir.',
    'HPV':
        'Human Papilloma Virus’a karşı korur. Ergenlik dönemi için önerilen bir aşıdır. Uygun yaş ve doz planlaması için çocuk doktorunuza danışınız.',
  };

  // -----------------------------
  // Lifecycle
  // -----------------------------
  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _medicineController.dispose();
    super.dispose();
  }

  // -----------------------------
  // Persistence
  // -----------------------------
  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = prefs.getStringList(_kLogsKey) ?? [];
    if (!mounted) return;
    setState(() => _logs = loaded);
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kLogsKey, _logs);
  }

  // -----------------------------
  // Derived
  // -----------------------------
  bool get _isVaccineMode => _selectedType == _kTypeVaccine;

  List<String> get _filteredLogs {
    if (_logs.isEmpty) return const [];
    final prefix = _isVaccineMode ? _tagVaccine : _tagMed;
    return _logs.where((e) => e.startsWith(prefix)).toList();
  }

  // -----------------------------
  // Actions
  // -----------------------------
  void _saveEntry() {
    final timeStamp = getCurrentDateTime();

    if (_isVaccineMode) {
      if (_selectedVaccine == null) {
        _toast('Lütfen aşı seçin.');
        return;
      }
      final entry = '$_tagVaccine$_selectedVaccine|$timeStamp';
      setState(() => _logs.insert(0, entry));
      _saveLogs();
      return;
    }

    final text = _medicineController.text.trim();
    if (text.isEmpty) {
      _toast('Lütfen ilaç/vitamin adını yazın.');
      return;
    }

    final entry = '$_tagMed$text|$timeStamp';
    setState(() => _logs.insert(0, entry));
    _medicineController.clear();
    _saveLogs();
  }

  Future<void> _clearAllLogs() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tüm kayıtlar silinsin mi?'),
        content: const Text('Bu işlem geri alınamaz.'),
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
    if (ok != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLogsKey);

    if (!mounted) return;
    setState(() => _logs.clear());
  }

  void _deleteLogWithUndoByValue(String value) {
    final removeIndex = _logs.indexOf(value);
    if (removeIndex < 0) return;

    setState(() => _logs.removeAt(removeIndex));
    _saveLogs();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('İşlem silindi'),
        action: SnackBarAction(
          label: 'Geri al',
          onPressed: () {
            setState(() => _logs.insert(removeIndex, value));
            _saveLogs();
          },
        ),
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _switchType(String type) {
    setState(() {
      _selectedType = type;
      _selectedVaccine = null;
      // medicine text stays (user-friendly)
    });
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
          backgroundColor: cs.surface,
          appBar: AppBar(
            title: const PageAppBarTitle(
              title: 'Sağlık Takibi',
              icon: Icons.local_hospital_rounded,
            ),
            backgroundColor: mainColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: _clearAllLogs,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Tüm kayıtları sil',
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
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                children: [
                  _typeSelector(mainColor),
                  const SizedBox(height: 14),

                  if (_isVaccineMode)
                    _surfaceCard(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            _vaccineDropdown(mainColor),
                            _vaccineInfoCard(mainColor),
                          ],
                        ),
                      ),
                    )
                  else
                    _surfaceCard(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: TextField(
                          controller: _medicineController,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: 'İlaç veya vitamin adı yaz...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            prefixIcon: Icon(Icons.edit, color: mainColor),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saveEntry,
                      style: FilledButton.styleFrom(
                        backgroundColor: mainColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'KAYDET',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  _sectionTitle('Geçmiş İşlemler'),
                  const SizedBox(height: 10),

                  if (_filteredLogs.isEmpty)
                    _emptyStateForType()
                  else
                    ..._filteredLogs.map((value) {
                      final parts = value.split('|');
                      final title = parts.isNotEmpty ? parts[0] : value;
                      final date = parts.length > 1 ? parts[1] : '';

                      return Dismissible(
                        key: ValueKey(value),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: mainColor.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteLogWithUndoByValue(value),
                        child: _logTile(
                          mainColor: mainColor,
                          title: title,
                          date: date,
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _typeSelector(Color mainColor) {
    final cs = Theme.of(context).colorScheme;

    return _surfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: _typeChip(
                label: _kTypeVaccine,
                icon: Icons.vaccines,
                selected: _isVaccineMode,
                mainColor: mainColor,
                cs: cs,
                onTap: () => _switchType(_kTypeVaccine),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _typeChip(
                label: _kTypeMed,
                icon: Icons.medication,
                selected: !_isVaccineMode,
                mainColor: mainColor,
                cs: cs,
                onTap: () => _switchType(_kTypeMed),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required Color mainColor,
    required ColorScheme cs,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? mainColor
              : cs.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? mainColor.withValues(alpha: 0.55)
                : cs.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : cs.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logTile({
    required Color mainColor,
    required String title,
    required String date,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isVaccine = title.startsWith(_tagVaccine);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: mainColor.withValues(alpha: 0.12),
          child: Icon(
            isVaccine ? Icons.vaccines : Icons.medication,
            color: mainColor,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface),
        ),
        subtitle: Text(date, style: TextStyle(color: cs.onSurfaceVariant)),
        trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
      ),
    );
  }

  Widget _emptyStateForType() {
    final cs = Theme.of(context).colorScheme;
    final msg = _isVaccineMode
        ? 'Henüz aşı kaydı yok.'
        : 'Henüz ilaç/vitamin kaydı yok.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(msg, style: TextStyle(color: cs.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: cs.onSurface.withValues(alpha: 0.90),
      ),
    );
  }

  Widget _surfaceCard({required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
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
      child: child,
    );
  }

  // -----------------------------
  // Vaccine UI (Dropdown with headers)
  // - headers are FULL WIDTH, NO ICONS
  // - header texts do not truncate
  // -----------------------------
  Widget _vaccineDropdown(Color mainColor) {
    final cs = Theme.of(context).colorScheme;

    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem<String>(
        enabled: false,
        value: '__header_mandatory__',
        child: _dropdownHeader(text: 'Zorunlu Aşılar', cs: cs),
      ),
      ..._mandatoryVaccines.map(
        (v) => DropdownMenuItem<String>(value: v, child: Text(v)),
      ),
      DropdownMenuItem<String>(
        enabled: false,
        value: '__header_optional__',
        child: _dropdownHeader(text: 'Opsiyonel / Özel Aşılar', cs: cs),
      ),
      ..._optionalVaccines.map(
        (v) => DropdownMenuItem<String>(value: v, child: Text(v)),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: mainColor.withValues(alpha: 0.65)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Text('Hangi aşı yapıldı?'),
          value: _selectedVaccine,
          items: items,
          onChanged: (value) {
            if (value == null) return;
            if (value == '__header_mandatory__' ||
                value == '__header_optional__') {
              return;
            }
            setState(() => _selectedVaccine = value);
          },
        ),
      ),
    );
  }

  Widget _dropdownHeader({required String text, required ColorScheme cs}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.visible, // do not cut
        softWrap: false,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: cs.onSurface.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget _vaccineInfoCard(Color mainColor) {
    if (_selectedVaccine == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    final isMandatory = _mandatoryVaccines.contains(_selectedVaccine);
    final groupLabel = isMandatory ? 'Zorunlu Aşı' : 'Opsiyonel / Özel Aşı';

    final info =
        _vaccineInfo[_selectedVaccine] ??
        'Bu aşı hakkında detaylı takvim ve uygulama bilgisi için çocuk doktorunuza danışın.';

    final bg = cs.surfaceContainerHighest.withValues(alpha: 0.35);
    final border = mainColor.withValues(alpha: 0.35);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            groupLabel,
            style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            info,
            style: TextStyle(
              fontSize: 13,
              height: 1.25,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Not: Uygulama resmi aşı takvimi veya tıbbi tavsiye yerine geçmez. '
            'Aşı zamanlamasını mutlaka çocuk doktorunuzla birlikte planlayın.',
            style: TextStyle(
              fontSize: 11,
              height: 1.25,
              color: cs.onSurfaceVariant.withValues(alpha: 0.90),
            ),
          ),
        ],
      ),
    );
  }
}
