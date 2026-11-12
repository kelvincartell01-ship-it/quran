import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/surah_metadata_data_source.dart';
import '../data/surah_repository.dart';
import '../domain/surah.dart';

final surahMetadataDataSourceProvider = Provider<SurahMetadataDataSource>(
  (ref) => const AssetSurahMetadataDataSource(),
);

final surahRepositoryProvider = Provider<SurahRepository>(
  (ref) => LocalSurahRepository(ref.watch(surahMetadataDataSourceProvider)),
);

final surahsProvider = FutureProvider<List<Surah>>(
  (ref) => ref.watch(surahRepositoryProvider).getAllSurahs(),
);

final surahSearchQueryProvider =
    NotifierProvider<SurahSearchQueryController, String>(
      SurahSearchQueryController.new,
    );

final surahByNumberProvider = Provider.family<AsyncValue<Surah?>, int>((
  ref,
  number,
) {
  return ref.watch(surahsProvider).whenData((surahs) {
    for (final surah in surahs) {
      if (surah.number == number) {
        return surah;
      }
    }
    return null;
  });
});

class SurahSearchQueryController extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

List<Surah> filterSurahs(List<Surah> surahs, String query) {
  final normalizedQuery = _normalizeSearchText(query);
  if (normalizedQuery.isEmpty) {
    return surahs;
  }

  final surahNumber = int.tryParse(normalizedQuery);
  return surahs
      .where((surah) {
        if (surahNumber == surah.number) {
          return true;
        }

        return _normalizeSearchText(surah.arabicName)
                .contains(normalizedQuery) ||
            _normalizeSearchText(surah.transliteration)
                .contains(normalizedQuery);
      })
      .toList(growable: false);
}

String _normalizeSearchText(String value) {
  return value
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .toLowerCase()
      .replaceAll(RegExp(r'[\u0640\u064B-\u065F\u0670\u06D6-\u06ED]'), '');
}
