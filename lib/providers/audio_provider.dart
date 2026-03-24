import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  List<String> _playlist = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

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
      skipToNext();
    });
  }

  List<String> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  String? get currentFile => _currentIndex != -1 ? _playlist[_currentIndex] : null;

  String get currentTrackName {
    if (currentFile == null) return "No track selected";
    return currentFile!.split('\\').last.split('/').last;
  }

  void setPlaylist(List<String> files) {
    _playlist = files;
    if (_playlist.isNotEmpty) {
      _currentIndex = 0;
      play();
    }
    notifyListeners();
  }

  Future<void> play() async {
    if (_currentIndex == -1 || _playlist.isEmpty) return;
    await _audioPlayer.play(DeviceFileSource(_playlist[_currentIndex]));
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.resume();
  }

  Future<void> togglePlay() async {
    if (_isPlaying) {
      await pause();
    } else {
      if (_position == Duration.zero) {
        await play();
      } else {
        await resume();
      }
    }
  }

  Future<void> skipToNext() async {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    await play();
  }

  Future<void> skipToPrevious() async {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    await play();
  }

  Future<void> seek(Duration pos) async {
    await _audioPlayer.seek(pos);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
