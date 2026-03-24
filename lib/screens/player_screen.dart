import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/album_art_widget.dart';

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
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
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

                    const Spacer(flex: 2),
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
