// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Central Kurdish (`ckb`).
class AppLocalizationsCkb extends AppLocalizations {
  AppLocalizationsCkb([String locale = 'ckb']) : super(locale);

  @override
  String get applicationTitle => 'قورئان';

  @override
  String get applicationSubtitle => 'شوێنێکی ئارام بۆ قورئان';

  @override
  String get navQuran => 'قورئان';

  @override
  String get navChannels => 'کەناڵەکان';

  @override
  String get navSettings => 'ڕێکخستن';

  @override
  String get quranWelcome => 'گەشتەکەت لەگەڵ قورئان';

  @override
  String get quranWelcomeBody => 'شوێنێکی ئارام بۆ خوێندنەوە و بیرکردنەوە.';

  @override
  String get quranContentUnavailable =>
      'خوێندنەوەی قورئان لە نوێکارییەکی داهاتوودا لێرە بەردەست دەبێت.';

  @override
  String get channelsTitle => 'کەناڵەکان';

  @override
  String get channelsDescription =>
      'پەڕەی پەخشی فەرمیی یەکێک لە دوو کەناڵی شارە پیرۆزەکان هەڵبژێرە.';

  @override
  String get makkahLiveName => 'پەخشی ڕاستەوخۆی مەککە';

  @override
  String get makkahLiveDescription => 'پەخشی ڕاستەوخۆ لە مەسجیدی حەرامەوە.';

  @override
  String get madinahLiveName => 'پەخشی ڕاستەوخۆی مەدینە';

  @override
  String get madinahLiveDescription => 'پەخشی ڕاستەوخۆ لە مەسجیدی نەبەوییەوە.';

  @override
  String get officialBroadcasterLabel => 'پەخشی فەرمی';

  @override
  String get openOfficialLivePage => 'کردنەوەی پەڕەی فەرمیی پەخش';

  @override
  String get openingOfficialLivePage => 'پەڕەی فەرمی دەکرێتەوە…';

  @override
  String get officialLivePageLabel =>
      'دەزگای تەلەفزیۆن و ڕادیۆی عەرەبستانی سعودی (SBA) · پەڕەی Aloula';

  @override
  String get channelInAppPlaybackUnverified =>
      'پەخشی فەرمیی ئێستای ناو ئەپ پشتڕاست نەکراوەتەوە. پەخشی پشتڕاستنەکراو یان نیشانی LIVE پیشان نادرێت؛ پەڕەی فەرمیی پەخش بکەر بکەرەوە.';

  @override
  String get officialLivePageOpenError =>
      'پەڕەی فەرمیی پەخش نەکرایەوە. پەیوەندیی ئینتەرنێتەکەت بپشکنە و دووبارە هەوڵبدەوە.';

  @override
  String get channelAudioPauseError =>
      'خوێندنەوەی قورئان نەوەستێنرا؛ بۆیە پەڕەی کەناڵ نەکرایەوە.';

  @override
  String get settingsTitle => 'ڕێکخستن';

  @override
  String get languageSection => 'زمان';

  @override
  String get languageLabel => 'زمانی ئەپ';

  @override
  String get languageSorani => 'کوردیی سۆرانی';

  @override
  String get languageArabic => 'عەرەبی';

  @override
  String get languageEnglish => 'ئینگلیزی';

  @override
  String get appearanceSection => 'ڕووکار';

  @override
  String get themeLabel => 'شێوازی ڕووکار';

  @override
  String get themeSystem => 'سیستەم';

  @override
  String get themeLight => 'ڕووناک';

  @override
  String get themeDark => 'تاریک';

  @override
  String get readingSection => 'خوێندنەوە';

  @override
  String get quranFontSize => 'قەبارەی نووسینی قورئان';

  @override
  String fontSizeValue(String size) {
    return '$size';
  }

  @override
  String get preferenceSaveError =>
      'پاشەکەوتکردنی هەڵبژاردەکەت سەرکەوتوو نەبوو. تکایە دووبارە هەوڵ بدەرەوە.';

  @override
  String get fontPreparationNote =>
      'فۆنتی Amiri Quran بە مۆڵەتی SIL OFL 1.1 بەکاردێت؛ ناوی فۆنتەکە واتای فۆنتی فەرمیی حەفسی نییە.';

  @override
  String get soraniFrameworkLocalizationNote =>
      'بەشێک لە پەیامەکانی ناوەوەی کۆنتڕۆڵەکانی Flutter بە عەرەبی پیشان دەدرێن، چونکە وەرگێڕانی سۆرانی بۆ کۆنتڕۆڵەکانی SDK بەردەست نییە.';

  @override
  String get surahsHeading => 'سوورەتەکان';

  @override
  String surahCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# سوورەت',
      one: '# سوورەت',
    );
    return '$_temp0';
  }

  @override
  String get searchSurahs => 'بگەڕێ بە ناو یان ژمارە';

  @override
  String get clearSearch => 'پاککردنەوەی گەڕان';

  @override
  String get noSurahsFound => 'هیچ سوورەتێک لەگەڵ گەڕانەکەت ناگونجێت.';

  @override
  String get surahLoadError => 'زانیاریی سوورەتەکان بارنەکرا.';

  @override
  String get retry => 'دووبارە هەوڵبدەوە';

  @override
  String get surahDetailTitle => 'وردەکاریی سوورەت';

  @override
  String get surahNotFound => 'ئەم سوورەتە نەدۆزرایەوە.';

  @override
  String surahNumber(int number) {
    return 'سوورەتی $number';
  }

  @override
  String get surahNumberLabel => 'ژمارە';

  @override
  String get verseCountLabel => 'ژمارەی ئایەتەکان';

  @override
  String verseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# ئایەت',
      one: '# ئایەت',
    );
    return '$_temp0';
  }

  @override
  String get revelationOrderLabel => 'ڕیزی دابەزین';

  @override
  String get makki => 'مەککی';

  @override
  String get madani => 'مەدەنی';

  @override
  String get surahDetailComingSoon =>
      'ئایەتەکانی قورئان و تایبەتمەندییەکانی خوێندنەوە لە قۆناغێکی داهاتوودا زیاد دەکرێن.';

  @override
  String get quranReaderTitle => 'خوێندنەوەی قورئان';

  @override
  String get quranReaderLoadError => 'دەقی قورئان یان واتای سۆرانی بارنەکرا.';

  @override
  String get verseMeaningLabel => 'واتای ئایەت';

  @override
  String verseNumber(int number) {
    return 'ئایەتی $number';
  }

  @override
  String get increaseQuranFontSize => 'گەورەکردنی نووسینی قورئان';

  @override
  String get decreaseQuranFontSize => 'بچووککردنی نووسینی قورئان';

  @override
  String get audioPlayerTitle => 'خوێندنەوەی قورئان';

  @override
  String get audioPlaybackUnavailable =>
      'پەخشی دەنگ لە ئەندرۆید و ئای ئۆ ئێس بەردەستە.';

  @override
  String get selectReciter => 'قاری';

  @override
  String get playSurah => 'پەخشکردنی سوورەت';

  @override
  String get resumeAudio => 'بەردەوامبوون لە خوێندنەوە';

  @override
  String get pauseAudio => 'وەستاندنی کاتیی خوێندنەوە';

  @override
  String playFromVerse(int verse) {
    return 'پەخشکردن لە ئایەتی $verse ـەوە';
  }

  @override
  String get previousVerse => 'ئایەتی پێشوو';

  @override
  String get nextVerse => 'ئایەتی دواتر';

  @override
  String get repeatModeLabel => 'شێوازی دووبارەکردنەوە';

  @override
  String get repeatOff => 'دووبارەکردنەوە ناچالاکە';

  @override
  String get repeatSurah => 'دووبارەکردنەوەی سوورەت';

  @override
  String get repeatVerse => 'دووبارەکردنەوەی ئایەت';

  @override
  String get audioLoading => 'خوێندنەوە بار دەکرێت…';

  @override
  String get audioPlaybackError =>
      'پەخشی دەنگ سەرکەوتوو نەبوو. پەیوەندیی ئینتەرنێتەکەت بپشکنە و دووبارە هەوڵبدەوە.';

  @override
  String get audioPermissionDenied =>
      'مۆڵەتی ئاگادارکردنەوە بدە بۆ پیشاندانی کۆنتڕۆڵەکانی پەخش.';

  @override
  String get audioProgressLabel => 'پێشکەوتنی خوێندنەوە';

  @override
  String get showAudioControls => 'پیشاندانی کۆنتڕۆڵەکانی دەنگ';

  @override
  String get hideAudioControls => 'شاردنەوەی کۆنتڕۆڵەکانی دەنگ';

  @override
  String get audioStreamingAttribution =>
      'دەنگەکان لە Al Quran Cloud ـەن؛ بە ئینتەرنێت گوێ بگرە یان سوورەتەکان بۆ گوێگرتنی بێ‌ئینتەرنێت دابگرە.';

  @override
  String get downloadSection => 'داگرتنی دەنگ';

  @override
  String get downloadReciter => 'قاریی داگرتن';

  @override
  String get downloadSurahAction => 'داگرتنی ئەم سوورەتە';

  @override
  String get downloadQuranAction => 'داگرتنی هەموو ١١٤ سوورەت';

  @override
  String get downloadAllConfirmationTitle => 'هەموو قورئان دابگریت؟';

  @override
  String downloadAllConfirmationBody(String reciter) {
    return 'هەموو ١١٤ سوورەت بۆ $reciter دەخرێنە ڕیزەوە. داگرتنەکان داتای مۆبایل و شوێنی پاشەکەوت بەکاردەهێنن؛ وایفای پێشنیار دەکرێت. تا پشتڕاست نەکەیتەوە هیچ داگرتنێک دەست پێ ناکات.';
  }

  @override
  String get downloadSizeUnavailable =>
      'پێش داواکردنی فایلە دەنگییەکان قەبارەی گشتی بە دڵنیایی نازانرێت.';

  @override
  String get downloadQueued => 'داگرتن خراوەتە ڕیزەوە.';

  @override
  String downloadProgress(int completed, int total) {
    return '$completed لە $total ئایەت پشتڕاستکراونەتەوە';
  }

  @override
  String downloadBatchProgress(int completed, int total) {
    return '$completed لە $total سوورەت تەواو بوون';
  }

  @override
  String downloadCurrentSurah(int surah, int verse) {
    return 'ئێستا: سوورەتی $surah، ئایەتی $verse';
  }

  @override
  String downloadCurrentFileProgress(String received, String total) {
    return 'بایتی ئایەتی ئێستا: $received / $total';
  }

  @override
  String get downloadWaiting => 'چاوەڕوانە';

  @override
  String get downloadDownloading => 'دادەگیرێت';

  @override
  String get downloadPaused => 'وەستێنراوە';

  @override
  String get downloadCompleted => 'داگیراوە';

  @override
  String get downloadFailed =>
      'تەواو نەبوو — ئایەتە سەرنەکەوتووەکان دووبارە دابگرە';

  @override
  String get downloadCancelled => 'هەڵوەشێنرایەوە';

  @override
  String get downloadNotDownloaded => 'داونەگیراوە';

  @override
  String get downloadPauseAll => 'هەمووی بوەستێنە';

  @override
  String get downloadResumeAll => 'هەمووی بەردەوام بکە';

  @override
  String get downloadCancelAll => 'هەمووی هەڵبوەشێنەوە';

  @override
  String get downloadPause => 'وەستاندنی داگرتن';

  @override
  String get downloadResume => 'بەردەوامبوون لە داگرتن';

  @override
  String get downloadCancel => 'هەڵوەشاندنەوەی داگرتن';

  @override
  String get downloadRetry => 'دووبارە داگرتنی ئایەتە سەرنەکەوتووەکان';

  @override
  String get downloadDelete => 'سڕینەوە';

  @override
  String get downloadDeleteAll => 'سڕینەوەی هەموو دەنگە داگیراوەکان';

  @override
  String get downloadDeleteAllConfirmation =>
      'هەموو دەنگە داگیراوەکانی قورئان لەم ئامێرە بسڕدرێنەوە؟ ئەم کارە ناگەڕێتەوە.';

  @override
  String get downloadDeleteReciter => 'سڕینەوەی داگرتنەکانی ئەم قارییە';

  @override
  String downloadStorageUsed(String size) {
    return 'شوێنی بەکارهاتوو: $size';
  }

  @override
  String get downloadedSurahs => 'سوورەتە داگیراوەکان';

  @override
  String get downloadNoItems => 'هێشتا هیچ دەنگێک دانەگیراوە.';

  @override
  String get downloadSourceAttribution =>
      'فایلە دەنگییەکان لە Al Quran Cloud ـەن و بۆ گوێگرتنی کەسی و فێرکارییەن؛ مافی تلاوەتەکان بۆ قاری و خاوەن مافەکانیان دەمێنێتەوە. https://alquran.cloud/cdn · https://alquran.cloud/terms-and-conditions';

  @override
  String get offlineAudioNotDownloaded =>
      'ئەم ئایەتە بۆ قاریی هەڵبژێردراو دانەگیراوە. بە ئینتەرنێت پەیوەست ببە یان بۆ پەخشی بێ‌ئینتەرنێت ئەم سوورەتە دابگرە.';

  @override
  String get downloadOperationError =>
      'داگرتن تەواو نەبوو. پەیوەندی و شوێنی بەردەست بپشکنە و دووبارە هەوڵبدەوە.';

  @override
  String get aboutSection => 'دەربارە';

  @override
  String get dataAttributionTitle => 'سەرچاوە و مۆڵەتەکان';

  @override
  String get surahMetadataAttribution =>
      'زانیاریی سوورەتەکان لە تانزیل، وەشانی 1.0، مۆڵەتی CC BY. ژمارەی ئایەت و جۆری دابەزین لەگەڵ Quran.com API v4 بەراورد کراوەتەوە. https://tanzil.net/docs/Quran_Metadata';

  @override
  String get quranTextAttribution =>
      'دەقی قورئانی تانزیل، وەشانی ١.١. مافی لەبەرگرتنەوە © ٢٠٠٧–٢٠٢٦ تانزیل. مۆڵەتی CC BY 3.0؛ دەقەکە بەبێ گۆڕانکاری بەکارهاتووە. https://tanzil.net/docs/Text_License';

  @override
  String get soraniDataAttribution =>
      'Holy Quran Kurdish Sorani Translation Dataset (HQKSTD). نووسەران: Shakhawan Hares Wady، Mhamad Bamoki، Soran Badawi. DOI: 10.17632/byyjd7kmvd.1. مۆڵەتی CC BY 4.0: https://creativecommons.org/licenses/by/4.0/ سەرچاوە: https://data.mendeley.com/datasets/byyjd7kmvd/1. بۆ ناو ئەپەکە گۆڕدراوەتە فۆرماتی JSON.';

  @override
  String get quranFontAttribution =>
      'فۆنتی Amiri Quran، پڕۆژەی Amiri، وەشانی 1.003. مۆڵەتی SIL Open Font License 1.1. https://github.com/aliftype/amiri';
}
