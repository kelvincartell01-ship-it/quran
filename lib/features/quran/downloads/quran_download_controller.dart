import '../audio/quran_reciter.dart';
import '../domain/quran_verse.dart';
import '../domain/surah.dart';
import 'quran_download_models.dart';

abstract interface class QuranDownloadController {
  bool get isSupported;
  String get selectedReciterId;
  QuranDownloadState get state;
  Stream<QuranDownloadState> get stateStream;

  Future<void> selectReciter(QuranReciter reciter);
  Future<void> downloadSurah({
    required Surah surah,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
  });
  Future<void> downloadAll({
    required List<Surah> surahs,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
  });
  Future<void> retrySurah({
    required Surah surah,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
  });
  Future<void> pauseSurah(String reciterId, int surahNumber);
  Future<void> resumeSurah({
    required Surah surah,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
  });
  Future<void> cancelSurah(String reciterId, int surahNumber);
  Future<void> pauseAll();
  Future<void> resumeAll({
    required List<Surah> surahs,
    required List<QuranVerse> verses,
    required List<QuranReciter> reciters,
  });
  Future<void> cancelAll();
  Future<void> deleteSurah(String reciterId, int surahNumber);
  Future<void> deleteReciterDownloads(String reciterId);
  Future<void> clearAll();
}

class UnavailableQuranDownloadController implements QuranDownloadController {
  const UnavailableQuranDownloadController();

  static final _error = UnsupportedError(
    'Quran audio downloads are unavailable on this platform.',
  );

  @override
  bool get isSupported => false;

  @override
  String get selectedReciterId => 'ar.alafasy';

  @override
  QuranDownloadState get state => const QuranDownloadState.unavailable();

  @override
  Stream<QuranDownloadState> get stateStream => const Stream.empty();

  @override
  Future<void> selectReciter(QuranReciter reciter) => Future.error(_error);

  @override
  Future<void> downloadSurah({
    required Surah surah,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
  }) => Future.error(_error);

  @override
  Future<void> downloadAll({
    required List<Surah> surahs,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
  }) => Future.error(_error);

  @override
  Future<void> retrySurah({
    required Surah surah,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
  }) => Future.error(_error);

  @override
  Future<void> pauseSurah(String reciterId, int surahNumber) =>
      Future.error(_error);

  @override
  Future<void> resumeSurah({
    required Surah surah,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
  }) => Future.error(_error);

  @override
  Future<void> cancelSurah(String reciterId, int surahNumber) =>
      Future.error(_error);

  @override
  Future<void> pauseAll() => Future.error(_error);

  @override
  Future<void> resumeAll({
    required List<Surah> surahs,
    required List<QuranVerse> verses,
    required List<QuranReciter> reciters,
  }) => Future.error(_error);

  @override
  Future<void> cancelAll() => Future.error(_error);

  @override
  Future<void> deleteSurah(String reciterId, int surahNumber) =>
      Future.error(_error);

  @override
  Future<void> deleteReciterDownloads(String reciterId) => Future.error(_error);

  @override
  Future<void> clearAll() => Future.error(_error);
}
