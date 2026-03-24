import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/album_art_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      body: Consumer<AudioProvider>(
        builder: (context, audio, _) {
          final song = audio.currentSong;

          return Stack(
            children: [
              // Background gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1A063A), Color(0xFF080818)],
                    stops: [0, 0.6],
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // ── Top bar ────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: Colors.white70, size: 32),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Text(
                              'Now Playing',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          // Placeholder for symmetry
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),

                    const Spacer(flex: 1),

                    // ── Album Art ──────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: song == null
                          ? _noSongArt()
                          : Container(
                              key: ValueKey(song.id),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C4DFF)
                                        .withOpacity(0.35),
                                    blurRadius: 40,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: AlbumArtWidget(
                                songId: song.id,
                                size: 280,
                                borderRadius: 28,
                              ),
                            ),
                    ),

                    const Spacer(flex: 1),

                    // ── Song Info ──────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(
                                    song?.title ?? 'No Song Selected',
                                    key: ValueKey(song?.id),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  song?.artist ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Seek Bar ───────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 16),
                              activeTrackColor: const Color(0xFF7C4DFF),
                              inactiveTrackColor: Colors.white12,
                              thumbColor: Colors.white,
                              overlayColor:
                                  const Color(0xFF7C4DFF).withOpacity(0.2),
                            ),
                            child: Slider(
                              value: audio.position.inMilliseconds
                                  .toDouble()
                                  .clamp(
                                      0,
                                      audio.duration.inMilliseconds > 0
                                          ? audio.duration.inMilliseconds
                                              .toDouble()
                                          : 1.0),
                              max: audio.duration.inMilliseconds > 0
                                  ? audio.duration.inMilliseconds.toDouble()
                                  : 1.0,
                              onChanged: (v) =>
                                  audio.seek(Duration(milliseconds: v.toInt())),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_fmt(audio.position),
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 12)),
                                Text(_fmt(audio.duration),
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Controls ────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Shuffle
                          _ControlIcon(
                            icon: Icons.shuffle_rounded,
                            isActive: audio.isShuffled,
                            size: 26,
                            onTap: audio.toggleShuffle,
                          ),
                          // Previous
                          IconButton(
                            icon: const Icon(Icons.skip_previous_rounded,
                                color: Colors.white, size: 40),
                            onPressed: audio.skipToPrevious,
                          ),
                          // Play / Pause
                          GestureDetector(
                            onTap: audio.togglePlay,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF8F5FFF), Color(0xFF5B20D8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        const Color(0xFF7C4DFF).withOpacity(0.5),
                                    blurRadius: 25,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  audio.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  key: ValueKey(audio.isPlaying),
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                          // Next
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded,
                                color: Colors.white, size: 40),
                            onPressed: audio.skipToNext,
                          ),
                          // Repeat
                          _RepeatIcon(
                            mode: audio.repeatMode,
                            onTap: audio.cycleRepeat,
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 1),

                    // ── Extra Controls (Fav, Delete, Share, More) ─────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              audio.isFavorite(song?.id)
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: audio.isFavorite(song?.id)
                                  ? Colors.redAccent
                                  : Colors.white70,
                            ),
                            onPressed: () {
                              if (song != null) audio.toggleFavorite(song.id);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.white70),
                            onPressed: () => _handleDelete(context, audio, song),
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_outlined,
                                color: Colors.white70),
                            onPressed: () {
                              if (song?.data != null) {
                                Share.shareXFiles([XFile(song!.data!)],
                                    text: 'Listen to ${song.title}');
                              }
                            },
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded,
                                color: Colors.white70),
                            color: const Color(0xFF2C1F6E),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            onSelected: (value) {
                              if (value == 'sleep') {
                                _showSleepTimerDialog(context, audio);
                              } else if (value == 'playlist') {
                                if (song != null) {
                                  _showAddToPlaylistDialog(context, audio, song);
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'sleep',
                                child: Row(
                                  children: [
                                    Icon(Icons.timer_outlined, color: Colors.white70),
                                    SizedBox(width: 12),
                                    Text('Sleep Timer', style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'playlist',
                                child: Row(
                                  children: [
                                    Icon(Icons.playlist_add_rounded, color: Colors.white70),
                                    SizedBox(width: 12),
                                    Text('Add to Playlist', style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _noSongArt() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C1F6E), Color(0xFF0A0A1A)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Icon(Icons.music_note_rounded,
          color: Colors.white12, size: 100),
    );
  }

  void _showSleepTimerDialog(BuildContext context, AudioProvider audio) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1240),
        title: const Text('Sleep Timer', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (audio.isSleepTimerActive)
              ListTile(
                title: Text('Active: ${audio.remainingSleepTime?.inMinutes}:${(audio.remainingSleepTime?.inSeconds.remainder(60)).toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Color(0xFF7C4DFF))),
                trailing: TextButton(
                  onPressed: () {
                    audio.cancelSleepTimer();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Cancel'),
                ),
              ),
            ...[15, 30, 45, 60].map((mins) => ListTile(
                  title: Text('$mins Minutes', style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    audio.setSleepTimer(Duration(minutes: mins));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sleep Timer set for $mins minutes')));
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, AudioProvider audio, dynamic song) {
    if (song == null) return;
    showDialog(
      context: context,
      builder: (ctx) => _PlaylistDialog(audio: audio, song: song),
    );
  }

  void _handleDelete(BuildContext context, AudioProvider audio, dynamic song) {
    if (song == null || song.data == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1240),
        title: const Text('Delete Song', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${song.title}" from device storage?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              
              // Demand exact permission on Android 11+ to delete
              final status = await Permission.manageExternalStorage.request();
              if (!status.isGranted) {
                final storageStatus = await Permission.storage.request();
                if (!storageStatus.isGranted) {
                  if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Storage permission is required to delete files!')));
                  }
                  return;
                }
              }

              try {
                final file = File(song.data!);
                if (await file.exists()) {
                  await file.delete();
                }
                audio.removeCurrentSong();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Song deleted successfully!')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed: Cannot delete files without OS permission!')));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ── Small helper widgets ─────────────────────────────────────────────────────

class _ControlIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final double size;
  final VoidCallback onTap;

  const _ControlIcon({
    required this.icon,
    required this.isActive,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon,
          color:
              isActive ? const Color(0xFF7C4DFF) : Colors.white38,
          size: size),
    );
  }
}

class _RepeatIcon extends StatelessWidget {
  final PlayerRepeatMode mode;
  final VoidCallback onTap;

  const _RepeatIcon({required this.mode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    bool active = mode != PlayerRepeatMode.none;

    if (mode == PlayerRepeatMode.one) {
      icon = Icons.repeat_one_rounded;
    } else {
      icon = Icons.repeat_rounded;
    }

    return IconButton(
      onPressed: onTap,
      icon: Icon(icon,
          color: active ? const Color(0xFF7C4DFF) : Colors.white38,
          size: 26),
    );
  }
}

class _PlaylistDialog extends StatefulWidget {
  final AudioProvider audio;
  final dynamic song;
  const _PlaylistDialog({required this.audio, required this.song});

  @override
  State<_PlaylistDialog> createState() => _PlaylistDialogState();
}

class _PlaylistDialogState extends State<_PlaylistDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audio, _) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1240),
          title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (audio.customPlaylists.isNotEmpty)
                  ...audio.customPlaylists.keys.map((name) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.queue_music_rounded, color: Colors.white70),
                    title: Text(name, style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      audio.addToPlaylist(name, widget.song);
                      Navigator.pop(context);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to $name')));
                      }
                    },
                  )),
                if (audio.customPlaylists.isNotEmpty)
                  const Divider(color: Colors.white24),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'New Playlist Name',
                    hintStyle: TextStyle(color: Colors.white38),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF7C4DFF))),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                final name = _controller.text.trim();
                if (name.isNotEmpty) {
                  audio.createPlaylist(name);
                  audio.addToPlaylist(name, widget.song);
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Created and added to $name')));
                  }
                }
              },
              child: const Text('Create & Add', style: TextStyle(color: Color(0xFF7C4DFF))),
            ),
          ],
        );
      },
    );
  }
}
