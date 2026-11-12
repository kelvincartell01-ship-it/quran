import '../domain/quran_verse.dart';
import 'quran_reciter.dart';

Uri quranAudioUriForVerse(QuranVerse verse, QuranReciter reciter) => Uri.https(
  'cdn.islamic.network',
  '/quran/audio/${reciter.bitrateKbps}/${reciter.identifier}/'
      '${verse.globalVerseNumber}.mp3',
);
