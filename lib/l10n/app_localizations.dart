import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_ckb.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('ckb'),
    Locale('en'),
  ];

  /// No description provided for @applicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get applicationTitle;

  /// No description provided for @applicationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A calm space for the Quran'**
  String get applicationSubtitle;

  /// No description provided for @navQuran.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get navQuran;

  /// No description provided for @navChannels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get navChannels;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @quranWelcome.
  ///
  /// In en, this message translates to:
  /// **'Your Quran journey'**
  String get quranWelcome;

  /// No description provided for @quranWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'A quiet place to read, listen, and reflect.'**
  String get quranWelcomeBody;

  /// No description provided for @quranContentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Quran reading will be available here in a future update.'**
  String get quranContentUnavailable;

  /// No description provided for @channelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get channelsTitle;

  /// No description provided for @channelsDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose an official broadcast page for one of the two holy-city channels.'**
  String get channelsDescription;

  /// No description provided for @makkahLiveName.
  ///
  /// In en, this message translates to:
  /// **'Makkah Live'**
  String get makkahLiveName;

  /// No description provided for @makkahLiveDescription.
  ///
  /// In en, this message translates to:
  /// **'Live broadcast from Masjid al-Haram.'**
  String get makkahLiveDescription;

  /// No description provided for @madinahLiveName.
  ///
  /// In en, this message translates to:
  /// **'Madinah Live'**
  String get madinahLiveName;

  /// No description provided for @madinahLiveDescription.
  ///
  /// In en, this message translates to:
  /// **'Live broadcast from Al-Masjid an-Nabawi.'**
  String get madinahLiveDescription;

  /// No description provided for @officialBroadcasterLabel.
  ///
  /// In en, this message translates to:
  /// **'Official broadcaster'**
  String get officialBroadcasterLabel;

  /// No description provided for @openOfficialLivePage.
  ///
  /// In en, this message translates to:
  /// **'Open official live page'**
  String get openOfficialLivePage;

  /// No description provided for @openingOfficialLivePage.
  ///
  /// In en, this message translates to:
  /// **'Opening official page…'**
  String get openingOfficialLivePage;

  /// No description provided for @officialLivePageLabel.
  ///
  /// In en, this message translates to:
  /// **'Saudi Broadcasting Authority (SBA) · Aloula live page'**
  String get officialLivePageLabel;

  /// No description provided for @channelInAppPlaybackUnverified.
  ///
  /// In en, this message translates to:
  /// **'A current official in-app stream could not be verified. No unverified feed or LIVE status is shown; use the broadcaster’s official page.'**
  String get channelInAppPlaybackUnverified;

  /// No description provided for @officialLivePageOpenError.
  ///
  /// In en, this message translates to:
  /// **'The official live page could not be opened. Check your connection and try again.'**
  String get officialLivePageOpenError;

  /// No description provided for @channelAudioPauseError.
  ///
  /// In en, this message translates to:
  /// **'Quran recitation could not be paused, so the channel page was not opened.'**
  String get channelAudioPauseError;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSection;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get languageLabel;

  /// No description provided for @languageSorani.
  ///
  /// In en, this message translates to:
  /// **'Sorani Kurdish'**
  String get languageSorani;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @appearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @readingSection.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get readingSection;

  /// No description provided for @quranFontSize.
  ///
  /// In en, this message translates to:
  /// **'Quran text size'**
  String get quranFontSize;

  /// No description provided for @fontSizeValue.
  ///
  /// In en, this message translates to:
  /// **'{size}'**
  String fontSizeValue(String size);

  /// No description provided for @preferenceSaveError.
  ///
  /// In en, this message translates to:
  /// **'Your preference could not be saved. Please try again.'**
  String get preferenceSaveError;

  /// No description provided for @fontPreparationNote.
  ///
  /// In en, this message translates to:
  /// **'Amiri Quran is bundled under SIL OFL 1.1; its name does not assert an official Hafs edition.'**
  String get fontPreparationNote;

  /// No description provided for @soraniFrameworkLocalizationNote.
  ///
  /// In en, this message translates to:
  /// **'Flutter-owned control labels use Arabic in Sorani mode because the SDK does not provide Sorani framework translations.'**
  String get soraniFrameworkLocalizationNote;

  /// No description provided for @surahsHeading.
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get surahsHeading;

  /// No description provided for @surahCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{# Surah} other{# Surahs}}'**
  String surahCount(int count);

  /// No description provided for @searchSurahs.
  ///
  /// In en, this message translates to:
  /// **'Search by name or number'**
  String get searchSurahs;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @noSurahsFound.
  ///
  /// In en, this message translates to:
  /// **'No Surahs match your search.'**
  String get noSurahsFound;

  /// No description provided for @surahLoadError.
  ///
  /// In en, this message translates to:
  /// **'Surah information could not be loaded.'**
  String get surahLoadError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @surahDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Surah details'**
  String get surahDetailTitle;

  /// No description provided for @surahNotFound.
  ///
  /// In en, this message translates to:
  /// **'This Surah could not be found.'**
  String get surahNotFound;

  /// No description provided for @surahNumber.
  ///
  /// In en, this message translates to:
  /// **'Surah {number}'**
  String surahNumber(int number);

  /// No description provided for @surahNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get surahNumberLabel;

  /// No description provided for @verseCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Verses'**
  String get verseCountLabel;

  /// No description provided for @verseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{# verse} other{# verses}}'**
  String verseCount(int count);

  /// No description provided for @revelationOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Revelation order'**
  String get revelationOrderLabel;

  /// No description provided for @makki.
  ///
  /// In en, this message translates to:
  /// **'Makki'**
  String get makki;

  /// No description provided for @madani.
  ///
  /// In en, this message translates to:
  /// **'Madani'**
  String get madani;

  /// No description provided for @surahDetailComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Quran verses and reading features will be added in a later phase.'**
  String get surahDetailComingSoon;

  /// No description provided for @quranReaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Quran reading'**
  String get quranReaderTitle;

  /// No description provided for @quranReaderLoadError.
  ///
  /// In en, this message translates to:
  /// **'Quran text or Sorani meanings could not be loaded.'**
  String get quranReaderLoadError;

  /// No description provided for @verseMeaningLabel.
  ///
  /// In en, this message translates to:
  /// **'Verse meaning'**
  String get verseMeaningLabel;

  /// No description provided for @verseNumber.
  ///
  /// In en, this message translates to:
  /// **'Verse {number}'**
  String verseNumber(int number);

  /// No description provided for @increaseQuranFontSize.
  ///
  /// In en, this message translates to:
  /// **'Increase Quran font size'**
  String get increaseQuranFontSize;

  /// No description provided for @decreaseQuranFontSize.
  ///
  /// In en, this message translates to:
  /// **'Decrease Quran font size'**
  String get decreaseQuranFontSize;

  /// No description provided for @audioPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Quran recitation'**
  String get audioPlayerTitle;

  /// No description provided for @audioPlaybackUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Audio playback is available on Android and iOS.'**
  String get audioPlaybackUnavailable;

  /// No description provided for @selectReciter.
  ///
  /// In en, this message translates to:
  /// **'Reciter'**
  String get selectReciter;

  /// No description provided for @playSurah.
  ///
  /// In en, this message translates to:
  /// **'Play this Surah'**
  String get playSurah;

  /// No description provided for @resumeAudio.
  ///
  /// In en, this message translates to:
  /// **'Resume recitation'**
  String get resumeAudio;

  /// No description provided for @pauseAudio.
  ///
  /// In en, this message translates to:
  /// **'Pause recitation'**
  String get pauseAudio;

  /// No description provided for @playFromVerse.
  ///
  /// In en, this message translates to:
  /// **'Play from verse {verse}'**
  String playFromVerse(int verse);

  /// No description provided for @previousVerse.
  ///
  /// In en, this message translates to:
  /// **'Previous verse'**
  String get previousVerse;

  /// No description provided for @nextVerse.
  ///
  /// In en, this message translates to:
  /// **'Next verse'**
  String get nextVerse;

  /// No description provided for @repeatModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat mode'**
  String get repeatModeLabel;

  /// No description provided for @repeatOff.
  ///
  /// In en, this message translates to:
  /// **'Repeat off'**
  String get repeatOff;

  /// No description provided for @repeatSurah.
  ///
  /// In en, this message translates to:
  /// **'Repeat Surah'**
  String get repeatSurah;

  /// No description provided for @repeatVerse.
  ///
  /// In en, this message translates to:
  /// **'Repeat verse'**
  String get repeatVerse;

  /// No description provided for @audioLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading recitation…'**
  String get audioLoading;

  /// No description provided for @audioPlaybackError.
  ///
  /// In en, this message translates to:
  /// **'Audio could not be played. Check your connection and try again.'**
  String get audioPlaybackError;

  /// No description provided for @audioPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications to show playback controls.'**
  String get audioPermissionDenied;

  /// No description provided for @audioProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Recitation progress'**
  String get audioProgressLabel;

  /// No description provided for @showAudioControls.
  ///
  /// In en, this message translates to:
  /// **'Show audio controls'**
  String get showAudioControls;

  /// No description provided for @hideAudioControls.
  ///
  /// In en, this message translates to:
  /// **'Hide audio controls'**
  String get hideAudioControls;

  /// No description provided for @audioStreamingAttribution.
  ///
  /// In en, this message translates to:
  /// **'Audio by Al Quran Cloud. Stream with internet or download Surahs for offline listening.'**
  String get audioStreamingAttribution;

  /// No description provided for @downloadSection.
  ///
  /// In en, this message translates to:
  /// **'Audio downloads'**
  String get downloadSection;

  /// No description provided for @downloadReciter.
  ///
  /// In en, this message translates to:
  /// **'Download reciter'**
  String get downloadReciter;

  /// No description provided for @downloadSurahAction.
  ///
  /// In en, this message translates to:
  /// **'Download this Surah'**
  String get downloadSurahAction;

  /// No description provided for @downloadQuranAction.
  ///
  /// In en, this message translates to:
  /// **'Download all 114 Surahs'**
  String get downloadQuranAction;

  /// No description provided for @downloadAllConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Download the complete Quran?'**
  String get downloadAllConfirmationTitle;

  /// No description provided for @downloadAllConfirmationBody.
  ///
  /// In en, this message translates to:
  /// **'This will queue all 114 Surahs for {reciter}. Downloads use mobile data and storage; Wi-Fi is recommended. Nothing starts until you confirm.'**
  String downloadAllConfirmationBody(String reciter);

  /// No description provided for @downloadSizeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'A reliable total size estimate is not available before the audio files are requested.'**
  String get downloadSizeUnavailable;

  /// No description provided for @downloadQueued.
  ///
  /// In en, this message translates to:
  /// **'Download queued.'**
  String get downloadQueued;

  /// No description provided for @downloadProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} verses verified'**
  String downloadProgress(int completed, int total);

  /// No description provided for @downloadBatchProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} Surahs complete'**
  String downloadBatchProgress(int completed, int total);

  /// No description provided for @downloadCurrentSurah.
  ///
  /// In en, this message translates to:
  /// **'Current: Surah {surah}, verse {verse}'**
  String downloadCurrentSurah(int surah, int verse);

  /// No description provided for @downloadCurrentFileProgress.
  ///
  /// In en, this message translates to:
  /// **'Current verse bytes: {received} / {total}'**
  String downloadCurrentFileProgress(String received, String total);

  /// No description provided for @downloadWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get downloadWaiting;

  /// No description provided for @downloadDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloadDownloading;

  /// No description provided for @downloadPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get downloadPaused;

  /// No description provided for @downloadCompleted.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloadCompleted;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Incomplete — retry failed verses'**
  String get downloadFailed;

  /// No description provided for @downloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get downloadCancelled;

  /// No description provided for @downloadNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Not downloaded'**
  String get downloadNotDownloaded;

  /// No description provided for @downloadPauseAll.
  ///
  /// In en, this message translates to:
  /// **'Pause all'**
  String get downloadPauseAll;

  /// No description provided for @downloadResumeAll.
  ///
  /// In en, this message translates to:
  /// **'Resume all'**
  String get downloadResumeAll;

  /// No description provided for @downloadCancelAll.
  ///
  /// In en, this message translates to:
  /// **'Cancel all'**
  String get downloadCancelAll;

  /// No description provided for @downloadPause.
  ///
  /// In en, this message translates to:
  /// **'Pause download'**
  String get downloadPause;

  /// No description provided for @downloadResume.
  ///
  /// In en, this message translates to:
  /// **'Resume download'**
  String get downloadResume;

  /// No description provided for @downloadCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel download'**
  String get downloadCancel;

  /// No description provided for @downloadRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry failed verses'**
  String get downloadRetry;

  /// No description provided for @downloadDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get downloadDelete;

  /// No description provided for @downloadDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all downloaded audio'**
  String get downloadDeleteAll;

  /// No description provided for @downloadDeleteAllConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete all downloaded Quran audio from this device? This cannot be undone.'**
  String get downloadDeleteAllConfirmation;

  /// No description provided for @downloadDeleteReciter.
  ///
  /// In en, this message translates to:
  /// **'Delete this reciter\'s downloads'**
  String get downloadDeleteReciter;

  /// No description provided for @downloadStorageUsed.
  ///
  /// In en, this message translates to:
  /// **'Storage used: {size}'**
  String downloadStorageUsed(String size);

  /// No description provided for @downloadedSurahs.
  ///
  /// In en, this message translates to:
  /// **'Downloaded Surahs'**
  String get downloadedSurahs;

  /// No description provided for @downloadNoItems.
  ///
  /// In en, this message translates to:
  /// **'No downloaded audio yet.'**
  String get downloadNoItems;

  /// No description provided for @downloadSourceAttribution.
  ///
  /// In en, this message translates to:
  /// **'Audio files are from Al Quran Cloud (edition IDs retained) for personal and educational listening. Recitation rights remain with their respective reciters or estates. https://alquran.cloud/cdn · https://alquran.cloud/terms-and-conditions'**
  String get downloadSourceAttribution;

  /// No description provided for @offlineAudioNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'This verse is not downloaded for the selected reciter. Connect to the internet or download this Surah for offline playback.'**
  String get offlineAudioNotDownloaded;

  /// No description provided for @downloadOperationError.
  ///
  /// In en, this message translates to:
  /// **'The download could not be completed. Check your connection and available storage, then try again.'**
  String get downloadOperationError;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @dataAttributionTitle.
  ///
  /// In en, this message translates to:
  /// **'Sources and licenses'**
  String get dataAttributionTitle;

  /// No description provided for @surahMetadataAttribution.
  ///
  /// In en, this message translates to:
  /// **'Surah metadata from Tanzil Quran Metadata, Version 1.0, CC BY. Verse counts and revelation places were cross-checked with Quran.com API v4. https://tanzil.net/docs/Quran_Metadata'**
  String get surahMetadataAttribution;

  /// No description provided for @quranTextAttribution.
  ///
  /// In en, this message translates to:
  /// **'Tanzil Quran Text, Version 1.1. Copyright © 2007–2026 Tanzil Project. CC BY 3.0; text used verbatim without changes. https://tanzil.net/docs/Text_License'**
  String get quranTextAttribution;

  /// No description provided for @soraniDataAttribution.
  ///
  /// In en, this message translates to:
  /// **'Holy Quran Kurdish Sorani Translation Dataset (HQKSTD). Contributors: Shakhawan Hares Wady, Mhamad Bamoki, and Soran Badawi. DOI: 10.17632/byyjd7kmvd.1. CC BY 4.0: https://creativecommons.org/licenses/by/4.0/. Source: https://data.mendeley.com/datasets/byyjd7kmvd/1. Converted to the app\'s local JSON format.'**
  String get soraniDataAttribution;

  /// No description provided for @quranFontAttribution.
  ///
  /// In en, this message translates to:
  /// **'Amiri Quran font, Amiri Project, version 1.003. SIL Open Font License 1.1. https://github.com/aliftype/amiri'**
  String get quranFontAttribution;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'ckb', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'ckb':
      return AppLocalizationsCkb();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
