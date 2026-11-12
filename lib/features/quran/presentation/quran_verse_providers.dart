import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quran_text_data_source.dart';
import '../data/quran_verse_repository.dart';
import '../data/sorani_translation_data_source.dart';
import '../domain/quran_verse.dart';
import 'surah_providers.dart';

final quranTextDataSourceProvider = Provider<QuranTextDataSource>(
  (ref) => const AssetQuranTextDataSource(),
);

final soraniTranslationDataSourceProvider =
    Provider<SoraniTranslationDataSource>(
      (ref) => const AssetSoraniTranslationDataSource(),
    );

final quranVerseRepositoryProvider = Provider<QuranVerseRepository>(
  (ref) => LocalQuranVerseRepository(
    surahRepository: ref.watch(surahRepositoryProvider),
    quranTextDataSource: ref.watch(quranTextDataSourceProvider),
    soraniTranslationDataSource: ref.watch(soraniTranslationDataSourceProvider),
  ),
);

final quranVersesProvider = FutureProvider<List<QuranVerse>>(
  (ref) => ref.watch(quranVerseRepositoryProvider).getAllVerses(),
);

final quranVersesForSurahProvider =
    Provider.family<AsyncValue<List<QuranVerse>>, int>((ref, surahNumber) {
      return ref
          .watch(quranVersesProvider)
          .whenData(
            (verses) => List.unmodifiable(
              verses.where((verse) => verse.surahNumber == surahNumber),
            ),
          );
    });
