import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_globals.dart'; // appThemeColor + getCurrentDateTime()

class VaccinePage extends StatefulWidget {
  const VaccinePage({super.key});

  @override
  State<VaccinePage> createState() => _VaccinePageState();
}

class _VaccinePageState extends State<VaccinePage> {
  String _selectedType = "Aşı";
  String? _selectedVaccine;
  final TextEditingController _medicineController = TextEditingController();
  List<String> vaccineLogs = [];

  final List<String> _mandatoryVaccines = [
    'Hepatit A',
    'Hepatit B',
    'BCG (Verem)',
    '5\'li Karma',
    'KPA (Zatürre)',
    'KKK (Kızamık)',
    'Su Çiçeği',
  ];

  final List<String> _optionalVaccines = [
    'Rota (Rotavirüs)',
    'Menenjit B',
    'Menenjit ACWY',
    'Grip Aşısı',
    'Hepatit E',
    'HPV',
  ];

  final Map<String, String> _vaccineInfo = {
    'Hepatit A':
        'Rutin çocukluk aşı programında yer alan bir aşıdır. Kesin zamanlama için çocuk doktorunuza göre planlayınız.',
    'Hepatit B':
        'Doğumdan itibaren uygulanan temel aşılar arasındadır. Kesin zamanlama için çocuk doktorunuzla birlikte değerlendirme yapın.',
    'BCG (Verem)':
        'Verem hastalığına karşı koruma sağlar. Genellikle erken dönemde uygulanır. Kesin uygulama zamanını çocuk doktorunuz belirlemelidir.',
    '5\'li Karma':
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

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => vaccineLogs = prefs.getStringList('vaccineLogs') ?? []);
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('vaccineLogs', vaccineLogs);
  }

  void _saveEntry() {
    String entry = "";
    final timeStamp = getCurrentDateTime();

    if (_selectedType == "Aşı") {
      if (_selectedVaccine == null) return;
      entry = "💉 $_selectedVaccine|$timeStamp";
    } else {
      final text = _medicineController.text.trim();
      if (text.isEmpty) return;
      entry = "💊 $text|$timeStamp";
      _medicineController.clear();
    }

    setState(() => vaccineLogs.insert(0, entry));
    _saveLogs();
  }

  Future<void> _clearLogs() async {
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
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('vaccineLogs');
    setState(() => vaccineLogs.clear());
  }

  void _deleteLogWithUndo(int index) {
    final removed = vaccineLogs[index];

    setState(() => vaccineLogs.removeAt(index));
    _saveLogs();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('İşlem silindi'),
        action: SnackBarAction(
          label: 'Geri al',
          onPressed: () {
            setState(() => vaccineLogs.insert(index, removed));
            _saveLogs();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ValueListenableBuilder<Color>(
      valueListenable: appThemeColor,
      builder: (context, mainColor, _) {
        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            title: const Text("Sağlık Takibi 🏥"),
            backgroundColor: mainColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: _clearLogs,
                icon: const Icon(Icons.delete_outline),
                tooltip: "Tüm kayıtları sil",
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
                  _typeSelector(context, mainColor),
                  const SizedBox(height: 14),

                  if (_selectedType == "Aşı")
                    Column(
                      children: [
                        _surfaceCard(
                          context,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                _buildVaccineDropdown(mainColor),
                                _buildVaccineInfoCard(mainColor),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    _surfaceCard(
                      context,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: TextField(
                          controller: _medicineController,
                          decoration: InputDecoration(
                            hintText: "İlaç veya vitamin adı yaz...",
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
                        "KAYDET",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  _sectionTitle(context, "Geçmiş İşlemler"),
                  const SizedBox(height: 10),

                  if (vaccineLogs.isEmpty)
                    _emptyState(context)
                  else
                    ...List.generate(vaccineLogs.length, (index) {
                      final parts = vaccineLogs[index].split('|');
                      final title = parts[0];
                      final date = parts.length > 1 ? parts[1] : "";

                      return Dismissible(
                        key: ValueKey('${vaccineLogs[index]}_$index'),
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
                        onDismissed: (_) => _deleteLogWithUndo(index),
                        child: _logTile(
                          context,
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

  // ---------------------------
  // UI blocks
  // ---------------------------

  Widget _typeSelector(BuildContext context, Color mainColor) {
    final cs = Theme.of(context).colorScheme;

    return _surfaceCard(
      context,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: _typeChip(
                context,
                label: "Aşı",
                icon: Icons.vaccines,
                selected: _selectedType == "Aşı",
                mainColor: mainColor,
                cs: cs,
                onTap: () => setState(() {
                  _selectedType = "Aşı";
                  _selectedVaccine = null;
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _typeChip(
                context,
                label: "İlaç/Vitamin",
                icon: Icons.medication,
                selected: _selectedType == "İlaç/Vitamin",
                mainColor: mainColor,
                cs: cs,
                onTap: () => setState(() {
                  _selectedType = "İlaç/Vitamin";
                  _selectedVaccine = null;
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(
    BuildContext context, {
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
              : cs.surfaceVariant.withValues(alpha: 0.55),
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

  Widget _logTile(
    BuildContext context, {
    required Color mainColor,
    required String title,
    required String date,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isVaccine = title.contains("💉");

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
          Icon(Icons.info_outline, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Henüz işlem yok.",
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

  static Widget _surfaceCard(BuildContext context, {required Widget child}) {
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

  // ---------------------------
  // Vaccine blocks
  // ---------------------------

  Widget _buildVaccineDropdown(Color mainColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: mainColor.withValues(alpha: 0.65)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Text("Hangi aşı yapıldı?"),
          value: _selectedVaccine,
          items: [
            const DropdownMenuItem<String>(
              value: 'HEADER_MANDATORY',
              enabled: false,
              child: Text(
                'Zorunlu Aşılar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ..._mandatoryVaccines.map(
              (v) => DropdownMenuItem<String>(value: v, child: Text(v)),
            ),
            const DropdownMenuItem<String>(
              value: 'HEADER_OPTIONAL',
              enabled: false,
              child: Text(
                'Opsiyonel / Özel Aşılar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ..._optionalVaccines.map(
              (v) => DropdownMenuItem<String>(value: v, child: Text(v)),
            ),
          ],
          onChanged: (value) {
            if (value == null ||
                value == 'HEADER_MANDATORY' ||
                value == 'HEADER_OPTIONAL') {
              return;
            }
            setState(() => _selectedVaccine = value);
          },
        ),
      ),
    );
  }

  Widget _buildVaccineInfoCard(Color mainColor) {
    if (_selectedVaccine == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    final isMandatory = _mandatoryVaccines.contains(_selectedVaccine);
    final groupLabel = isMandatory ? 'Zorunlu Aşı' : 'Opsiyonel / Özel Aşı';

    final info =
        _vaccineInfo[_selectedVaccine] ??
        'Bu aşı hakkında detaylı takvim ve uygulama bilgisi için çocuk doktorunuza danışın.';

    // Daha “sakin” ton: alert hissi yerine nötr bilgi kartı
    final bg = cs.surfaceVariant.withValues(alpha: 0.35);
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
            "Not: Uygulama resmi aşı takvimi veya tıbbi tavsiye yerine geçmez. "
            "Aşı zamanlamasını mutlaka çocuk doktorunuzla birlikte planlayın.",
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
