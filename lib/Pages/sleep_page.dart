// lib/pages/sleep_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart'; // appThemeColor ve getCurrentDateTime için

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
