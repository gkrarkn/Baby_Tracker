// lib/pages/sleep_page.dart
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/notification_service.dart';
import '../core/app_globals.dart'; // appThemeColor + getCurrentDateTime

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

  // Hatırlatma saati
  TimeOfDay? _reminderTime;

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
        final String timeStamp = getCurrentDateTime();
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

  // --- Hatırlatma saati seçici + planlama ---
  Future<void> _pickReminderTime() async {
    final initialTime = _reminderTime ?? TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null) return;

    setState(() {
      _reminderTime = picked;
    });

    // Günlük bildirim planla
    await NotificationService.instance.scheduleDailySleepReminder(picked);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Her gün ${picked.format(context)} için uyku hatırlatması ayarlandı.",
        ),
      ),
    );
  }

  // --- UI HELPER: Son uyku kartı datası ---
  String? get _lastSleepDuration {
    if (sleepLogs.isEmpty) return null;
    final parts = sleepLogs.first.split('|');
    if (parts.isEmpty) return null;
    // "😴 Uyku: 02:14:32"
    return parts[0].replaceFirst("😴 ", "");
  }

  String? get _lastSleepDateTime {
    if (sleepLogs.isEmpty) return null;
    final parts = sleepLogs.first.split('|');
    if (parts.length < 2) return null;
    return parts[1];
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = appThemeColor.value;
    final Color softBg = mainColor.withOpacity(0.06);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Uyku Takibi 🌙"),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.alarm),
            tooltip: 'Uyku hatırlatması ayarla',
            onPressed: _pickReminderTime,
          ),
          IconButton(
            onPressed: _clearLogs,
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: "Tüm kayıtları temizle",
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [softBg, Theme.of(context).colorScheme.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // --- SON UYKU KARTI ---
              _buildLastSleepCard(mainColor),

              // --- AKTİF TIMER KARTI ---
              _buildTimerCard(mainColor),

              const SizedBox(height: 24),

              // --- BAŞLIK: GEÇMİŞ UYKULAR ---
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Geçmiş Uykular",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // --- LİSTE ---
              Expanded(
                child: sleepLogs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: sleepLogs.length,
                        itemBuilder: (context, index) {
                          final parts = sleepLogs[index].split('|');
                          final title = parts[0];
                          final date = parts.length > 1 ? parts[1] : "";
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: mainColor.withOpacity(0.15),
                                child: Icon(
                                  Icons.nightlight_round,
                                  color: mainColor,
                                ),
                              ),
                              title: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                date,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Uyku / uyanıklık ikonunu üreten helper ---
  Widget _buildStateIcon() {
    if (isSleeping) {
      // Uyku modunda SVG ikon
      return SvgPicture.asset(
        'assets/icons/sleep_zzz.svg', // dosya yolu
        width: 90,
        height: 90,
      );
    } else {
      // Uyanık modunda güneş ikonu
      return const Icon(Icons.wb_sunny, size: 80, color: Colors.orange);
    }
  }

  // --- Widget: Son Uyku Kartı ---
  Widget _buildLastSleepCard(Color mainColor) {
    if (_lastSleepDuration == null || _lastSleepDateTime == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: mainColor.withOpacity(0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: mainColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.nightlight_round, color: mainColor, size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Henüz kayıt yok",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "İlk uykuyu kaydetmek için aşağıdaki butonu kullan.",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: mainColor.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cloud, color: mainColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Son Uyku",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  _lastSleepDuration!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _lastSleepDateTime!,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget: Timer Kartı ve Buton ---
  Widget _buildTimerCard(Color mainColor) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: mainColor.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // İkon
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSleeping
                  ? mainColor.withOpacity(0.12)
                  : Colors.orange.withOpacity(0.12),
            ),
            child: _buildStateIcon(),
          ),

          const SizedBox(height: 20),

          // Durum etiketi
          Text(
            isSleeping ? "Miniğin şu anda uyuyor" : "Miniğin şu anda uyanık",
            style: TextStyle(
              fontSize: 15,
              color: isSleeping ? mainColor : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 14),

          // Süre
          Text(
            elapsedTime,
            style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 28),

          // Buton – tam genişlik
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _toggleSleep,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: isSleeping ? Colors.redAccent : Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              icon: Icon(isSleeping ? Icons.stop : Icons.play_arrow),
              label: Text(
                isSleeping ? "UYAN" : "UYUT",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget: Boş liste durumu ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_queue, color: Colors.grey.shade400, size: 64),
          const SizedBox(height: 10),
          const Text(
            "Henüz uyku kaydı yok",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            "İlk uyku kaydını başlatmak için\n\"UYUT\" butonuna dokun.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
