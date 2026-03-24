import 'package:on_audio_query/on_audio_query.dart';

enum PlayerRepeatMode { none, all, one }

class Song {
  final int id;
  final String title;
  final String artist;
  final String album;
  final int duration; // ms
  final String? data;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.data,
  });

  factory Song.fromSongModel(SongModel model) {
    return Song(
      id: model.id,
      title: model.title,
      artist: model.artist ?? 'Unknown Artist',
      album: model.album ?? 'Unknown Album',
      duration: model.duration ?? 0,
      data: model.data,
    );
  }

  String get formattedDuration {
    final d = Duration(milliseconds: duration);
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
