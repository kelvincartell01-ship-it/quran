import '../audio/quran_audio_catalog.dart';
import '../domain/quran_verse.dart';
import '../domain/surah.dart';
import 'quran_text_data_source.dart';
import 'quran_verse_repository.dart';
import 'sorani_translation_data_source.dart';
import 'surah_metadata_data_source.dart';
import 'surah_repository.dart';

class LocalQuranAudioCatalog implements QuranAudioCatalog {
  LocalQuranAudioCatalog({
    required this.surahRepository,
    required this.verseRepository,
  });

  factory LocalQuranAudioCatalog.fromAssets() {
    final surahRepository = LocalSurahRepository(
      const AssetSurahMetadataDataSource(),
    );
    final verseRepository = LocalQuranVerseRepository(
      surahRepository: surahRepository,
      quranTextDataSource: const AssetQuranTextDataSource(),
      soraniTranslationDataSource: const AssetSoraniTranslationDataSource(),
    );
    return LocalQuranAudioCatalog(
      surahRepository: surahRepository,
      verseRepository: verseRepository,
    );
  }

  final SurahRepository surahRepository;
  final QuranVerseRepository verseRepository;
  Future<List<Surah>>? _surahs;
  Future<List<QuranVerse>>? _verses;

  Future<List<Surah>> get _allSurahs =>
      _surahs ??= surahRepository.getAllSurahs();

  Future<List<QuranVerse>> get _allVerses =>
      _verses ??= verseRepository.getAllVerses();

  @override
  Future<Surah?> getSurah(int number) async {
    for (final surah in await _allSurahs) {
      if (surah.number == number) return surah;
    }
    return null;
  }

  @override
  Future<List<QuranVerse>> getVerses(int surahNumber) async {
    final verses = (await _allVerses)
        .where((verse) => verse.surahNumber == surahNumber)
        .toList(growable: false);
    if (verses.isEmpty) {
      throw StateError('No verified verses exist for Surah $surahNumber.');
    }
    return List.unmodifiable(verses);
  }
}
