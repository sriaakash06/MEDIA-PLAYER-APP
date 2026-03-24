import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/song_model.dart';
import '../services/global_audio_handler.dart';
import '../main.dart';

class AudioProvider extends ChangeNotifier {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  
  List<Song> _songs = [];
  Set<int> _favorites = {};
  Map<String, List<Song>> _customPlaylists = {};
  
  Timer? _sleepTimer;
  Duration? _remainingSleepTime;
  
  bool _isLoading = false;
  String _permissionError = '';

  AudioProvider() {
    _initAudioSession();
    _setupHandlerSync();
  }

  void _setupHandlerSync() {
    final h = globalHandler;
    if (h == null) return;

    h.onDurationChanged = (d) {
      notifyListeners();
    };
    h.onPositionChanged = (p) {
      notifyListeners();
    };
    h.onPlayerStateChanged = (s) {
      notifyListeners();
    };
    h.onTrackComplete = () {
      notifyListeners();
    };
  }

  // ─── Getters ──────────────────────────────────────────────────────────────
  List<Song> get songs => _songs;
  bool get isLoading => _isLoading;
  String get permissionError => _permissionError;

  // Sync these from GlobalAudioHandler
  Song? get currentSong {
    final h = globalHandler;
    if (h == null || h.currentIndex == -1 || h.currentQueue.isEmpty) return null;
    return h.currentQueue[h.currentIndex];
  }
  
  bool get isPlaying => globalHandler?.player.state == PlayerState.playing;
  Duration get duration => globalHandler?.currentDuration ?? Duration.zero;
  Duration get position => globalHandler?.currentPosition ?? Duration.zero;
  bool get isShuffled => globalHandler?.isShuffled ?? false;
  AudioServiceRepeatMode get repeatMode => globalHandler?.repeatMode ?? AudioServiceRepeatMode.none;
  
  Duration? get remainingSleepTime => _remainingSleepTime;
  bool get isSleepTimerActive => _sleepTimer != null;

  // ─── Playback Commands ───────────────────────────────────────────────────
  void togglePlay() {
    if (isPlaying) {
      globalHandler?.pause();
    } else {
      globalHandler?.play();
    }
    notifyListeners();
  }

  void playFromLibrary(Song song) {
    if (globalHandler == null) return;
    globalHandler!.setQueue(_songs);
    int index = _songs.indexWhere((s) => s.id == song.id);
    globalHandler!.playAtIndex(index);
    notifyListeners();
  }

  void playSongAt(int index) {
    globalHandler?.playAtIndex(index);
    notifyListeners();
  }

  void skipToNext() {
    globalHandler?.skipToNext();
    notifyListeners();
  }

  void skipToPrevious() {
    globalHandler?.skipToPrevious();
    notifyListeners();
  }

  void seek(Duration pos) {
    globalHandler?.seek(pos);
    notifyListeners();
  }

  void toggleShuffle() {
    globalHandler?.toggleShuffle();
    notifyListeners();
  }

  void toggleRepeatMode() {
    final h = globalHandler;
    if (h == null) return;
    final modes = [AudioServiceRepeatMode.none, AudioServiceRepeatMode.all, AudioServiceRepeatMode.one];
    int currentIndex = modes.indexOf(h.repeatMode);
    if (currentIndex == -1) currentIndex = 0;
    final next = modes[(currentIndex + 1) % modes.length];
    h.setRepeatMode(next);
    notifyListeners();
  }

  // ─── Device Scan ──────────────────────────────────────────────────────────
  Future<void> loadDeviceSongs() async {
    _isLoading = true;
    _permissionError = '';
    notifyListeners();

    // Android 13+ Notification Permission
    await Permission.notification.request();

    bool granted = false;
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

      _songs = models.map((m) => Song.fromSongModel(m)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _permissionError = 'Error scanning songs: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Features ─────────────────────────────────────────────────────────────
  List<Song> get favoriteSongs => _songs.where((s) => _favorites.contains(s.id)).toList();
  Map<String, List<Song>> get customPlaylists => _customPlaylists;

  Map<String, List<Song>> get artists {
    final map = <String, List<Song>>{};
    for (var s in _songs) {
      map.putIfAbsent(s.artist, () => []).add(s);
    }
    return map;
  }

  Map<String, List<Song>> get albums {
    final map = <String, List<Song>>{};
    for (var s in _songs) {
      map.putIfAbsent(s.album, () => []).add(s);
    }
    return map;
  }

  bool isFavorite(int? id) => id != null && _favorites.contains(id);

  void toggleFavorite(int id) {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
    notifyListeners();
  }

  void createPlaylist(String name) {
    if (!_customPlaylists.containsKey(name)) {
      _customPlaylists[name] = [];
      notifyListeners();
    }
  }

  void addToPlaylist(String name, Song song) {
    if (_customPlaylists.containsKey(name)) {
      if (!_customPlaylists[name]!.any((s) => s.id == song.id)) {
        _customPlaylists[name]!.add(song);
        notifyListeners();
      }
    }
  }

  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _remainingSleepTime = duration;
    notifyListeners();

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSleepTime != null) {
        if (_remainingSleepTime!.inSeconds <= 0) {
          _sleepTimer?.cancel();
          _sleepTimer = null;
          _remainingSleepTime = null;
          globalHandler?.pause();
          notifyListeners();
        } else {
          _remainingSleepTime = Duration(seconds: _remainingSleepTime!.inSeconds - 1);
          if (_remainingSleepTime!.inSeconds % 10 == 0) notifyListeners();
        }
      }
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _remainingSleepTime = null;
    notifyListeners();
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  List<Song> search(String query) {
    final q = query.toLowerCase();
    return _songs.where((s) => 
      s.title.toLowerCase().contains(q) || 
      s.artist.toLowerCase().contains(q) ||
      s.album.toLowerCase().contains(q)).toList();
  }

  void removeCurrentSong() {
    final s = currentSong;
    if (s != null) {
      _songs.removeWhere((x) => x.id == s.id);
      globalHandler?.setQueue(_songs);
      notifyListeners();
    }
  }
}
