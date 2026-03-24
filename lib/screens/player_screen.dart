import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/audio_provider.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  Future<void> _pickFiles(BuildContext context) async {
    debugPrint("Pick Files clicked");
    bool canPick = false;

    if (Theme.of(context).platform == TargetPlatform.android || Theme.of(context).platform == TargetPlatform.iOS) {
      final status = await Permission.storage.request();
      final audioStatus = await Permission.audio.request();
      canPick = status.isGranted || audioStatus.isGranted;
      debugPrint("Android/iOS Permission status: storage=$status, audio=$audioStatus");
    } else {
      // Desktop platforms don't need these permissions via permission_handler
      canPick = true;
      debugPrint("Desktop platform, skipping permission check");
    }

    if (canPick) {
      debugPrint("Opening File Picker...");
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'flac'],
          allowMultiple: true,
        );

        if (result != null) {
          final paths = result.paths.whereType<String>().toList();
          debugPrint("Picked ${paths.length} files: $paths");
          if (context.mounted) {
            Provider.of<AudioProvider>(context, listen: false).setPlaylist(paths);
          }
        } else {
          debugPrint("User canceled the picker");
        }
      } catch (e) {
        debugPrint("Error picking files: $e");
      }
    } else {
      debugPrint("Permission denied");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission denied")),
        );
      }
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.3),
              const Color(0xFF0F0F1E),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Consumer<AudioProvider>(
              builder: (context, audio, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Album Art Placeholder
                    Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.music_note_rounded,
                        size: 150,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Track Info
                    Text(
                      audio.currentTrackName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Local Storage",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white54,
                      ),
                    ),
                    const Spacer(),
                    // Seek Bar
                    Column(
                      children: [
                        Slider(
                          value: audio.position.inSeconds.toDouble(),
                          max: audio.duration.inSeconds.toDouble() > 0 
                              ? audio.duration.inSeconds.toDouble() 
                              : 100.0,
                          onChanged: (value) {
                            audio.seek(Duration(seconds: value.toInt()));
                          },
                          activeColor: Theme.of(context).primaryColor,
                          inactiveColor: Colors.white12,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(audio.position), style: const TextStyle(color: Colors.white54)),
                              Text(_formatDuration(audio.duration), style: const TextStyle(color: Colors.white54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded, size: 48),
                          onPressed: audio.skipToPrevious,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 24),
                        GestureDetector(
                          onTap: audio.togglePlay,
                          child: Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, size: 48),
                          onPressed: audio.skipToNext,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Pick Files Button
                    ElevatedButton.icon(
                      onPressed: () => _pickFiles(context),
                      icon: const Icon(Icons.folder_open_rounded),
                      label: const Text("Pick Audio Files"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
