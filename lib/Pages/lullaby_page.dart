// lib/pages/lullaby_page.dart
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
  Timer? _sleepTimer;
  Duration? _remaining;

  final List<_LullabyTrack> _tracks = const [
    _LullabyTrack(
      title: 'Beyaz Gürültü',
      assetFile: 'white_noise.ogg',
      icon: Icons.graphic_eq_rounded,
      bgColor: Color(0xFFE3F2FD),
      iconColor: Color(0xFF1E88E5),
    ),
    _LullabyTrack(
      title: 'Yağmur Sesi',
      assetFile: 'rain.ogg',
      icon: Icons.water_drop_rounded,
      bgColor: Color(0xFFE1F5FE),
      iconColor: Color(0xFF039BE5),
    ),
    _LullabyTrack(
      title: 'Klasik Ninni',
      assetFile: 'brahms_lullaby.ogg',
      icon: Icons.music_note_rounded,
      bgColor: Color(0xFFEDE7F6),
      iconColor: Color(0xFF7E57C2),
    ),
    _LullabyTrack(
      title: 'Süpürge Sesi',
      assetFile: 'vacuum.ogg',
      icon: Icons.cleaning_services_rounded,
      bgColor: Color(0xFFE0F2F1),
      iconColor: Color(0xFF26A69A),
    ),
    _LullabyTrack(
      title: 'Şömine Sesi',
      assetFile: 'fireplace.ogg',
      icon: Icons.local_fire_department_rounded,
      bgColor: Color(0xFFFFE0B2),
      iconColor: Color(0xFFEF6C00),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _player.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(_LullabyTrack track) async {
    final sameTrack = _currentFile == track.assetFile;

    if (sameTrack && _isPlaying) {
      await _player.pause();
      if (!mounted) return;
      setState(() => _isPlaying = false);
      return;
    }

    await _player.stop();
    await _player.play(AssetSource('audio/${track.assetFile}'));

    if (!mounted) return;
    setState(() {
      _currentFile = track.assetFile;
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

  String get _timerLabel {
    final r = _remaining;
    if (r == null) return 'Kapalı';
    final mm = r.inMinutes;
    final ss = r.inSeconds % 60;
    if (mm > 0) return '${mm}dk';
    return '${ss}s';
  }

  void _startSleepTimerMinutes(int minutes) {
    _sleepTimer?.cancel();

    if (minutes == 0) {
      setState(() => _remaining = null);
      return;
    }

    setState(() => _remaining = Duration(minutes: minutes));

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) return;

      final r = _remaining;
      if (r == null) {
        t.cancel();
        return;
      }

      final next = r - const Duration(seconds: 1);

      if (next.inSeconds <= 0) {
        t.cancel();
        setState(() => _remaining = null);
        await _stopPlayback();
        return;
      }

      setState(() => _remaining = next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = appThemeColor.value;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const PageAppBarTitle(
          title: 'Müzik Kutusu',
          icon: Icons.queue_music_rounded,
        ),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: _sleepMode ? 'Uyku modu açık' : 'Uyku modu kapalı',
            icon: Icon(
              _sleepMode ? Icons.dark_mode_rounded : Icons.dark_mode_outlined,
            ),
            onPressed: () => setState(() => _sleepMode = !_sleepMode),
          ),
          PopupMenuButton<int>(
            tooltip: 'Otomatik kapanma',
            onSelected: _startSleepTimerMinutes,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 15, child: Text('15 dk')),
              PopupMenuItem(value: 30, child: Text('30 dk')),
              PopupMenuItem(value: 60, child: Text('60 dk')),
              PopupMenuDivider(),
              PopupMenuItem(value: 0, child: Text('Timer kapat')),
            ],
            child: Padding(
              padding: const EdgeInsets.only(left: 6, right: 12),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    _timerLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800),
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
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16 + 96),
            itemCount: _tracks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final track = _tracks[index];
              final isActive = _currentFile == track.assetFile && _isPlaying;

              final activeBg = Color.alphaBlend(
                mainColor.withValues(alpha: 0.10),
                Theme.of(context).cardColor,
              );
              final cardBg = isActive ? activeBg : Theme.of(context).cardColor;
              final borderColor = isActive
                  ? mainColor.withValues(alpha: 0.28)
                  : Colors.black12;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: isActive ? 10 : 6,
                      offset: const Offset(0, 2),
                      color: Colors.black.withValues(
                        alpha: isActive ? 0.10 : 0.08,
                      ),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _togglePlay(track),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          _IconBubble(
                            icon: track.icon,
                            bgColor: track.bgColor,
                            iconColor: track.iconColor,
                            isActive: isActive,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              track.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isActive ? Icons.pause_circle : Icons.play_circle,
                            size: 38,
                            color: isActive ? mainColor : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (_sleepMode)
            IgnorePointer(
              child: Container(color: Colors.black.withValues(alpha: 0.55)),
            ),
        ],
      ),
    );
  }
}

class _LullabyTrack {
  final String title;
  final String assetFile;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const _LullabyTrack({
    required this.title,
    required this.assetFile,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });
}

class _IconBubble extends StatefulWidget {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final bool isActive;

  const _IconBubble({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.isActive,
  });

  @override
  State<_IconBubble> createState() => _IconBubbleState();
}

class _IconBubbleState extends State<_IconBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scale = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

    if (widget.isActive) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _IconBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _c.repeat(reverse: true);
      } else {
        _c.stop();
        _c.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(widget.icon, color: widget.iconColor, size: 22),
    );

    if (!widget.isActive) return child;
    return ScaleTransition(scale: _scale, child: child);
  }
}
