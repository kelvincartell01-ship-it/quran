import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/preferences/shared_preferences_repository.dart';
import 'features/quran/audio/quran_audio_providers.dart';
import 'features/quran/audio/quran_audio_source_resolver.dart';
import 'features/quran/audio/quran_audio_startup.dart';
import 'features/quran/data/local_quran_audio_catalog.dart';
import 'features/quran/downloads/quran_download_providers.dart';
import 'features/quran/downloads/quran_download_startup.dart';
import 'features/settings/presentation/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  final preferencesRepository = SharedPreferencesRepository(sharedPreferences);
  final initialPreferences = await preferencesRepository.load();
  final downloadManager = await createQuranDownloadManager();
  final audioController = await createQuranAudioController(
    sharedPreferences,
    sourceResolver: LocalFirstQuranAudioSourceResolver(downloadManager.storage),
    playbackCatalog: LocalQuranAudioCatalog.fromAssets(),
  );

  runApp(
    ProviderScope(
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(preferencesRepository),
        initialAppPreferencesProvider.overrideWithValue(initialPreferences),
        quranAudioControllerProvider.overrideWithValue(audioController),
        quranDownloadControllerProvider.overrideWithValue(downloadManager),
      ],
      child: const QuranApp(),
    ),
  );
}
