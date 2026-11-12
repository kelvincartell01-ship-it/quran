import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran/data/quran_text_data_source.dart';
import 'package:quran/features/quran/data/quran_verse_repository.dart';
import 'package:quran/features/quran/data/sorani_translation_data_source.dart';
import 'package:quran/features/quran/data/surah_metadata_data_source.dart';
import 'package:quran/features/quran/data/surah_repository.dart';
import 'package:quran/features/quran/domain/quran_verse.dart';
import 'package:quran/features/quran/domain/surah.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Surah> surahs;
  late List<QuranVerse> verses;

  setUpAll(() async {
    final surahRepository = LocalSurahRepository(
      const AssetSurahMetadataDataSource(),
    );
    surahs = await surahRepository.getAllSurahs();
    verses = await LocalQuranVerseRepository(
      surahRepository: surahRepository,
      quranTextDataSource: const AssetQuranTextDataSource(),
      soraniTranslationDataSource: const AssetSoraniTranslationDataSource(),
    ).getAllVerses();
  });

  test('loads 6,236 verses in continuous canonical order', () {
    expect(surahs, hasLength(114));
    expect(verses, hasLength(6236));
    expect(
      verses.map((verse) => verse.globalVerseNumber),
      List<int>.generate(6236, (index) => index + 1),
    );

    for (final surah in surahs) {
      final surahVerses = verses
          .where((verse) => verse.surahNumber == surah.number)
          .toList();
      expect(
        surahVerses,
        hasLength(surah.verseCount),
        reason: 'Surah ${surah.number} has the metadata verse count.',
      );
      expect(
        surahVerses.map((verse) => verse.verseNumber),
        List<int>.generate(surah.verseCount, (index) => index + 1),
      );
    }
  });

  test('Al-Fatihah, Al-Baqarah, and An-Nas have aligned source verses', () {
    final fatihah = verses.where((verse) => verse.surahNumber == 1).toList();
    final baqarah = verses.where((verse) => verse.surahNumber == 2).toList();
    final nas = verses.where((verse) => verse.surahNumber == 114).toList();

    expect(fatihah, hasLength(7));
    expect(fatihah.first.arabicText, 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ');
    expect(fatihah.first.surahOpeningBismillah, isNull);
    expect(fatihah.first.soraniTranslation, 'بەناوی خوای بەخشندەی میهرەبان');
    expect(baqarah, hasLength(286));
    expect(baqarah.first.globalVerseNumber, 8);
    expect(baqarah.first.arabicText, 'الٓمٓ');
    expect(
      baqarah.first.surahOpeningBismillah,
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
    );
    expect(nas, hasLength(6));
    expect(nas.last.globalVerseNumber, 6236);
    expect(nas.last.arabicText, 'مِنَ ٱلْجِنَّةِ وَٱلنَّاسِ');
    expect(nas.last.soraniTranslation, 'لە جنۆکە و لە ئادەمیزاد');
  });

  test(
    'Arabic strings are preserved exactly from the Tanzil JSON asset',
    () async {
      final source = await rootBundle.loadString(
        AssetQuranTextDataSource.assetPath,
      );
      final decoded = jsonDecode(source) as Map<String, dynamic>;
      final sourceVerses = (decoded['verses'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      expect(sourceVerses, hasLength(6236));
      expect(
        decoded['copyrightNotice'],
        'Tanzil Quran Text Copyright (C) 2007-2026 Tanzil Project. '
        'License: Creative Commons Attribution 3.0',
      );
      expect(
        verses.map((verse) => verse.arabicText),
        sourceVerses.map((record) => record['arabicText']),
      );
      expect(
        verses.map((verse) => verse.surahOpeningBismillah),
        sourceVerses.map((record) => record['surahOpeningBismillah']),
      );
      expect(source, isNot(contains('\uFFFD')));
      expect(
        verses.map((verse) => verse.soraniTranslation),
        everyElement(isNotEmpty),
      );
    },
  );

  test('translation records align to the Arabic verse references', () async {
    final translations = await const AssetSoraniTranslationDataSource()
        .loadTranslations();

    expect(translations, hasLength(6236));
    for (final verse in verses) {
      final reference = VerseReference(
        surahNumber: verse.surahNumber,
        verseNumber: verse.verseNumber,
      );
      final translation = translations[reference];
      expect(
        translation,
        isNotNull,
        reason:
            'Missing translation for ${verse.surahNumber}:'
            '${verse.verseNumber}.',
      );
      expect(translation!.globalVerseNumber, verse.globalVerseNumber);
      expect(translation.translation, verse.soraniTranslation);
      expect(translation.translation.trim(), isNotEmpty);
    }
  });

  test(
    'local reader assets include the Quran font and both text datasets',
    () async {
      final arabicText = await rootBundle.loadString(
        AssetQuranTextDataSource.assetPath,
      );
      final soraniText = await rootBundle.loadString(
        AssetSoraniTranslationDataSource.assetPath,
      );
      final quranFont = await rootBundle.load('assets/fonts/AmiriQuran.ttf');
      final fontManifest = await rootBundle.loadString('FontManifest.json');

      expect(arabicText, contains('"verses"'));
      expect(soraniText, contains('"translations"'));
      expect(quranFont.lengthInBytes, greaterThan(0));
      expect(fontManifest, contains('AmiriQuran'));
    },
  );

  test('source contains Quranic marks, superscript alefs, and pause signs', () {
    final allArabicText = verses.map((verse) => verse.arabicText).join();

    for (final mark in ['ٰ', 'ۛ', 'ۖ', 'ۗ', 'ۚ', 'ۭ', '۩']) {
      expect(
        allArabicText,
        contains(mark),
        reason: 'The source retains $mark.',
      );
    }
  });

  test('long Surah Al-Baqarah remains available as individual verses', () {
    final baqarah = verses
        .where((verse) => verse.surahNumber == 2)
        .toList(growable: false);

    expect(baqarah, hasLength(286));
    expect(baqarah.first.verseNumber, 1);
    expect(baqarah.last.verseNumber, 286);
  });

  test('Surah-opening Bismillah is not paired with the verse translation', () {
    final baqarahFirst = verses.firstWhere(
      (verse) => verse.surahNumber == 2 && verse.verseNumber == 1,
    );
    final tawbahFirst = verses.firstWhere(
      (verse) => verse.surahNumber == 9 && verse.verseNumber == 1,
    );
    final nasFirst = verses.firstWhere(
      (verse) => verse.surahNumber == 114 && verse.verseNumber == 1,
    );

    expect(baqarahFirst.arabicText, 'الٓمٓ');
    expect(baqarahFirst.surahOpeningBismillah, isNotNull);
    expect(tawbahFirst.surahOpeningBismillah, isNull);
    expect(nasFirst.surahOpeningBismillah, isNotNull);
  });

  test('repository detects a Sorani global verse alignment mismatch', () async {
    final translationEntries = Map<VerseReference, SoraniTranslationEntry>.of(
      await const AssetSoraniTranslationDataSource().loadTranslations(),
    );
    final corruptedEntries = Map<VerseReference, SoraniTranslationEntry>.of(
      translationEntries,
    );
    const firstReference = VerseReference(surahNumber: 1, verseNumber: 1);
    const secondReference = VerseReference(surahNumber: 1, verseNumber: 2);
    corruptedEntries[firstReference] = translationEntries[secondReference]!;

    final repository = LocalQuranVerseRepository(
      surahRepository: LocalSurahRepository(
        const AssetSurahMetadataDataSource(),
      ),
      quranTextDataSource: const AssetQuranTextDataSource(),
      soraniTranslationDataSource: _FixedTranslationDataSource(
        corruptedEntries,
      ),
    );

    await expectLater(
      repository.getAllVerses(),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Surah 1, verse 1'),
        ),
      ),
    );
  });

  test(
    'repository reports a missing Sorani translation by verse key',
    () async {
      final translationEntries = Map<VerseReference, SoraniTranslationEntry>.of(
        await const AssetSoraniTranslationDataSource().loadTranslations(),
      );
      translationEntries.remove(
        const VerseReference(surahNumber: 1, verseNumber: 1),
      );
      final repository = LocalQuranVerseRepository(
        surahRepository: LocalSurahRepository(
          const AssetSurahMetadataDataSource(),
        ),
        quranTextDataSource: const AssetQuranTextDataSource(),
        soraniTranslationDataSource: _FixedTranslationDataSource(
          translationEntries,
        ),
      );

      await expectLater(
        repository.getAllVerses(),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Missing Sorani translation for Surah 1, verse 1'),
          ),
        ),
      );
    },
  );

  test('corrupted and missing source assets surface explicit errors', () async {
    final malformedArabic = AssetQuranTextDataSource(
      bundle: _MemoryAssetBundle({
        AssetQuranTextDataSource.assetPath: 'not a Tanzil record',
      }),
    );
    await expectLater(
      malformedArabic.loadArabicVerses(),
      throwsFormatException,
    );

    final missingArabic = AssetQuranTextDataSource(
      bundle: _MemoryAssetBundle({}, missingAssetsThrow: true),
    );
    await expectLater(
      missingArabic.loadArabicVerses(),
      throwsA(isA<FlutterError>()),
    );

    final malformedTranslation = AssetSoraniTranslationDataSource(
      bundle: _MemoryAssetBundle({
        AssetSoraniTranslationDataSource.assetPath: jsonEncode({
          'schemaVersion': 1,
          'translations': [],
        }),
      }),
    );
    await expectLater(
      malformedTranslation.loadTranslations(),
      throwsFormatException,
    );
  });
}

class _FixedTranslationDataSource implements SoraniTranslationDataSource {
  const _FixedTranslationDataSource(this.entries);

  final Map<VerseReference, SoraniTranslationEntry> entries;

  @override
  Future<Map<VerseReference, SoraniTranslationEntry>> loadTranslations() async {
    return entries;
  }
}

class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this.assets, {this.missingAssetsThrow = false});

  final Map<String, String> assets;
  final bool missingAssetsThrow;

  @override
  Future<ByteData> load(String key) async {
    final content = assets[key];
    if (content == null) {
      if (missingAssetsThrow) {
        throw FlutterError('Missing test asset: $key');
      }
      return ByteData.sublistView(Uint8List(0));
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
  }
}
