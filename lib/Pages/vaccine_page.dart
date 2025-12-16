import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_globals.dart';

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
      if (_medicineController.text.isEmpty) return;
      entry = "💊 ${_medicineController.text}|$timeStamp";
      _medicineController.clear();
    }

    setState(() {
      vaccineLogs.insert(0, entry);
      _saveLogs();
    });
  }

  Future<void> _clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('vaccineLogs');
    setState(() => vaccineLogs.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Sağlık Takibi 🏥"),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            onPressed: _clearLogs,
            icon: const Icon(Icons.delete_outline, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTypeButton("Aşı", Icons.vaccines),
                const SizedBox(width: 20),
                _buildTypeButton("İlaç/Vitamin", Icons.medication),
              ],
            ),
            const SizedBox(height: 30),
            if (_selectedType == "Aşı")
              Column(
                children: [_buildVaccineDropdown(), _buildVaccineInfoCard()],
              )
            else
              TextField(
                controller: _medicineController,
                decoration: InputDecoration(
                  hintText: "İlaç veya vitamin adı girin...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.edit, color: Colors.redAccent),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  "KAYDET",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Geçmiş İşlemler",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: vaccineLogs.length,
                itemBuilder: (context, index) {
                  final parts = vaccineLogs[index].split('|');
                  final title = parts[0];
                  final date = parts.length > 1 ? parts[1] : "";
                  return Card(
                    color: Colors.red.shade50,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      leading: Icon(
                        title.contains("💉")
                            ? Icons.vaccines
                            : Icons.medication,
                        color: Colors.red,
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        date,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaccineDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Text("Hangi aşı yapıldı?"),
          value: _selectedVaccine,
          items: [
            const DropdownMenuItem<String>(
              value: 'HEADER_MANDATORY',
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

  Widget _buildVaccineInfoCard() {
    if (_selectedVaccine == null) return const SizedBox.shrink();

    final isMandatory = _mandatoryVaccines.contains(_selectedVaccine);
    final groupLabel = isMandatory ? 'Zorunlu Aşı' : 'Opsiyonel / Özel Aşı';
    final info =
        _vaccineInfo[_selectedVaccine] ??
        'Bu aşı hakkında detaylı takvim ve uygulama bilgisi için çocuk doktorunuza danışın.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            groupLabel,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            info,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          const Text(
            "Not: Uygulama resmi aşı takvimi veya tıbbi tavsiye yerine geçmez. "
            "Aşı zamanlamasını mutlaka çocuk doktorunuzla birlikte planlayın.",
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String type, IconData icon) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedVaccine = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.redAccent : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 8),
            Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
