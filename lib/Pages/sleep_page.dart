import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_globals.dart';
import '../core/notification_service.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  static const _kSleepLogsKey = 'sleepLogs';

  bool _isSleeping = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _elapsed = "00:00:00";

  List<String> _sleepLogs = [];

  TimeOfDay? _reminderTime;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sleepLogs = prefs.getStringList(_kSleepLogsKey) ?? [];
    });
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kSleepLogsKey, _sleepLogs);
  }

  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed = _formatTime(_stopwatch.elapsedMilliseconds));
    });
  }

  String _formatTime(int ms) {
    final totalSeconds = (ms / 1000).floor();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return "${hours.toString().padLeft(2, '0')}:"
        "${minutes.toString().padLeft(2, '0')}:"
        "${seconds.toString().padLeft(2, '0')}";
  }

  void _toggleSleep() {
    if (_isSleeping) {
      // stop
      _stopwatch.stop();
      _timer?.cancel();

      final stamp = getCurrentDateTime();
      // Emoji basmıyoruz; log formatı: "Uyku - 00:00:00|dd.mm.yyyy - HH:mm"
      final entry = "Uyku - $_elapsed|$stamp";

      setState(() {
        _sleepLogs.insert(0, entry);
        _elapsed = "00:00:00";
        _isSleeping = false;
      });

      _stopwatch.reset();
      _saveLogs();
      return;
    }

    // start
    setState(() => _isSleeping = true);
    _stopwatch.start();
    _startTicking();
  }

  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSleepLogsKey);
    setState(() => _sleepLogs.clear());
  }

  Future<void> _pickReminderTime() async {
    final initial = _reminderTime ?? TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;

    setState(() => _reminderTime = picked);

    await NotificationService.instance.scheduleDailySleepReminder(picked);

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Her gün ${picked.format(context)} için uyku hatırlatması ayarlandı.",
        ),
      ),
    );
  }

  // ---- Derived UI data ----
  String? get _lastTitle {
    if (_sleepLogs.isEmpty) return null;
    final parts = _sleepLogs.first.split('|');
    if (parts.isEmpty) return null;

    // Eski formatta emoji varsa temizle (geriye dönük uyumluluk)
    final t = parts[0].trim();
    return t.replaceAll(RegExp(r'^[^\wÇĞİÖŞÜçğıöşü]+'), '').trim();
  }

  String? get _lastStamp {
    if (_sleepLogs.isEmpty) return null;
    final parts = _sleepLogs.first.split('|');
    if (parts.length < 2) return null;
    return parts[1].trim();
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = appThemeColor.value;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Uyku Takibi"),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _pickReminderTime,
            icon: const Icon(Icons.alarm),
            tooltip: 'Uyku hatırlatması',
          ),
          IconButton(
            onPressed: _clearAll,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Tüm kayıtları sil',
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildTopInfo(mainColor),
                  const SizedBox(height: 12),
                  _buildTimerCard(mainColor),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        "Geçmiş Uykular",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const Spacer(),
                      if (_reminderTime != null)
                        _pill(
                          icon: Icons.notifications_active_outlined,
                          text: _reminderTime!.format(context),
                          color: mainColor,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ]),
              ),
            ),

            if (_sleepLogs.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    "Henüz uyku kaydı yok.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final raw = _sleepLogs[index];
                    final parts = raw.split('|');
                    final title = (parts.isNotEmpty ? parts[0] : '').trim();
                    final stamp = (parts.length > 1 ? parts[1] : '').trim();

                    return Dismissible(
                      key: ValueKey('$raw$index'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        final removed = _sleepLogs[index];
                        setState(() => _sleepLogs.removeAt(index));
                        await _saveLogs();

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Uyku kaydı silindi"),
                            action: SnackBarAction(
                              label: "Geri al",
                              onPressed: () async {
                                setState(
                                  () => _sleepLogs.insert(index, removed),
                                );
                                await _saveLogs();
                              },
                            ),
                          ),
                        );
                      },
                      child: _logCard(
                        mainColor: mainColor,
                        title: title
                            .replaceAll(RegExp(r'^[^\wÇĞİÖŞÜçğıöşü]+'), '')
                            .trim(),
                        subtitle: stamp,
                      ),
                    );
                  }, childCount: _sleepLogs.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---- UI components ----

  Widget _buildTopInfo(Color mainColor) {
    final title = _lastTitle;
    final stamp = _lastStamp;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: mainColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mainColor.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: mainColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.nightlight_round, color: mainColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title == null ? "Son uyku" : "Son uyku",
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  title ?? "Henüz kayıt yok. Aşağıdan başlatabilirsiniz.",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (stamp != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    stamp,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard(Color mainColor) {
    final accent = _isSleeping ? mainColor : Colors.orange;
    final stateText = _isSleeping
        ? "Miniğin şu anda uyuyor"
        : "Miniğin şu anda uyanık";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isSleeping ? Icons.bedtime : Icons.wb_sunny_outlined,
              size: 44,
              color: accent,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            stateText,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _elapsed,
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _toggleSleep,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSleeping ? Colors.redAccent : Colors.green,
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(_isSleeping ? Icons.stop : Icons.play_arrow),
              label: Text(
                _isSleeping ? "UYAN" : "UYUT",
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logCard({
    required Color mainColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: mainColor.withValues(alpha: 0.14),
          child: Icon(Icons.nightlight_round, color: mainColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }

  Widget _pill({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
