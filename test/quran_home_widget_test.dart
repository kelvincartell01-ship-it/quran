import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran/data/quran_text_data_source.dart';
import 'package:quran/features/quran/data/quran_verse_repository.dart';
import 'package:quran/features/quran/data/sorani_translation_data_source.dart';
import 'package:quran/features/quran/data/surah_metadata_data_source.dart';
import 'package:quran/features/quran/data/surah_repository.dart';
import 'package:quran/features/quran/domain/quran_verse.dart';
import 'package:quran/features/quran/domain/surah.dart';
import 'package:quran/features/quran/widget/quran_home_widget.dart';

late Surah testSurah;
late QuranVerse testVerse;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final surahRepository = LocalSurahRepository(
      const AssetSurahMetadataDataSource(),
    );
    final surahs = await surahRepository.getAllSurahs();
    testSurah = surahs.singleWhere((surah) => surah.number == 2);
    testVerse =
        (await LocalQuranVerseRepository(
          surahRepository: surahRepository,
          quranTextDataSource: const AssetQuranTextDataSource(),
          soraniTranslationDataSource: const AssetSoraniTranslationDataSource(),
        ).getAllVerses()).singleWhere(
          (verse) => verse.surahNumber == 2 && verse.verseNumber == 255,
        );
  });

  test('shares canonical Quran text in a versioned WidgetKit payload', () {
    final data = QuranHomeWidgetData.fromVerse(
      surah: testSurah,
      verse: testVerse,
    );

    expect(QuranHomeWidgetData.payloadKey, 'quran.widget.payload');
    expect(jsonDecode(data.toPayload()), {
      'schemaVersion': QuranHomeWidgetData.schemaVersion,
      'surahNumber': 2,
      'verseNumber': 255,
      'arabicSurahName': 'البقرة',
      'surahTransliteration': testSurah.transliteration,
      'arabicText': testVerse.arabicText,
      'soraniTranslation': testVerse.soraniTranslation,
    });
    expect(QuranHomeWidgetData.appGroupId, 'group.com.example.quran');
  });

  test('widget URI opens the exact Surah and Ayah route', () {
    final data = QuranHomeWidgetData.fromVerse(
      surah: testSurah,
      verse: testVerse,
    );

    expect(
      QuranHomeWidgetData.routeLocation(data.widgetUri),
      '/quran/surah/2?ayah=255',
    );
  });

  test('requires an Ayah that belongs to the supplied Surah', () {
    expect(
      () => QuranHomeWidgetData.fromVerse(
        surah: testSurah,
        verse: const QuranVerse(
          surahNumber: 3,
          verseNumber: 1,
          globalVerseNumber: 1,
          arabicText: '',
          soraniTranslation: '',
        ),
      ),
      throwsArgumentError,
    );
  });

  test('rejects invalid Surah and Ayah widget links', () {
    expect(
      QuranHomeWidgetData.routeLocation(
        Uri.parse('quran:///quran/surah/115?ayah=1&homeWidget'),
      ),
      isNull,
    );
    expect(
      QuranHomeWidgetData.routeLocation(
        Uri.parse('quran:///quran/surah/2?ayah=0&homeWidget'),
      ),
      isNull,
    );
    expect(
      QuranHomeWidgetData.routeLocation(
        Uri.parse('quran:///quran/surah/2?ayah=287&homeWidget'),
      ),
      isNull,
    );
  });

  test('rejects out-of-range Ayahs when creating widget data', () {
    expect(
      () => QuranHomeWidgetData.fromVerse(
        surah: testSurah,
        verse: const QuranVerse(
          surahNumber: 2,
          verseNumber: 287,
          globalVerseNumber: 288,
          arabicText: 'text',
          soraniTranslation: 'text',
        ),
      ),
      throwsArgumentError,
    );
  });

  test('requires both Arabic and Sorani Ayah text', () {
    final versesWithMissingText = [
      QuranVerse(
        surahNumber: testVerse.surahNumber,
        verseNumber: testVerse.verseNumber,
        globalVerseNumber: testVerse.globalVerseNumber,
        arabicText: ' ',
        soraniTranslation: testVerse.soraniTranslation,
      ),
      QuranVerse(
        surahNumber: testVerse.surahNumber,
        verseNumber: testVerse.verseNumber,
        globalVerseNumber: testVerse.globalVerseNumber,
        arabicText: testVerse.arabicText,
        soraniTranslation: '',
      ),
    ];
    for (final verse in versesWithMissingText) {
      expect(
        () => QuranHomeWidgetData.fromVerse(surah: testSurah, verse: verse),
        throwsArgumentError,
      );
    }

    final invalidData = QuranHomeWidgetData(
      surahNumber: 2,
      verseNumber: 255,
      arabicSurahName: 'البقرة',
      surahTransliteration: testSurah.transliteration,
      arabicText: testVerse.arabicText,
      soraniTranslation: ' ',
    );
    expect(invalidData.widgetUri, isNull);
    expect(invalidData.toPayload, throwsArgumentError);
  });

  test('returns an empty result for malformed or unsupported payloads', () {
    expect(QuranHomeWidgetData.fromPayload('{not json'), isNull);
    expect(
      QuranHomeWidgetData.fromPayload(jsonEncode({'schemaVersion': 2})),
      isNull,
    );
    expect(
      QuranHomeWidgetData.fromPayload(
        jsonEncode({
          'schemaVersion': 1,
          'surahNumber': 2,
          'verseNumber': 287,
          'arabicSurahName': 'البقرة',
          'surahTransliteration': testSurah.transliteration,
          'arabicText': 'text',
          'soraniTranslation': 'text',
        }),
      ),
      isNull,
    );
    final validPayload = jsonDecode(
      QuranHomeWidgetData.fromVerse(
        surah: testSurah,
        verse: testVerse,
      ).toPayload(),
    ) as Map<String, dynamic>;
    expect(
      QuranHomeWidgetData.fromPayload(
        jsonEncode({...validPayload, 'arabicText': ' '}),
      ),
      isNull,
    );
    expect(
      QuranHomeWidgetData.fromPayload(
        jsonEncode({...validPayload}..remove('soraniTranslation')),
      ),
      isNull,
    );
  });

  test('valid payloads retain exact navigation and required content', () {
    final data = QuranHomeWidgetData.fromVerse(
      surah: testSurah,
      verse: testVerse,
    );
    final restored = QuranHomeWidgetData.fromPayload(data.toPayload());

    expect(restored?.arabicText, testVerse.arabicText);
    expect(restored?.soraniTranslation, testVerse.soraniTranslation);
    expect(
      QuranHomeWidgetData.routeLocation(restored?.widgetUri),
      '/quran/surah/2?ayah=255',
    );
  });

  test('canonical verse counts match the bundled Surah metadata', () async {
    final surahs = await LocalSurahRepository(
      const AssetSurahMetadataDataSource(),
    ).getAllSurahs();

    for (final surah in surahs) {
      expect(
        QuranHomeWidgetData.verseCountForSurah(surah.number),
        surah.verseCount,
      );
    }
    expect(QuranHomeWidgetData.verseCountForSurah(0), isNull);
    expect(QuranHomeWidgetData.verseCountForSurah(115), isNull);
  });
}
