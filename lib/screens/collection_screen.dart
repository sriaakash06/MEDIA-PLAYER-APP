import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../models/song_model.dart';
import '../widgets/album_art_widget.dart';
import '../widgets/mini_player.dart';
import 'player_screen.dart';

class CollectionScreen extends StatelessWidget {
  final String title;
  final List<Song> songs;

  const CollectionScreen({super.key, required this.title, required this.songs});

  String _fmt(int ms) {
    final d = Duration(milliseconds: ms);
    return '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  void _openPlayer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const PlayerScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A063A),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: songs.isEmpty
                ? Center(
                    child: Text('No songs in $title',
                        style: const TextStyle(color: Colors.white54, fontSize: 16)),
                  )
                : Consumer<AudioProvider>(
                    builder: (context, audio, _) {
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          final isPlaying = audio.currentSong?.id == song.id;
                          return InkWell(
                            onTap: () {
                              final idx = audio.songs.indexWhere((s) => s.id == song.id);
                              if (idx != -1) {
                                audio.playFromLibrary(song); // Will queue all and play song
                              }
                              _openPlayer(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: isPlaying
                                  ? BoxDecoration(
                                      color: const Color(0xFF7C4DFF).withOpacity(0.08),
                                      border: const Border(
                                        left: BorderSide(color: Color(0xFF7C4DFF), width: 3),
                                      ),
                                    )
                                  : null,
                              child: Row(
                                children: [
                                  AlbumArtWidget(songId: song.id, size: 52, borderRadius: 10),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          song.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isPlaying ? const Color(0xFF7C4DFF) : Colors.white,
                                            fontSize: 14.5,
                                            fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          song.artist,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white38, fontSize: 12.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _fmt(song.duration),
                                    style: const TextStyle(color: Colors.white24, fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}
