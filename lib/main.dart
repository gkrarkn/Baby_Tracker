import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // KLAVYE KONTROLÜ
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart'; // HAFIZA
import 'package:audioplayers/audioplayers.dart'; // MÜZİK
import 'package:fl_chart/fl_chart.dart'; // GRAFİK
import 'dart:convert'; // Notları JSON olarak saklamak için
// Tarih formatı için

// Canlı Tema Rengi
ValueNotifier<Color> appThemeColor = ValueNotifier(Colors.deepPurple);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  String? savedGender = prefs.getString('gender');

  if (savedGender == 'girl') {
    appThemeColor.value = Colors.pink.shade200; // Soft Pembe
  } else if (savedGender == 'boy') {
    appThemeColor.value = Colors.blue;
  } else {
    appThemeColor.value = Colors.deepPurple;
  }

  runApp(const BabyTrackerApp());
}

class BabyTrackerApp extends StatelessWidget {
  const BabyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: appThemeColor,
      builder: (context, color, child) {
        final lightTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: color,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: color,
            foregroundColor: Colors.white,
            centerTitle: true,
            titleTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        );

        final darkTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: color,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: color,
            foregroundColor: Colors.white,
            centerTitle: true,
            titleTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Bebek Takip',
          theme: lightTheme,
          darkTheme: darkTheme,
          // Cihaz ayarına göre otomatik light/dark
          themeMode: ThemeMode.system,
          home: const DashboardPage(),
        );
      },
    );
  }
}

String getCurrentDateTime() {
  DateTime now = DateTime.now();
  String date = "${now.day}.${now.month}.${now.year}";
  String time =
      "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  return "$date - $time";
}

// --- ANA MENÜ (DASHBOARD) ---
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  void _showGenderSettings() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 250,
          child: Column(
            children: [
              const Text(
                "Bebeğin Cinsiyeti",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildGenderOption(
                "Kız Bebek",
                Icons.female,
                Colors.pink.shade200,
                'girl',
              ),
              _buildGenderOption("Erkek Bebek", Icons.male, Colors.blue, 'boy'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenderOption(
    String title,
    IconData icon,
    Color color,
    String key,
  ) {
    return ListTile(
      leading: Icon(icon, color: color, size: 30),
      title: Text(title, style: const TextStyle(fontSize: 18)),
      onTap: () async {
        appThemeColor.value = color;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('gender', key);
        if (mounted) Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color mainColor = appThemeColor.value;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Bebek Takip 🐣'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showGenderSettings,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: mainColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: mainColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.child_care, size: 40, color: mainColor),
                  ),
                  const SizedBox(width: 15),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hoşgeldin!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Miniğin bugün nasıl?",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildMenuCard(context, Icons.bedtime, "Uyku", mainColor, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SleepPage(),
                      ),
                    );
                  }),
                  _buildMenuCard(
                    context,
                    Icons.restaurant,
                    "Beslenme",
                    Colors.orange,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FeedingPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context,
                    Icons.medical_services,
                    "Aşı & İlaç",
                    Colors.red,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VaccinePage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context,
                    Icons.show_chart,
                    "Gelişim",
                    Colors.teal,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GrowthPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context,
                    Icons.music_note,
                    "Ninniler",
                    Colors.purpleAccent,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LullabyPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context,
                    Icons.note_alt,
                    "Notlar",
                    const Color(0xFF6D8A8F), // SOFT PASTEL RENK
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotesPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// --- NİNNİLER SAYFASI (LOCAL MP3 - FINAL) 🎵 ---
class LullabyPage extends StatefulWidget {
  const LullabyPage({super.key});
  @override
  State<LullabyPage> createState() => _LullabyPageState();
}

class _LullabyPageState extends State<LullabyPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingFile;

  final List<Map<String, String>> _sounds = [
    {'title': 'Beyaz Gürültü', 'file': 'white_noise.mp3'},
    {'title': 'Süpürge Sesi', 'file': 'vacuum.mp3'},
    {'title': 'Sakinleştirici Yağmur', 'file': 'rain.mp3'},
    {'title': 'Brahms Ninnisi', 'file': 'brahms_lullaby.mp3'},
  ];

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleSound(String fileName) async {
    try {
      if (_playingFile == fileName) {
        await _audioPlayer.stop();
        setState(() {
          _playingFile = null;
        });
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.play(AssetSource('assets/audio/$fileName'));
        setState(() {
          _playingFile = fileName;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ses dosyası bulunamadı!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Ninniler 🎵"),
        backgroundColor: Colors.purpleAccent.shade100,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.headset, size: 100, color: Colors.purpleAccent),
            const SizedBox(height: 20),
            const Text(
              "Bebeğin için sakinleştirici sesler",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: _sounds.length,
                itemBuilder: (context, index) {
                  final sound = _sounds[index];
                  final isPlaying = _playingFile == sound['file'];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPlaying
                            ? Colors.purpleAccent
                            : Colors.grey.shade200,
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: isPlaying ? Colors.white : Colors.black,
                        ),
                      ),
                      title: Text(
                        sound['title']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPlaying ? Colors.purpleAccent : Colors.black,
                        ),
                      ),
                      trailing: isPlaying
                          ? const Icon(
                              Icons.graphic_eq,
                              color: Colors.purpleAccent,
                            )
                          : null,
                      onTap: () => _toggleSound(sound['file']!),
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
}

// --- GELİŞİM SAYFASI 📈 ---

class _GrowthSample {
  final double weight;
  final double height;
  final String label; // örn: 29.11.2025

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

    String weight = _weightController.text.replaceAll(',', '.');
    String height = _heightController.text.replaceAll(',', '.');
    String head = _headController.text.replaceAll(',', '.');
    String timeStamp = getCurrentDateTime();

    String entryText = "⚖️ $weight kg  -  📏 $height cm";
    if (head.isNotEmpty) {
      entryText += "\n🧢 Baş Çevresi: $head cm";
    }
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
    setState(() {
      growthLogs.clear();
    });
  }

  // LOG’lardaki kg / cm değerlerini grafik için parse eden yapı
  List<_GrowthSample> _parseGrowthSamples() {
    final regexWeight = RegExp(r'⚖️\s*([\d.,]+)\s*kg');
    final regexHeight = RegExp(r'📏\s*([\d.,]+)\s*cm');

    final List<_GrowthSample> samples = [];

    // En eski kaydı solda görmek için tersten okuyup listeye ekliyoruz
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

      // Etiket olarak kısaltılmış tarih (30.11.25) kullan
      String label;
      final datePart = rawDate.split(' - ').first; // "30.11.2025" gibi
      final pieces = datePart.split('.'); // ["30","11","2025"]

      if (pieces.length == 3) {
        final day = pieces[0];
        final month = pieces[1];
        final year = pieces[2];
        final shortYear = year.length >= 2
            ? year.substring(year.length - 2)
            : year;
        label = "$day.$month.$shortYear"; // 30.11.25
      } else {
        label = datePart; // parse edemezse olduğu gibi bırak
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
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title ($unit)",
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
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
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
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

                        if (index % step != 0) {
                          return const SizedBox.shrink();
                        }

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
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.12),
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
    // Grafik için data hazırlığı
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
              // Giriş alanları
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

              // GRAFİKLER
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

              // Liste – tek scroll
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: growthLogs.length,
                itemBuilder: (context, index) {
                  List<String> parts = growthLogs[index].split('|');
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

// --- SAĞLIK SAYFASI ---
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

  // Zorunlu aşılar
  final List<String> _mandatoryVaccines = [
    'Hepatit A',
    'Hepatit B',
    'BCG (Verem)',
    '5\'li Karma',
    'KPA (Zatürre)',
    'KKK (Kızamık)',
    'Su Çiçeği',
  ];

  // Opsiyonel / özel aşılar
  final List<String> _optionalVaccines = [
    'Rota (Rotavirüs)',
    'Menenjit B',
    'Menenjit ACWY',
    'Grip Aşısı',
    'Hepatit E',
    'HPV',
  ];

  // Genel bilgi notları
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
    setState(() {
      vaccineLogs = prefs.getStringList('vaccineLogs') ?? [];
    });
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('vaccineLogs', vaccineLogs);
  }

  void _saveEntry() {
    String entry = "";
    String timeStamp = getCurrentDateTime();

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
    setState(() {
      vaccineLogs.clear();
    });
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
            // Aşı / İlaç seçim butonları
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTypeButton("Aşı", Icons.vaccines),
                const SizedBox(width: 20),
                _buildTypeButton("İlaç/Vitamin", Icons.medication),
              ],
            ),
            const SizedBox(height: 30),

            // Aşı seçimi veya ilaç girişi
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

            // Kaydet butonu
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

            // Geçmiş liste
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

  // Zorunlu / Opsiyonel başlıkları olan dropdown
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
            // Başlık satırına tıklanırsa seçim yapma
            if (value == null ||
                value == 'HEADER_MANDATORY' ||
                value == 'HEADER_OPTIONAL') {
              return;
            }
            setState(() {
              _selectedVaccine = value;
            });
          },
        ),
      ),
    );
  }

  // Seçilen aşı için bilgi kartı
  Widget _buildVaccineInfoCard() {
    if (_selectedVaccine == null) return const SizedBox.shrink();

    final bool isMandatory = _mandatoryVaccines.contains(_selectedVaccine);
    final String groupLabel = isMandatory
        ? 'Zorunlu Aşı'
        : 'Opsiyonel / Özel Aşı';

    final String info =
        _vaccineInfo[_selectedVaccine] ??
        'Bu aşı hakkında detaylı takvim ve uygulama bilgisi için çocuk doktorunuza danışın.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
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
    final bool isSelected = _selectedType == type;
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

// --- UYKU SAYFASI ---
class SleepPage extends StatefulWidget {
  const SleepPage({super.key});
  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  bool isSleeping = false;
  final Stopwatch stopwatch = Stopwatch();
  Timer? timer; // nullable
  String elapsedTime = "00:00:00";
  List<String> sleepLogs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      sleepLogs = prefs.getStringList('sleepLogs') ?? [];
    });
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('sleepLogs', sleepLogs);
  }

  void _startTimer() {
    // varsa eski timer'ı iptal et
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        elapsedTime = _formatTime(stopwatch.elapsedMilliseconds);
      });
    });
  }

  String _formatTime(int milliseconds) {
    int seconds = (milliseconds / 1000).truncate();
    int minutes = (seconds / 60).truncate();
    int hours = (minutes / 60).truncate();
    return "${hours.toString().padLeft(2, '0')}:"
        "${minutes.toString().padLeft(2, '0')}:"
        "${seconds.toString().padLeft(2, '0')}";
  }

  void _toggleSleep() {
    setState(() {
      if (isSleeping) {
        // Uyku bitişi
        stopwatch.stop();
        timer?.cancel();
        String timeStamp = getCurrentDateTime();
        sleepLogs.insert(0, "😴 Uyku: $elapsedTime|$timeStamp");
        _saveLogs();
        stopwatch.reset();
        elapsedTime = "00:00:00";
      } else {
        // Uyku başlangıcı
        stopwatch.start();
        _startTimer();
      }
      isSleeping = !isSleeping;
    });
  }

  Future<void> _clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sleepLogs');
    setState(() {
      sleepLogs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Uyku Takibi 🌙"),
        backgroundColor: appThemeColor.value,
        actions: [
          IconButton(
            onPressed: _clearLogs,
            icon: const Icon(Icons.delete_outline, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          Icon(
            isSleeping ? Icons.bedtime : Icons.wb_sunny,
            size: 80,
            color: isSleeping ? appThemeColor.value : Colors.orange,
          ),
          const SizedBox(height: 20),
          Text(
            elapsedTime,
            style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _toggleSleep,
            icon: Icon(isSleeping ? Icons.stop : Icons.play_arrow),
            label: Text(isSleeping ? "UYAN" : "UYUT"),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSleeping ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const Divider(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: sleepLogs.length,
              itemBuilder: (context, index) {
                List<String> parts = sleepLogs[index].split('|');
                return ListTile(
                  leading: Icon(Icons.history, color: appThemeColor.value),
                  title: Text(parts[0]),
                  subtitle: Text(parts.length > 1 ? parts[1] : ""),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- BESLENME SAYFASI ---
class FeedingPage extends StatefulWidget {
  const FeedingPage({super.key});
  @override
  State<FeedingPage> createState() => _FeedingPageState();
}

class _FeedingPageState extends State<FeedingPage> {
  double _currentSliderValue = 90;
  String _selectedType = "Mama";
  List<String> feedingLogs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
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
    setState(() {
      String amount = "${_currentSliderValue.round()} ml";
      String timeStamp = getCurrentDateTime();
      feedingLogs.insert(0, "🍼 $_selectedType - $amount|$timeStamp");
      _saveLogs();
    });
  }

  Future<void> _clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('feedingLogs');
    setState(() {
      feedingLogs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Beslenme Takibi 🍼"),
        backgroundColor: Colors.orange,
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
                _buildTypeButton("Mama", Icons.rice_bowl),
                const SizedBox(width: 20),
                _buildTypeButton("Anne Sütü", Icons.favorite),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              "${_currentSliderValue.round()} ml",
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const Text("Miktar Seçiniz", style: TextStyle(color: Colors.grey)),
            Slider(
              value: _currentSliderValue,
              min: 0,
              max: 250,
              divisions: 25,
              activeColor: Colors.orange,
              label: _currentSliderValue.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _currentSliderValue = value;
                });
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveFeeding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
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
                "Son Beslenmeler",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: feedingLogs.length,
                itemBuilder: (context, index) {
                  List<String> parts = feedingLogs[index].split('|');
                  return Card(
                    color: Colors.orange.shade50,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      leading: const Icon(
                        Icons.restaurant_menu,
                        color: Colors.orange,
                      ),
                      title: Text(
                        parts[0],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(parts.length > 1 ? parts[1] : ""),
                      trailing: const Icon(Icons.check, color: Colors.green),
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

  Widget _buildTypeButton(String type, IconData icon) {
    bool isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.grey.shade200,
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

// --- NOTLAR SAYFASI 📝 ---
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Map<String, String>> notes = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonNotes = prefs.getString('notes');
    if (jsonNotes != null) {
      List decoded = jsonDecode(jsonNotes);
      setState(() {
        notes = decoded.map((e) => Map<String, String>.from(e)).toList();
      });
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notes', jsonEncode(notes));
  }

  void _addNote() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      notes.insert(0, {
        'text': _controller.text.trim(),
        'date': getCurrentDateTime(),
      });
      _controller.clear();
      _saveNotes();
    });
  }

  void _deleteNote(int index) {
    setState(() {
      notes.removeAt(index);
      _saveNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Notlar 📝"),
        backgroundColor: appThemeColor.value.withOpacity(0.85),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Bir not ekleyin...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                onPressed: _addNote,
                icon: const Icon(Icons.add, size: 22),
                label: const Text(
                  "EKLE",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appThemeColor.value.withOpacity(0.9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      title: Text(
                        note['text']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        note['date']!,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteNote(index),
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
}

// KOD SONU
