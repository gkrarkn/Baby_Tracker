import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../widgets/page_appbar_title.dart';
import '../core/app_globals.dart';
import '../ads/anchored_adaptive_banner.dart';

class LullabyPage extends StatefulWidget {
  const LullabyPage({super.key});

  @override
  State<LullabyPage> createState() => _LullabyPageState();
}

class _LullabyPageState extends State<LullabyPage> {
  final AudioPlayer _player = AudioPlayer();

  String? _currentFile;
  bool _isPlaying = false;

  bool _sleepMode = false;
  double _volume = 0.8;

  Timer? _sleepTimer;
  Timer? _fadeTimer;
  Duration? _remaining;

  final List<_LullabyTrack> _tracks = const [
    _LullabyTrack(
      title: 'Beyaz Gürültü',
      fileBase: 'white_noise',
      icon: Icons.graphic_eq_rounded,
      bgColor: Color(0xFFE3F2FD),
      iconColor: Color(0xFF1E88E5),
    ),
    _LullabyTrack(
      title: 'Yağmur Sesi',
      fileBase: 'rain',
      icon: Icons.water_drop_rounded,
      bgColor: Color(0xFFE1F5FE),
      iconColor: Color(0xFF039BE5),
    ),
    _LullabyTrack(
      title: 'Dalga Sesi',
      fileBase: 'waves',
      icon: Icons.waves_rounded,
      bgColor: Color(0xFFE0F7FA),
      iconColor: Color(0xFF00838F),
    ),
    _LullabyTrack(
      title: 'Rüzgar Sesi',
      fileBase: 'brown_noise',
      icon: Icons.air_rounded,
      bgColor: Color(0xFFE8F5E9),
      iconColor: Color(0xFF43A047),
    ),
    _LullabyTrack(
      title: 'Anne Kalp Atışı',
      fileBase: 'heartbeat_mother',
      icon: Icons.favorite_rounded,
      bgColor: Color(0xFFFCE4EC),
      iconColor: Color(0xFFD81B60),
    ),
    _LullabyTrack(
      title: 'Klasik Ninni',
      fileBase: 'brahms_lullaby',
      icon: Icons.music_note_rounded,
      bgColor: Color(0xFFEDE7F6),
      iconColor: Color(0xFF7E57C2),
    ),
    _LullabyTrack(
      title: 'Süpürge Sesi',
      fileBase: 'vacuum',
      icon: Icons.cleaning_services_rounded,
      bgColor: Color(0xFFE0F2F1),
      iconColor: Color(0xFF26A69A),
    ),
    _LullabyTrack(
      title: 'Şömine Sesi',
      fileBase: 'fireplace',
      icon: Icons.local_fire_department_rounded,
      bgColor: Color(0xFFFFE0B2),
      iconColor: Color(0xFFEF6C00),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _player.setReleaseMode(ReleaseMode.loop);
    _player.setVolume(_volume);
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _fadeTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(_LullabyTrack track) async {
    final file = '${track.fileBase}.m4a';
    final same = _currentFile == file;

    if (same && _isPlaying) {
      await _player.pause();
      if (!mounted) return;
      setState(() => _isPlaying = false);
      return;
    }

    await _player.stop();
    await _player.setVolume(_volume);
    await _player.play(AssetSource('audio/$file'));

    if (!mounted) return;
    setState(() {
      _currentFile = file;
      _isPlaying = true;
    });
  }

  Future<void> _stopPlayback() async {
    await _player.stop();
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _currentFile = null;
    });
  }

  // ---------------------------------------------------------------------------
  // TIMER
  // ---------------------------------------------------------------------------

  void _startSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    _fadeTimer?.cancel();

    if (minutes <= 0) {
      setState(() => _remaining = null);
      return;
    }

    setState(() => _remaining = Duration(minutes: minutes));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Zamanlayıcı başladı · Müzik devam eder, ekranı kilitleyebilirsiniz 🌙',
        ),
        duration: Duration(seconds: 3),
      ),
    );

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted || _remaining == null) return;

      final next = _remaining! - const Duration(seconds: 1);
      setState(() => _remaining = next);

      if (next.inSeconds == 10) {
        _startFadeOut();
      }

      if (next.inSeconds <= 0) {
        t.cancel();
        setState(() => _remaining = null);
        await _stopPlayback();
      }
    });
  }

  void _startFadeOut() {
    _fadeTimer?.cancel();

    const steps = 10;
    final stepVolume = _volume / steps;
    var current = _volume;

    _fadeTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      current -= stepVolume;
      if (current <= 0) {
        _player.setVolume(0);
        t.cancel();
      } else {
        _player.setVolume(current);
      }
    });
  }

  String get _timerLabel {
    if (_remaining == null) return 'Kapalı';
    final m = _remaining!.inMinutes;
    return '${m}dk';
  }

  // ---------------------------------------------------------------------------
  // CUSTOM TIMER DIALOG
  // ---------------------------------------------------------------------------

  Future<void> _openCustomTimerDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Süre seç'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Dakika',
              hintText: 'Örn: 30',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value == null || value < 1 || value > 180) return;
                Navigator.pop(ctx, value);
              },
              child: const Text('Başlat'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      _startSleepTimer(result);
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final mainColor = appThemeColor.value;

    return Scaffold(
      appBar: AppBar(
        title: const PageAppBarTitle(
          title: 'Müzik Kutusu',
          icon: Icons.queue_music_rounded,
        ),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Gece modu',
            icon: Icon(
              _sleepMode ? Icons.dark_mode_rounded : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              setState(() => _sleepMode = !_sleepMode);
              if (_sleepMode) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Gece modu açık · Müzik devam eder, ekranı kilitleyebilirsiniz 🌙',
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
          PopupMenuButton<int>(
            onSelected: (v) {
              if (v == -1) {
                _openCustomTimerDialog();
              } else {
                _startSleepTimer(v);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 20, child: Text('20 dk')),
              PopupMenuItem(value: 40, child: Text('40 dk')),
              PopupMenuItem(value: 60, child: Text('60 dk')),
              PopupMenuDivider(),
              PopupMenuItem(value: -1, child: Text('Özel süre…')),
              PopupMenuDivider(),
              PopupMenuItem(value: 0, child: Text('Timer kapat')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    _timerLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AnchoredAdaptiveBanner(),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              _buildVolumeSlider(),
              const SizedBox(height: 12),
              ..._tracks.map(_buildTrackTile),
            ],
          ),
          if (_sleepMode)
            IgnorePointer(
              child: Container(color: Colors.black.withOpacity(0.55)),
            ),
        ],
      ),
    );
  }

  Widget _buildVolumeSlider() {
    return Row(
      children: [
        const Icon(Icons.volume_down),
        Expanded(
          child: Slider(
            value: _volume,
            min: 0,
            max: 1,
            onChanged: (v) {
              setState(() => _volume = v);
              _player.setVolume(v);
            },
          ),
        ),
        const Icon(Icons.volume_up),
      ],
    );
  }

  Widget _buildTrackTile(_LullabyTrack track) {
    final active =
        _currentFile?.startsWith(track.fileBase) == true && _isPlaying;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: track.bgColor,
          child: Icon(track.icon, color: track.iconColor),
        ),
        title: Text(
          track.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: Icon(
          active ? Icons.pause_circle : Icons.play_circle,
          size: 36,
        ),
        onTap: () => _togglePlay(track),
      ),
    );
  }
}

class _LullabyTrack {
  final String title;
  final String fileBase;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const _LullabyTrack({
    required this.title,
    required this.fileBase,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });
}
