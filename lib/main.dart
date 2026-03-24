import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/audio_provider.dart';
import 'screens/library_screen.dart';
import 'package:audio_service/audio_service.dart';
import 'services/global_audio_handler.dart';

late AudioHandler audioHandler;
GlobalAudioHandler? _handlerInstance;
GlobalAudioHandler? get globalHandler => _handlerInstance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    debugPrint('Starting AudioService initialization...');
    _handlerInstance = GlobalAudioHandler();
    audioHandler = await AudioService.init(
      builder: () => _handlerInstance!,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.media.player.channel.audio',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: true,
      ),
    );
    debugPrint('AudioService initialized successfully.');
  } catch (e, stack) {
    debugPrint('AudioService initialization FAILED: $e');
    debugPrint(stack.toString());
    // Fallback? or just crash?
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tunify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF7C4DFF),
        scaffoldBackgroundColor: const Color(0xFF0A0A1A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C4DFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const LibraryScreen(),
    );
  }
}
