import '../downloads/quran_audio_storage.dart';
import '../domain/quran_verse.dart';
import 'quran_audio_uri.dart';
import 'quran_reciter.dart';

abstract interface class QuranAudioSourceResolver {
  Future<Uri> resolve(QuranVerse verse, QuranReciter reciter);
}

class RemoteQuranAudioSourceResolver implements QuranAudioSourceResolver {
  const RemoteQuranAudioSourceResolver();

  @override
  Future<Uri> resolve(QuranVerse verse, QuranReciter reciter) async =>
      quranAudioUriForVerse(verse, reciter);
}

class LocalFirstQuranAudioSourceResolver implements QuranAudioSourceResolver {
  const LocalFirstQuranAudioSourceResolver(this.storage);

  final QuranAudioStorage storage;

  @override
  Future<Uri> resolve(QuranVerse verse, QuranReciter reciter) async {
    final downloaded = await storage.findValidVerse(
      reciter.identifier,
      verse.surahNumber,
      verse.verseNumber,
      verse.globalVerseNumber,
    );
    if (downloaded != null) {
      return storage
          .audioFileFor(
            reciter.identifier,
            verse.surahNumber,
            verse.verseNumber,
          )
          .uri;
    }
    return quranAudioUriForVerse(verse, reciter);
  }
}
