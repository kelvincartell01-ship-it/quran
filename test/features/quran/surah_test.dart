import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran/data/surah_metadata_data_source.dart';
import 'package:quran/features/quran/data/surah_repository.dart';
import 'package:quran/features/quran/domain/surah.dart';
import 'package:quran/features/quran/presentation/surah_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Surah> loadedSurahs;

  setUpAll(() async {
    loadedSurahs = await const LocalSurahRepository(
      AssetSurahMetadataDataSource(),
    ).getAllSurahs();
  });

  test('offline metadata has 114 unique Surahs in canonical order', () {
    expect(loadedSurahs, hasLength(114));
    final numbers = loadedSurahs.map((surah) => surah.number).toList();
    expect(numbers.toSet(), hasLength(114));
    expect(numbers, List<int>.generate(114, (index) => index + 1));
    expect(loadedSurahs.first.arabicName, 'الفاتحة');
    expect(loadedSurahs.last.arabicName, 'الناس');
  });

  test('verse counts are positive and total 6,236', () {
    final verseCounts = loadedSurahs
        .map<int>((surah) => surah.verseCount)
        .toList();
    expect(verseCounts.every((count) => count > 0), isTrue);
    expect(verseCounts.reduce((sum, count) => sum + count), 6236);
  });

  test('search matches Arabic names, transliteration, and Surah numbers', () {
    expect(filterSurahs(loadedSurahs, 'الفَاتِحَة').single.number, 1);
    expect(filterSurahs(loadedSurahs, '  Al-Faatiha  ').single.number, 1);
    expect(filterSurahs(loadedSurahs, ' 0114 ').single.number, 114);
  });

  test(
    'blank search returns all records and unmatched search returns none',
    () {
      expect(filterSurahs(loadedSurahs, ' \t\n '), hasLength(114));
      expect(filterSurahs(loadedSurahs, 'not a surah'), isEmpty);
    },
  );
}
