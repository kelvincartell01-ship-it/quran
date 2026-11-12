import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'quran_audio_storage.dart';
import 'quran_download_manager.dart';

Future<QuranDownloadManager> createQuranDownloadManager() async {
  final supportDirectory = await getApplicationSupportDirectory();
  final rootDirectory = Directory(
    '${supportDirectory.path}${Platform.pathSeparator}quran_audio_downloads',
  );
  return QuranDownloadManager.create(
    storage: QuranAudioStorage(rootDirectory: rootDirectory),
  );
}
