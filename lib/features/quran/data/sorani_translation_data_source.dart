import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/quran_verse.dart';

typedef SoraniTranslationEntry = ({int globalVerseNumber, String translation});

abstract interface class SoraniTranslationDataSource {
  Future<Map<VerseReference, SoraniTranslationEntry>> loadTranslations();
}

class AssetSoraniTranslationDataSource implements SoraniTranslationDataSource {
  const AssetSoraniTranslationDataSource({this.bundle});

  static const assetPath = 'assets/data/sorani-translation.json';
  static const expectedVerseCount = 6236;

  final AssetBundle? bundle;

  @override
  Future<Map<VerseReference, SoraniTranslationEntry>> loadTranslations() async {
    final contents = await (bundle ?? rootBundle).loadString(assetPath);
    final decoded = jsonDecode(contents);
    if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != 1) {
      throw const FormatException(
        'Unsupported Sorani translation data format.',
      );
    }

    final records = decoded['translations'];
    if (records is! List<dynamic>) {
      throw const FormatException(
        'Sorani translation data must contain a list.',
      );
    }

    final translations = <VerseReference, SoraniTranslationEntry>{};
    for (var index = 0; index < records.length; index++) {
      final record = records[index];
      if (record is! Map<String, dynamic>) {
        throw FormatException(
          'Invalid Sorani translation record ${index + 1}.',
        );
      }

      final surahNumber = record['surahNumber'];
      final verseNumber = record['verseNumber'];
      final globalVerseNumber = record['globalVerseNumber'];
      final translation = record['translation'];
      if (surahNumber is! int ||
          verseNumber is! int ||
          globalVerseNumber is! int ||
          translation is! String) {
        throw FormatException(
          'Invalid Sorani translation at record ${index + 1}.',
        );
      }
      if (surahNumber < 1 || surahNumber > 114 || verseNumber < 1) {
        throw FormatException(
          'Invalid Sorani verse key at record ${index + 1}.',
        );
      }
      if (globalVerseNumber != index + 1) {
        throw FormatException(
          'Global verse number mismatch at Surah $surahNumber, '
          'verse $verseNumber: expected ${index + 1}, '
          'found $globalVerseNumber.',
        );
      }
      if (translation.trim().isEmpty) {
        throw FormatException(
          'Missing Sorani translation at Surah $surahNumber, '
          'verse $verseNumber.',
        );
      }

      final reference = VerseReference(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );
      if (translations.containsKey(reference)) {
        throw FormatException(
          'Duplicate Sorani translation for Surah $surahNumber, '
          'verse $verseNumber.',
        );
      }
      translations[reference] = (
        globalVerseNumber: globalVerseNumber,
        translation: translation,
      );
    }

    if (translations.length != expectedVerseCount) {
      throw FormatException(
        'Expected $expectedVerseCount Sorani translations; '
        'found ${translations.length}.',
      );
    }
    return Map.unmodifiable(translations);
  }
}
