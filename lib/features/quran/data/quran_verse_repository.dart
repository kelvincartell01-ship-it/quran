import '../domain/quran_verse.dart';
import 'quran_text_data_source.dart';
import 'sorani_translation_data_source.dart';
import 'surah_repository.dart';

abstract interface class QuranVerseRepository {
  Future<List<QuranVerse>> getAllVerses();
}

class LocalQuranVerseRepository implements QuranVerseRepository {
  const LocalQuranVerseRepository({
    required this.surahRepository,
    required this.quranTextDataSource,
    required this.soraniTranslationDataSource,
  });

  static const expectedVerseCount = 6236;

  final SurahRepository surahRepository;
  final QuranTextDataSource quranTextDataSource;
  final SoraniTranslationDataSource soraniTranslationDataSource;

  @override
  Future<List<QuranVerse>> getAllVerses() async {
    final surahs = await surahRepository.getAllSurahs();
    final arabicVerses = await quranTextDataSource.loadArabicVerses();
    final translations = await soraniTranslationDataSource.loadTranslations();
    final verses = <QuranVerse>[];
    var globalVerseNumber = 0;

    for (final surah in surahs) {
      for (
        var verseNumber = 1;
        verseNumber <= surah.verseCount;
        verseNumber++
      ) {
        globalVerseNumber++;
        final reference = VerseReference(
          surahNumber: surah.number,
          verseNumber: verseNumber,
        );
        final arabicVerse = arabicVerses[reference];
        final translation = translations[reference];
        if (arabicVerse == null) {
          throw FormatException(
            'Missing Tanzil text for Surah ${surah.number}, '
            'verse $verseNumber.',
          );
        }
        if (translation == null) {
          throw FormatException(
            'Missing Sorani translation for Surah ${surah.number}, '
            'verse $verseNumber.',
          );
        }
        if (translation.globalVerseNumber != globalVerseNumber) {
          throw FormatException(
            'Sorani global verse number mismatch at Surah ${surah.number}, '
            'verse $verseNumber: expected $globalVerseNumber, '
            'found ${translation.globalVerseNumber}.',
          );
        }

        verses.add(
          QuranVerse(
            surahNumber: surah.number,
            verseNumber: verseNumber,
            globalVerseNumber: globalVerseNumber,
            arabicText: arabicVerse.text,
            surahOpeningBismillah: arabicVerse.surahOpeningBismillah,
            soraniTranslation: translation.translation,
          ),
        );
      }
    }

    if (globalVerseNumber != expectedVerseCount ||
        arabicVerses.length != expectedVerseCount ||
        translations.length != expectedVerseCount) {
      throw FormatException(
        'Quran data must contain exactly $expectedVerseCount aligned verses.',
      );
    }
    return List.unmodifiable(verses);
  }
}
