import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

import '../domain/quran_verse.dart';
import '../domain/surah.dart';
import 'quran_audio_source_resolver.dart';
import 'quran_audio_uri.dart';
import 'quran_reciter.dart';

@immutable
class QuranAudioTrack {
  const QuranAudioTrack({required this.uri, required this.mediaItem});

  final Uri uri;
  final MediaItem mediaItem;
}

class QuranAudioQueueBuilder {
  const QuranAudioQueueBuilder();

  List<QuranAudioTrack> build({
    required Surah surah,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
    required Uri artworkUri,
    int startingVerseNumber = 1,
  }) {
    if (verses.length != surah.verseCount) {
      throw StateError(
        'Surah ${surah.number} has ${verses.length} loaded verses; '
        '${surah.verseCount} are required.',
      );
    }

    for (var index = 0; index < verses.length; index++) {
      final verse = verses[index];
      if (verse.surahNumber != surah.number ||
          verse.verseNumber != index + 1 ||
          verse.globalVerseNumber <= 0 ||
          (index > 0 &&
              verse.globalVerseNumber !=
                  verses[index - 1].globalVerseNumber + 1)) {
        throw StateError('The audio queue requires ordered canonical verses.');
      }
    }

    final startingIndex = startingVerseNumber - 1;
    if (startingIndex < 0 || startingIndex >= verses.length) {
      throw RangeError.range(
        startingVerseNumber,
        1,
        verses.length,
        'startingVerseNumber',
      );
    }

    return List.unmodifiable(
      verses.map((verse) {
        final mediaItem = MediaItem(
          id: verse.globalVerseNumber.toString(),
          title: '${surah.transliteration} · ${verse.verseNumber}',
          album: surah.arabicName,
          artist: reciter.englishName,
          artUri: artworkUri,
          extras: {
            'surahNumber': verse.surahNumber,
            'verseNumber': verse.verseNumber,
            'globalVerseNumber': verse.globalVerseNumber,
            'reciterId': reciter.identifier,
          },
        );
        return QuranAudioTrack(
          uri: audioUriForVerse(verse, reciter),
          mediaItem: mediaItem,
        );
      }),
    );
  }

  Future<List<QuranAudioTrack>> buildWithSourceResolver({
    required Surah surah,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
    required Uri artworkUri,
    required QuranAudioSourceResolver sourceResolver,
    int startingVerseNumber = 1,
  }) async {
    final remoteTracks = build(
      surah: surah,
      verses: verses,
      reciter: reciter,
      artworkUri: artworkUri,
      startingVerseNumber: startingVerseNumber,
    );
    final resolvedUris = await Future.wait(
      verses.map((verse) => sourceResolver.resolve(verse, reciter)),
    );
    return List.unmodifiable([
      for (var index = 0; index < remoteTracks.length; index++)
        QuranAudioTrack(
          uri: resolvedUris[index],
          mediaItem: remoteTracks[index].mediaItem,
        ),
    ]);
  }

  static Uri audioUriForVerse(QuranVerse verse, QuranReciter reciter) =>
      quranAudioUriForVerse(verse, reciter);
}
