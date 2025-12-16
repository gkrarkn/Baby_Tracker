import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../core/app_globals.dart';

class LullabyPage extends StatefulWidget {
  const LullabyPage({super.key});

  @override
  State<LullabyPage> createState() => _LullabyPageState();
}

class _LullabyPageState extends State<LullabyPage> {
  final AudioPlayer _player = AudioPlayer();

  String? _currentFile; // örn: 'rain.mp3'
  bool _isPlaying = false;

  final List<_LullabyTrack> _tracks = const [
    _LullabyTrack(
      title: 'Beyaz Gürültü',
      assetFile: 'white_noise.mp3',
      emoji: '🌊',
    ),
    _LullabyTrack(title: 'Yağmur Sesi', assetFile: 'rain.mp3', emoji: '🌧️'),
    _LullabyTrack(
      title: 'Brahms Ninnisi',
      assetFile: 'brahms_lullaby.mp3',
      emoji: '🎶',
    ),
    _LullabyTrack(title: 'Süpürge Sesi', assetFile: 'vacuum.mp3', emoji: '🧹'),
  ];

  @override
  void initState() {
    super.initState();
    _player.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(_LullabyTrack track) async {
    final sameTrack = _currentFile == track.assetFile;

    if (sameTrack && _isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }

    await _player.stop();
    await _player.play(AssetSource('audio/${track.assetFile}'));

    setState(() {
      _currentFile = track.assetFile;
      _isPlaying = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = appThemeColor.value;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Ninniler 🎵'),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tracks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final track = _tracks[index];
          final isActive = _currentFile == track.assetFile && _isPlaying;

          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: Text(track.emoji, style: const TextStyle(fontSize: 28)),
              title: Text(
                track.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: Icon(
                isActive ? Icons.pause_circle : Icons.play_circle,
                size: 36,
                color: isActive ? mainColor : Colors.grey,
              ),
              onTap: () => _togglePlay(track),
            ),
          );
        },
      ),
    );
  }
}

class _LullabyTrack {
  final String title;
  final String assetFile; // sadece dosya adı
  final String emoji;

  const _LullabyTrack({
    required this.title,
    required this.assetFile,
    required this.emoji,
  });
}
