import '../domain/quran_verse.dart';
import '../domain/surah.dart';

abstract interface class QuranAudioCatalog {
  Future<Surah?> getSurah(int number);
  Future<List<QuranVerse>> getVerses(int surahNumber);
}
