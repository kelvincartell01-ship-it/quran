import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'quran_audio_controller.dart';
import 'quran_audio_catalog.dart';
import 'quran_audio_engine.dart';
import 'quran_audio_handler.dart';
import 'quran_audio_preferences.dart';
import 'quran_audio_session.dart';
import 'quran_audio_source_resolver.dart';

Future<QuranAudioController> createQuranAudioController(
  SharedPreferences sharedPreferences, {
  QuranAudioSourceResolver sourceResolver =
      const RemoteQuranAudioSourceResolver(),
  QuranAudioCatalog? playbackCatalog,
}) async {
  final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  if (!isAndroid && !isIOS) {
    return const UnavailableQuranAudioController();
  }

  final preferences = QuranAudioPreferencesRepository(sharedPreferences);
  final initialPreferences = preferences.load();
  final engine = JustAudioQuranAudioEngine();
  await engine.setRepeatMode(initialPreferences.repeatMode);
  final session = await AudioSessionCoordinator.create();
  final artworkUri = await _localAudioArtworkUri();
  final handler = QuranAudioHandler(
    engine: engine,
    session: session,
    preferences: preferences,
    initialPreferences: initialPreferences,
    artworkUri: artworkUri,
    resumeOnInterruptionEnd: isAndroid,
    playbackCatalog: playbackCatalog,
    sourceResolver: sourceResolver,
  );

  await AudioService.init(
    builder: () => handler,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.quran.audio',
      androidNotificationChannelName: 'Quran audio playback',
      androidNotificationIcon: 'drawable/ic_audio_notification',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: false,
      androidNotificationClickStartsActivity: true,
      androidResumeOnClick: true,
      androidStopForegroundOnPause: true,
    ),
  );
  return handler;
}

Future<Uri> _localAudioArtworkUri() async {
  final directory = await getTemporaryDirectory();
  final file = File(
    '${directory.path}${Platform.pathSeparator}quran_audio_art.png',
  );
  if (!await file.exists()) {
    final bytes = await rootBundle.load('assets/images/quran_audio_art.png');
    await file.writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      flush: true,
    );
  }
  return file.uri;
}
