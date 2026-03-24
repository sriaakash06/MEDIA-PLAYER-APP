import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../models/song_model.dart';
import '../widgets/album_art_widget.dart';
import '../widgets/mini_player.dart';
import 'player_screen.dart';
import 'collection_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioProvider>().loadDeviceSongs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDuration(int ms) {
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
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
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A1A),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A063A), Color(0xFF0A0A1A)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tunify',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Feel the Music 🎧',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Consumer<AudioProvider>(
                          builder: (_, audio, __) => IconButton(
                            icon: const Icon(Icons.refresh_rounded,
                                color: Colors.white54),
                            onPressed: audio.loadDeviceSongs,
                            tooltip: 'Refresh Library',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isSearching
                              ? const Color(0xFF7C4DFF)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 15),
                        onChanged: (v) => setState(() => _searchQuery = v),
                        onTap: () => setState(() => _isSearching = true),
                        onEditingComplete: () =>
                            setState(() => _isSearching = false),
                        decoration: InputDecoration(
                          hintText: 'Search songs, artists...',
                          hintStyle: const TextStyle(color: Colors.white30),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: Colors.white30),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      color: Colors.white30, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tabs 
                    TabBar(
                      isScrollable: true,
                      indicatorColor: const Color(0xFF7C4DFF),
                      labelColor: const Color(0xFF7C4DFF),
                      unselectedLabelColor: Colors.white54,
                      tabAlignment: TabAlignment.start,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Songs'),
                        Tab(text: 'Lists'),
                        Tab(text: 'Artists'),
                        Tab(text: 'Albums'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Tab Contents ───────────────────────────────────────────────────
          Expanded(
            child: Consumer<AudioProvider>(
              builder: (context, audio, _) {
                if (audio.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Color(0xFF7C4DFF)),
                          strokeWidth: 2,
                        ),
                        SizedBox(height: 16),
                        Text('Scanning music library...',
                            style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  );
                }

                if (audio.permissionError.isNotEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline_rounded,
                              color: Color(0xFF7C4DFF), size: 64),
                          const SizedBox(height: 16),
                          Text(
                            audio.permissionError,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 14),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: audio.loadDeviceSongs,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C4DFF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final displaySongs = _searchQuery.isNotEmpty
                    ? audio.search(_searchQuery)
                    : audio.songs;

                final songsTab = displaySongs.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.music_off_rounded,
                                color: Colors.white24, size: 72),
                            SizedBox(height: 16),
                            Text('No songs found',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 16)),
                            SizedBox(height: 6),
                            Text('Add music files to your device',
                                style: TextStyle(
                                    color: Colors.white24, fontSize: 13)),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Song count + shuffle all
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
                            child: Row(
                              children: [
                                Text(
                                  '${displaySongs.length} Songs',
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 13),
                                ),
                                const Spacer(),
                                _ShuffleAllButton(
                                    songs: displaySongs,
                                    onPlay: () => _openPlayer(context)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 8),
                              itemCount: displaySongs.length,
                              itemBuilder: (context, index) {
                                final song = displaySongs[index];
                                return _SongTile(
                                  song: song,
                                  isPlaying: audio.currentSong?.id == song.id,
                                  onTap: () {
                                    audio.playFromLibrary(song);
                                    _openPlayer(context);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );

                final artists = audio.artists.keys.toList()..sort();
                final albums = audio.albums.keys.toList()..sort();

                final listsTab = ListView(
                  children: [
                    ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFFF5252)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
                      ),
                      title: const Text('Favorites', style: TextStyle(color: Colors.white, fontSize: 16)),
                      subtitle: Text('${audio.favoriteSongs.length} songs', style: const TextStyle(color: Colors.white54)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => CollectionScreen(title: 'Favorites', songs: audio.favoriteSongs),
                        ));
                      },
                    ),
                    if (audio.customPlaylists.isNotEmpty)
                      const Divider(color: Colors.white12, height: 1),
                    ...audio.customPlaylists.keys.map((name) {
                      final pSongs = audio.customPlaylists[name]!;
                      return ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C1F6E),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.queue_music_rounded, color: Colors.white70, size: 26),
                        ),
                        title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 16)),
                        subtitle: Text('${pSongs.length} songs', style: const TextStyle(color: Colors.white54)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => CollectionScreen(title: name, songs: pSongs),
                          ));
                        },
                      );
                    }),
                  ],
                );

                final artistsTab = ListView.builder(
                  itemCount: artists.length,
                  itemBuilder: (context, index) {
                    final artistName = artists[index];
                    final artistSongs = audio.artists[artistName]!;
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF2C1F6E),
                        child: Icon(Icons.person_rounded, color: Colors.white70),
                      ),
                      title: Text(artistName, style: const TextStyle(color: Colors.white)),
                      subtitle: Text('${artistSongs.length} songs', style: const TextStyle(color: Colors.white54)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => CollectionScreen(title: artistName, songs: artistSongs),
                        ));
                      },
                    );
                  },
                );

                final albumsTab = ListView.builder(
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final albumName = albums[index];
                    final albumSongs = audio.albums[albumName]!;
                    return ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C1F6E),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.album_rounded, color: Colors.white70),
                      ),
                      title: Text(albumName, style: const TextStyle(color: Colors.white)),
                      subtitle: Text('${albumSongs.length} songs', style: const TextStyle(color: Colors.white54)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => CollectionScreen(title: albumName, songs: albumSongs),
                        ));
                      },
                    );
                  },
                );

                return TabBarView(
                  children: [
                    songsTab,
                    listsTab,
                    artistsTab,
                    albumsTab,
                  ],
                );
              },
            ),
          ),

          // ── Mini Player ─────────────────────────────────────────────────
          const MiniPlayer(),
        ],
      ),
    ));
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────

class _ShuffleAllButton extends StatelessWidget {
  final List<Song> songs;
  final VoidCallback onPlay;

  const _ShuffleAllButton({required this.songs, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        final audio = context.read<AudioProvider>();
        if (!audio.isShuffled) audio.toggleShuffle();
        audio.playSongAt(0);
        onPlay();
      },
      icon: const Icon(Icons.shuffle_rounded, size: 16, color: Color(0xFF7C4DFF)),
      label: const Text('Shuffle All',
          style: TextStyle(color: Color(0xFF7C4DFF), fontSize: 13)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        backgroundColor: const Color(0xFF7C4DFF).withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;

  const _SongTile({
    required this.song,
    required this.isPlaying,
    required this.onTap,
  });

  String _fmt(int ms) {
    final d = Duration(milliseconds: ms);
    return '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: const Color(0xFF7C4DFF).withOpacity(0.1),
      highlightColor: const Color(0xFF7C4DFF).withOpacity(0.05),
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
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isPlaying)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: _MusicBars(),
              ),
            Text(
              _fmt(song.duration),
              style: const TextStyle(color: Colors.white24, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated playing bars indicator
class _MusicBars extends StatefulWidget {
  const _MusicBars();

  @override
  State<_MusicBars> createState() => _MusicBarsState();
}

class _MusicBarsState extends State<_MusicBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [1.0, 0.4, 0.75, 0.55].asMap().entries.map((e) {
            final phase = (e.key * 0.25 + _controller.value) % 1.0;
            final height = 6 + 10 * (0.5 + 0.5 * phase);
            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
