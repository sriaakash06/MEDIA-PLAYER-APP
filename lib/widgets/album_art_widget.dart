import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AlbumArtWidget extends StatelessWidget {
  final int songId;
  final double size;
  final double borderRadius;

  const AlbumArtWidget({
    super.key,
    required this.songId,
    this.size = 56,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: QueryArtworkWidget(
        id: songId,
        type: ArtworkType.AUDIO,
        artworkWidth: size,
        artworkHeight: size,
        artworkFit: BoxFit.cover,
        quality: 50,
        keepOldArtwork: true,
        artworkBorder: BorderRadius.circular(borderRadius),
        nullArtworkWidget: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C3FD8), Color(0xFF1A1A3E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Icon(
            Icons.music_note_rounded,
            color: Colors.white54,
            size: size * 0.45,
          ),
        ),
      ),
    );
  }
}
