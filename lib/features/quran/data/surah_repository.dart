import '../domain/surah.dart';
import 'surah_metadata_data_source.dart';

abstract interface class SurahRepository {
  Future<List<Surah>> getAllSurahs();
}

class LocalSurahRepository implements SurahRepository {
  const LocalSurahRepository(this._dataSource);

  final SurahMetadataDataSource _dataSource;

  @override
  Future<List<Surah>> getAllSurahs() => _dataSource.loadSurahs();
}
