import 'dart:async';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/song_model.dart';

class GlobalAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  
  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _isShuffled = false;
  List<int> _shuffledIndices = [];
  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;
  Duration currentPosition = Duration.zero;
  Duration currentDuration = Duration.zero;

  // Callbacks for UI sync
  Function(Duration)? onDurationChanged;
  Function(Duration)? onPositionChanged;
  Function(PlayerState)? onPlayerStateChanged;
  Function()? onTrackComplete;

  GlobalAudioHandler() {
    _player.onDurationChanged.listen((d) {
      currentDuration = d;
      if (mediaItem.value != null) {
        mediaItem.add(mediaItem.value!.copyWith(duration: d));
      }
      onDurationChanged?.call(d);
    });

    _player.onPositionChanged.listen((p) {
      currentPosition = p;
      onPositionChanged?.call(p);
      _broadcastState();
    });

    _player.onPlayerStateChanged.listen((s) {
      onPlayerStateChanged?.call(s);
      _broadcastState();
    });

    _player.onPlayerComplete.listen((_) {
      _handleTrackComplete();
      onTrackComplete?.call();
    });
  }

  // ─── Playback Control ──────────────────────────────────────────────────────

  @override
  Future<void> play() async {
    if (_currentIndex == -1 && _queue.isNotEmpty) {
      await playAtIndex(0);
    } else {
      await _player.resume();
    }
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;
    int nextIndex = _currentIndex + 1;
    if (nextIndex >= _queue.length) {
      nextIndex = 0;
    }
    await playAtIndex(nextIndex);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;
    int prevIndex = _currentIndex - 1;
    if (prevIndex < 0) {
      prevIndex = _queue.length - 1;
    }
    await playAtIndex(prevIndex);
  }

  // ─── Queue Management ──────────────────────────────────────────────────────

  void setQueue(List<Song> songs) {
    _queue = List.from(songs);
    _broadcastQueue();
  }

  Future<void> playAtIndex(int index) async {
    if (_queue.isEmpty || index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    final song = _queue[_currentIndex];
    
    if (song.data != null) {
      await _player.play(DeviceFileSource(song.data!));
      _broadcastMediaItem(song);
    }
  }

  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    if (_isShuffled) {
      _shuffledIndices = List.generate(_queue.length, (i) => i)..shuffle();
    } else {
      _shuffledIndices = [];
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode mode) async {
    _repeatMode = mode;
  }

  void _handleTrackComplete() {
    switch (_repeatMode) {
      case AudioServiceRepeatMode.one:
        playAtIndex(_currentIndex);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        skipToNext();
        break;
      case AudioServiceRepeatMode.none:
        if (_currentIndex < _queue.length - 1) {
          skipToNext();
        } else {
          _player.stop();
          _broadcastState();
        }
        break;
    }
  }

  // ─── Notification Sync ─────────────────────────────────────────────────────

  void _broadcastMediaItem(Song s) {
    final item = MediaItem(
      id: s.id.toString(),
      album: s.album,
      title: s.title,
      artist: s.artist,
      duration: Duration(milliseconds: s.duration),
    );
    mediaItem.add(item);
  }

  void _broadcastState() {
    final playing = _player.state == PlayerState.playing;
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.ready,
      playing: playing,
      updatePosition: _player.getCurrentPosition() != null ? Duration.zero : Duration.zero, // Dummy, overridden by updatePosition below
      bufferedPosition: Duration.zero,
      speed: 1.0,
    ).copyWith(
      updatePosition: Duration(milliseconds: 0), // BaseAudioHandler handles the duration calc if updateTime is provided
    ));
    
    // Exact position broadcast
    _player.getCurrentPosition().then((pos) {
       if (pos != null) {
          playbackState.add(playbackState.value.copyWith(
             updatePosition: pos,
          ));
       }
    });
  }

  void _broadcastQueue() {
    final list = _queue.map((s) => MediaItem(
      id: s.id.toString(),
      album: s.album,
      title: s.title,
      artist: s.artist,
      duration: Duration(milliseconds: s.duration),
    )).toList();
    queue.add(list);
  }

  // Getters for AudioProvider
  AudioPlayer get player => _player;
  List<Song> get currentQueue => _queue;
  int get currentIndex => _currentIndex;
  bool get isShuffled => _isShuffled;
  AudioServiceRepeatMode get repeatMode => _repeatMode;
}
