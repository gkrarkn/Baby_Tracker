import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'core/notification_service.dart';
import 'core/app_globals.dart';
import 'pages/settings_page.dart';
import 'theme/theme_controller.dart';
import 'pages/sleep_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.initialize();
  await NotificationService.instance.init();

  final prefs = await SharedPreferences.getInstance();
  final savedGender = prefs.getString('gender');

  if (savedGender == 'girl') {
    appThemeColor.value = Colors.pink.shade200;
  } else if (savedGender == 'boy') {
    appThemeColor.value = Colors.blue;
  } else {
    appThemeColor.value = Colors.deepPurple;
  }

  runApp(const BabyTrackerApp());
}

class BabyTrackerApp extends StatefulWidget {
  const BabyTrackerApp({super.key});

  @override
  State<BabyTrackerApp> createState() => _BabyTrackerAppState();
}

class _BabyTrackerAppState extends State<BabyTrackerApp> {
  late final ThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = ThemeController(seedColor: appThemeColor);
    _themeController.load();
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

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

        return AnimatedBuilder(
          animation: _themeController,
          builder: (context, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Bebek Takip',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: _themeController.mode,
              home: DashboardPage(themeController: _themeController),
            );
          },
        );
      },
    );
  }
}

// --- ANA MENÜ (DASHBOARD) ---
class DashboardPage extends StatefulWidget {
  final ThemeController themeController;
  const DashboardPage({super.key, required this.themeController});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  BannerAd? _bannerAd;
  bool _isBannerReady = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: 'ca-app-pub-3940256099942544/2934735716', // iOS TEST
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerReady = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner error: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = appThemeColor.value;

    final bannerHeight = (_isBannerReady && _bannerAd != null)
        ? _bannerAd!.size.height.toDouble()
        : 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Bebek Takip 🐣'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SettingsPage(themeController: widget.themeController),
                ),
              );
            },
          ),
        ],
      ),

      // ✅ Grid yukarıda Expanded, banner altta ayrı alan
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: mainColor.withValues(alpha: 0.1),
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
                            color: mainColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.child_care,
                            size: 40,
                            color: mainColor,
                          ),
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
                        _buildMenuCard(
                          context,
                          Icons.bedtime,
                          "Uyku",
                          mainColor,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SleepPage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          context,
                          Icons.restaurant,
                          "Beslenme",
                          Colors.orange,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FeedingPage(),
                            ),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          Icons.medical_services,
                          "Aşı & İlaç",
                          Colors.red,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VaccinePage(),
                            ),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          Icons.show_chart,
                          "Gelişim",
                          Colors.teal,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GrowthPage(),
                            ),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          Icons.music_note,
                          "Ninniler",
                          Colors.purpleAccent,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LullabyPage(),
                            ),
                          ),
                        ),

                        _buildMenuCard(
                          context,
                          Icons.note_alt,
                          "Notlar",
                          const Color(0xFF6D8A8F),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotesPage(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ Banner her zaman en altta, grid'i "kesmez"
          if (bannerHeight > 0)
            SafeArea(
              top: false,
              child: SizedBox(
                height: bannerHeight,
                width: double.infinity,
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
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
              color: Colors.grey.withValues(alpha: 0.1),
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
  void initState() {
    super.initState();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleSound(String fileName) async {
    try {
      if (_playingFile == fileName) {
        await _audioPlayer.setReleaseMode(ReleaseMode.stop);
        await _audioPlayer.stop();
        setState(() => _playingFile = null);
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.play(AssetSource('audio/$fileName'));
        setState(() => _playingFile = fileName);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ses dosyası bulunamadı!')));
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
    if (_weightController.text.isEmpty || _heightController.text.isEmpty)
      return;

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
                value == 'HEADER_OPTIONAL')
              return;
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

  // ✅ BURADA
  String getCurrentDate() {
    final now = DateTime.now();
    return "${now.day}.${now.month}.${now.year}";
  }

  int getTodayTotalMl() {
    final today = getCurrentDate();
    int total = 0;

    for (final log in feedingLogs) {
      final parts = log.split('|');
      if (parts.length < 2) continue;

      if (parts[1].startsWith(today)) {
        final match = RegExp(r'(\d+)\s?ml').firstMatch(parts[0]);
        if (match != null) {
          total += int.parse(match.group(1)!);
        }
      }
    }
    return total;
  }

  int getTodayCount() {
    final today = getCurrentDate();
    return feedingLogs.where((log) {
      final parts = log.split('|');
      return parts.length > 1 && parts[1].startsWith(today);
    }).length;
  }

  DateTime? _parseLogDateTime(String raw) {
    // raw: "7.12.2025 - 03:32"
    try {
      final parts = raw.split(' - ');
      if (parts.length != 2) return null;

      final d = parts[0].split('.');
      final t = parts[1].split(':');
      if (d.length != 3 || t.length != 2) return null;

      final day = int.parse(d[0]);
      final month = int.parse(d[1]);
      final year = int.parse(d[2]);
      final hour = int.parse(t[0]);
      final minute = int.parse(t[1]);

      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return "Şimdi";
    if (diff.inMinutes < 60) return "${diff.inMinutes} dk önce";
    if (diff.inHours < 24) return "${diff.inHours} saat önce";
    return "${diff.inDays} gün önce";
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => feedingLogs = prefs.getStringList('feedingLogs') ?? []);
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('feedingLogs', feedingLogs);
  }

  void _saveFeeding() {
    setState(() {
      final amount = "${_currentSliderValue.round()} ml";
      final timeStamp = getCurrentDateTime();
      final icon = _selectedType == "Anne Sütü" ? "❤️" : "🍼";
      feedingLogs.insert(0, "$icon $_selectedType - $amount|$timeStamp");
      _saveLogs();
    });
  }

  Future<void> _clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('feedingLogs');
    setState(() => feedingLogs.clear());
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
                setState(() => _currentSliderValue = value);
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

            const SizedBox(height: 8),

            // ✅ Mini özet
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text("🍼", style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Bugün toplam: ${getTodayTotalMl()} ml",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "❤️ ${getTodayCount()} beslenme",
                    style: TextStyle(color: Colors.grey.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                itemCount: feedingLogs.length,
                itemBuilder: (context, index) {
                  final parts = feedingLogs[index].split('|');
                  return Card(
                    color: Colors.orange.shade50,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      leading: const Icon(
                        Icons.restaurant_menu,
                        color: Colors.orange,
                      ),
                      title: Text(parts[0]),
                      subtitle: Builder(
                        builder: (_) {
                          final raw = parts.length > 1 ? parts[1] : "";
                          final dt = _parseLogDateTime(raw);
                          if (dt == null) return Text(raw);

                          return Text(
                            "${_timeAgo(dt)}  •  ${raw.split(' - ').last}",
                          );
                        },
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

  Widget _buildTypeButton(String type, IconData icon) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
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
  } // _buildTypeButton bitti
} // ✅ _FeedingPageState bitti (BU EKSİKTİ)

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
    final jsonNotes = prefs.getString('notes');
    if (jsonNotes != null) {
      final List decoded = jsonDecode(jsonNotes);
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
        backgroundColor: appThemeColor.value.withValues(alpha: 0.85),
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
                  backgroundColor: appThemeColor.value.withValues(alpha: 0.9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: notes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                ),
                itemBuilder: (context, index) {
                  final note = notes[index];

                  return Dismissible(
                    key: ValueKey('${note['date']}_$index'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      final removed = notes[index];
                      final removedIndex = index;

                      _deleteNote(index);

                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Not silindi"),
                          action: SnackBarAction(
                            label: "Geri al",
                            onPressed: () {
                              setState(() {
                                notes.insert(removedIndex, removed);
                              });
                              _saveNotes();
                            },
                          ),
                        ),
                      );
                    },
                    child: _NoteCard(
                      text: note['text'] ?? '',
                      date: note['date'] ?? '',
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

class _NoteCard extends StatelessWidget {
  final String text;
  final String date;

  const _NoteCard({required this.text, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              date,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blueGrey.withValues(alpha: 0.95),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.fade,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
