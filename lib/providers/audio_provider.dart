import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song_model.dart';

enum PlayerRepeatMode { none, all, one }

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  List<Song> _songs = [];
  List<Song> _queue = [];
  List<int> _shuffledIndices = [];
  Set<int> _favorites = {};
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isShuffled = false;
  PlayerRepeatMode _repeatMode = PlayerRepeatMode.none;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String _permissionError = '';

  AudioProvider() {
    _audioPlayer.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      _onTrackComplete();
    });
  }

  // ─── Getters ─────────────────────────────────────────────────────────────
  List<Song> get songs => _songs;
  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isShuffled => _isShuffled;
  PlayerRepeatMode get repeatMode => _repeatMode;
  Duration get duration => _duration;
  Duration get position => _position;
  String get permissionError => _permissionError;

  Song? get currentSong =>
      (_currentIndex != -1 && _queue.isNotEmpty) ? _queue[_currentIndex] : null;

  bool isFavorite(int? id) => id != null && _favorites.contains(id);

  void toggleFavorite(int id) {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
    notifyListeners();
  }

  void removeCurrentSong() {
    if (_currentIndex == -1 || _queue.isEmpty) return;
    
    final songToRemove = _queue[_currentIndex];
    
    _songs.removeWhere((s) => s.id == songToRemove.id);
    _queue.removeAt(_currentIndex);
    
    if (_queue.isEmpty) {
      _audioPlayer.stop();
      _isPlaying = false;
      _currentIndex = -1;
      _position = Duration.zero;
      _duration = Duration.zero;
    } else {
      if (_currentIndex >= _queue.length) {
        _currentIndex = 0;
      }
      playSongAt(_currentIndex);
    }
    notifyListeners();
  }

  // ─── Device Scan ──────────────────────────────────────────────────────────
  Future<void> loadDeviceSongs() async {
    _isLoading = true;
    _permissionError = '';
    notifyListeners();

    bool granted = false;
    // Android 13+ uses READ_MEDIA_AUDIO, below uses READ_EXTERNAL_STORAGE
    final audioStatus = await Permission.audio.request();
    if (audioStatus.isGranted) {
      granted = true;
    } else {
      final storageStatus = await Permission.storage.request();
      granted = storageStatus.isGranted;
    }

    if (!granted) {
      _permissionError = 'Storage permission denied. Please grant permission to scan songs.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final models = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      _songs = models
          .where((m) => (m.duration ?? 0) > 30000) // filter clips <30s
          .map((m) => Song.fromSongModel(m))
          .toList();

      _queue = List.from(_songs);
    } catch (e) {
      _permissionError = 'Failed to load songs: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Playback ────────────────────────────────────────────────────────────
  Future<void> playSongAt(int index) async {
    if (_queue.isEmpty) return;
    _currentIndex = index.clamp(0, _queue.length - 1);
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
    final song = _queue[_currentIndex];
    if (song.data == null) return;
    await _audioPlayer.play(DeviceFileSource(song.data!));
  }

  Future<void> togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (currentSong == null) {
        if (_queue.isNotEmpty) await playSongAt(0);
      } else {
        await _audioPlayer.resume();
      }
    }
  }

  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;
    if (_repeatMode == PlayerRepeatMode.one) {
      await playSongAt(_currentIndex);
      return;
    }
    final next = (_currentIndex + 1) % _queue.length;
    if (next == 0 && _repeatMode == PlayerRepeatMode.none) {
      await _audioPlayer.stop();
      _isPlaying = false;
      notifyListeners();
      return;
    }
    await playSongAt(next);
  }

  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    final prev = (_currentIndex - 1 + _queue.length) % _queue.length;
    await playSongAt(prev);
  }

  Future<void> seek(Duration pos) async {
    await _audioPlayer.seek(pos);
  }

  void _onTrackComplete() {
    switch (_repeatMode) {
      case PlayerRepeatMode.one:
        playSongAt(_currentIndex);
        break;
      case PlayerRepeatMode.all:
        skipToNext();
        break;
      case PlayerRepeatMode.none:
        final next = _currentIndex + 1;
        if (next < _queue.length) {
          playSongAt(next);
        } else {
          _isPlaying = false;
          notifyListeners();
        }
        break;
    }
  }

  // ─── Shuffle ──────────────────────────────────────────────────────────────
  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    final currentSongId = currentSong?.id;

    if (_isShuffled) {
      _shuffledIndices = List.generate(_songs.length, (i) => i)..shuffle();
      _queue = _shuffledIndices.map((i) => _songs[i]).toList();
    } else {
      _queue = List.from(_songs);
    }

    // Keep current song playing
    if (currentSongId != null) {
      _currentIndex = _queue.indexWhere((s) => s.id == currentSongId);
      if (_currentIndex == -1) _currentIndex = 0;
    }
    notifyListeners();
  }

  // ─── Repeat ───────────────────────────────────────────────────────────────
  void cycleRepeat() {
    switch (_repeatMode) {
      case PlayerRepeatMode.none:
        _repeatMode = PlayerRepeatMode.all;
        break;
      case PlayerRepeatMode.all:
        _repeatMode = PlayerRepeatMode.one;
        break;
      case PlayerRepeatMode.one:
        _repeatMode = PlayerRepeatMode.none;
        break;
    }
    notifyListeners();
  }

  // ─── Play from library ────────────────────────────────────────────────────
  void playFromLibrary(Song song) {
    if (_isShuffled) {
      _queue = List.from(_songs)..shuffle();
    } else {
      _queue = List.from(_songs);
    }
    final idx = _queue.indexWhere((s) => s.id == song.id);
    playSongAt(idx == -1 ? 0 : idx);
  }

  // ─── Search ───────────────────────────────────────────────────────────────
  List<Song> search(String query) {
    if (query.trim().isEmpty) return _songs;
    final q = query.toLowerCase();
    return _songs.where((s) {
      return s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q) ||
          s.album.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
