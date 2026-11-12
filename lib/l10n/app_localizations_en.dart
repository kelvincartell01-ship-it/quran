// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get applicationTitle => 'Quran';

  @override
  String get applicationSubtitle => 'A calm space for the Quran';

  @override
  String get navQuran => 'Quran';

  @override
  String get navChannels => 'Channels';

  @override
  String get navSettings => 'Settings';

  @override
  String get quranWelcome => 'Your Quran journey';

  @override
  String get quranWelcomeBody => 'A quiet place to read, listen, and reflect.';

  @override
  String get quranContentUnavailable =>
      'Quran reading will be available here in a future update.';

  @override
  String get channelsTitle => 'Channels';

  @override
  String get channelsDescription =>
      'Choose an official broadcast page for one of the two holy-city channels.';

  @override
  String get makkahLiveName => 'Makkah Live';

  @override
  String get makkahLiveDescription => 'Live broadcast from Masjid al-Haram.';

  @override
  String get madinahLiveName => 'Madinah Live';

  @override
  String get madinahLiveDescription =>
      'Live broadcast from Al-Masjid an-Nabawi.';

  @override
  String get officialBroadcasterLabel => 'Official broadcaster';

  @override
  String get openOfficialLivePage => 'Open official live page';

  @override
  String get openingOfficialLivePage => 'Opening official page…';

  @override
  String get officialLivePageLabel =>
      'Saudi Broadcasting Authority (SBA) · Aloula live page';

  @override
  String get channelInAppPlaybackUnverified =>
      'A current official in-app stream could not be verified. No unverified feed or LIVE status is shown; use the broadcaster’s official page.';

  @override
  String get officialLivePageOpenError =>
      'The official live page could not be opened. Check your connection and try again.';

  @override
  String get channelAudioPauseError =>
      'Quran recitation could not be paused, so the channel page was not opened.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageSection => 'Language';

  @override
  String get languageLabel => 'App language';

  @override
  String get languageSorani => 'Sorani Kurdish';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get languageEnglish => 'English';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get readingSection => 'Reading';

  @override
  String get quranFontSize => 'Quran text size';

  @override
  String fontSizeValue(String size) {
    return '$size';
  }

  @override
  String get preferenceSaveError =>
      'Your preference could not be saved. Please try again.';

  @override
  String get fontPreparationNote =>
      'Amiri Quran is bundled under SIL OFL 1.1; its name does not assert an official Hafs edition.';

  @override
  String get soraniFrameworkLocalizationNote =>
      'Flutter-owned control labels use Arabic in Sorani mode because the SDK does not provide Sorani framework translations.';

  @override
  String get surahsHeading => 'Surahs';

  @override
  String surahCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# Surahs',
      one: '# Surah',
    );
    return '$_temp0';
  }

  @override
  String get searchSurahs => 'Search by name or number';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get noSurahsFound => 'No Surahs match your search.';

  @override
  String get surahLoadError => 'Surah information could not be loaded.';

  @override
  String get retry => 'Try again';

  @override
  String get surahDetailTitle => 'Surah details';

  @override
  String get surahNotFound => 'This Surah could not be found.';

  @override
  String surahNumber(int number) {
    return 'Surah $number';
  }

  @override
  String get surahNumberLabel => 'Number';

  @override
  String get verseCountLabel => 'Verses';

  @override
  String verseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# verses',
      one: '# verse',
    );
    return '$_temp0';
  }

  @override
  String get revelationOrderLabel => 'Revelation order';

  @override
  String get makki => 'Makki';

  @override
  String get madani => 'Madani';

  @override
  String get surahDetailComingSoon =>
      'Quran verses and reading features will be added in a later phase.';

  @override
  String get quranReaderTitle => 'Quran reading';

  @override
  String get quranReaderLoadError =>
      'Quran text or Sorani meanings could not be loaded.';

  @override
  String get verseMeaningLabel => 'Verse meaning';

  @override
  String verseNumber(int number) {
    return 'Verse $number';
  }

  @override
  String get increaseQuranFontSize => 'Increase Quran font size';

  @override
  String get decreaseQuranFontSize => 'Decrease Quran font size';

  @override
  String get audioPlayerTitle => 'Quran recitation';

  @override
  String get audioPlaybackUnavailable =>
      'Audio playback is available on Android and iOS.';

  @override
  String get selectReciter => 'Reciter';

  @override
  String get playSurah => 'Play this Surah';

  @override
  String get resumeAudio => 'Resume recitation';

  @override
  String get pauseAudio => 'Pause recitation';

  @override
  String playFromVerse(int verse) {
    return 'Play from verse $verse';
  }

  @override
  String get previousVerse => 'Previous verse';

  @override
  String get nextVerse => 'Next verse';

  @override
  String get repeatModeLabel => 'Repeat mode';

  @override
  String get repeatOff => 'Repeat off';

  @override
  String get repeatSurah => 'Repeat Surah';

  @override
  String get repeatVerse => 'Repeat verse';

  @override
  String get audioLoading => 'Loading recitation…';

  @override
  String get audioPlaybackError =>
      'Audio could not be played. Check your connection and try again.';

  @override
  String get audioPermissionDenied =>
      'Allow notifications to show playback controls.';

  @override
  String get audioProgressLabel => 'Recitation progress';

  @override
  String get showAudioControls => 'Show audio controls';

  @override
  String get hideAudioControls => 'Hide audio controls';

  @override
  String get audioStreamingAttribution =>
      'Audio by Al Quran Cloud. Stream with internet or download Surahs for offline listening.';

  @override
  String get downloadSection => 'Audio downloads';

  @override
  String get downloadReciter => 'Download reciter';

  @override
  String get downloadSurahAction => 'Download this Surah';

  @override
  String get downloadQuranAction => 'Download all 114 Surahs';

  @override
  String get downloadAllConfirmationTitle => 'Download the complete Quran?';

  @override
  String downloadAllConfirmationBody(String reciter) {
    return 'This will queue all 114 Surahs for $reciter. Downloads use mobile data and storage; Wi-Fi is recommended. Nothing starts until you confirm.';
  }

  @override
  String get downloadSizeUnavailable =>
      'A reliable total size estimate is not available before the audio files are requested.';

  @override
  String get downloadQueued => 'Download queued.';

  @override
  String downloadProgress(int completed, int total) {
    return '$completed of $total verses verified';
  }

  @override
  String downloadBatchProgress(int completed, int total) {
    return '$completed of $total Surahs complete';
  }

  @override
  String downloadCurrentSurah(int surah, int verse) {
    return 'Current: Surah $surah, verse $verse';
  }

  @override
  String downloadCurrentFileProgress(String received, String total) {
    return 'Current verse bytes: $received / $total';
  }

  @override
  String get downloadWaiting => 'Waiting';

  @override
  String get downloadDownloading => 'Downloading';

  @override
  String get downloadPaused => 'Paused';

  @override
  String get downloadCompleted => 'Downloaded';

  @override
  String get downloadFailed => 'Incomplete — retry failed verses';

  @override
  String get downloadCancelled => 'Cancelled';

  @override
  String get downloadNotDownloaded => 'Not downloaded';

  @override
  String get downloadPauseAll => 'Pause all';

  @override
  String get downloadResumeAll => 'Resume all';

  @override
  String get downloadCancelAll => 'Cancel all';

  @override
  String get downloadPause => 'Pause download';

  @override
  String get downloadResume => 'Resume download';

  @override
  String get downloadCancel => 'Cancel download';

  @override
  String get downloadRetry => 'Retry failed verses';

  @override
  String get downloadDelete => 'Delete';

  @override
  String get downloadDeleteAll => 'Clear all downloaded audio';

  @override
  String get downloadDeleteAllConfirmation =>
      'Delete all downloaded Quran audio from this device? This cannot be undone.';

  @override
  String get downloadDeleteReciter => 'Delete this reciter\'s downloads';

  @override
  String downloadStorageUsed(String size) {
    return 'Storage used: $size';
  }

  @override
  String get downloadedSurahs => 'Downloaded Surahs';

  @override
  String get downloadNoItems => 'No downloaded audio yet.';

  @override
  String get downloadSourceAttribution =>
      'Audio files are from Al Quran Cloud (edition IDs retained) for personal and educational listening. Recitation rights remain with their respective reciters or estates. https://alquran.cloud/cdn · https://alquran.cloud/terms-and-conditions';

  @override
  String get offlineAudioNotDownloaded =>
      'This verse is not downloaded for the selected reciter. Connect to the internet or download this Surah for offline playback.';

  @override
  String get downloadOperationError =>
      'The download could not be completed. Check your connection and available storage, then try again.';

  @override
  String get aboutSection => 'About';

  @override
  String get dataAttributionTitle => 'Sources and licenses';

  @override
  String get surahMetadataAttribution =>
      'Surah metadata from Tanzil Quran Metadata, Version 1.0, CC BY. Verse counts and revelation places were cross-checked with Quran.com API v4. https://tanzil.net/docs/Quran_Metadata';

  @override
  String get quranTextAttribution =>
      'Tanzil Quran Text, Version 1.1. Copyright © 2007–2026 Tanzil Project. CC BY 3.0; text used verbatim without changes. https://tanzil.net/docs/Text_License';

  @override
  String get soraniDataAttribution =>
      'Holy Quran Kurdish Sorani Translation Dataset (HQKSTD). Contributors: Shakhawan Hares Wady, Mhamad Bamoki, and Soran Badawi. DOI: 10.17632/byyjd7kmvd.1. CC BY 4.0: https://creativecommons.org/licenses/by/4.0/. Source: https://data.mendeley.com/datasets/byyjd7kmvd/1. Converted to the app\'s local JSON format.';

  @override
  String get quranFontAttribution =>
      'Amiri Quran font, Amiri Project, version 1.003. SIL Open Font License 1.1. https://github.com/aliftype/amiri';
}
