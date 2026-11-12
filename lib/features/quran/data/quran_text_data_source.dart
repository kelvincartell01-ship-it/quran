import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/quran_verse.dart';

typedef ArabicVerseText = ({String text, String? surahOpeningBismillah});

abstract interface class QuranTextDataSource {
  Future<Map<VerseReference, ArabicVerseText>> loadArabicVerses();
}

class AssetQuranTextDataSource implements QuranTextDataSource {
  const AssetQuranTextDataSource({this.bundle});

  static const assetPath = 'assets/data/quran-uthmani.json';
  static const expectedVerseCount = 6236;

  final AssetBundle? bundle;

  @override
  Future<Map<VerseReference, ArabicVerseText>> loadArabicVerses() async {
    final contents = await (bundle ?? rootBundle).loadString(assetPath);
    final decoded = jsonDecode(contents);
    final copyrightNotice = decoded is Map<String, dynamic>
        ? decoded['copyrightNotice']
        : null;
    if (decoded is! Map<String, dynamic> ||
        decoded['schemaVersion'] != 1 ||
        decoded['source'] != 'Tanzil Quran Text' ||
        decoded['version'] != '1.1' ||
        copyrightNotice is! String ||
        !copyrightNotice.startsWith('Tanzil Quran Text Copyright (C) 2007-') ||
        !copyrightNotice.endsWith(
          'Tanzil Project. License: Creative Commons Attribution 3.0',
        )) {
      throw const FormatException('Unsupported Tanzil Quran text format.');
    }

    final records = decoded['verses'];
    if (records is! List<dynamic>) {
      throw const FormatException('Tanzil data must contain a verse list.');
    }

    final verses = <VerseReference, ArabicVerseText>{};
    for (var index = 0; index < records.length; index++) {
      final record = records[index];
      if (record is! Map<String, dynamic>) {
        throw FormatException('Invalid Tanzil verse record ${index + 1}.');
      }

      final surahNumber = record['surahNumber'];
      final verseNumber = record['verseNumber'];
      final arabicText = record['arabicText'];
      final bismillah = record['surahOpeningBismillah'];
      if (surahNumber is! int ||
          verseNumber is! int ||
          arabicText is! String ||
          surahNumber < 1 ||
          surahNumber > 114 ||
          verseNumber < 1 ||
          arabicText.isEmpty) {
        throw FormatException(
          'Invalid Tanzil verse key or text at record ${index + 1}.',
        );
      }
      final String? surahOpeningBismillah;
      if (bismillah == null) {
        surahOpeningBismillah = null;
      } else if (bismillah is String &&
          bismillah.isNotEmpty &&
          verseNumber == 1) {
        surahOpeningBismillah = bismillah;
      } else {
        throw FormatException(
          'Invalid Surah-opening Bismillah at Surah $surahNumber, '
          'verse $verseNumber.',
        );
      }

      final reference = VerseReference(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );
      if (verses.containsKey(reference)) {
        throw FormatException(
          'Duplicate Tanzil verse ${reference.surahNumber}:'
          '${reference.verseNumber}.',
        );
      }
      verses[reference] = (
        text: arabicText,
        surahOpeningBismillah: surahOpeningBismillah,
      );
    }

    if (verses.length != expectedVerseCount) {
      throw FormatException(
        'Expected $expectedVerseCount Tanzil verses; found ${verses.length}.',
      );
    }
    return Map.unmodifiable(verses);
  }
}
