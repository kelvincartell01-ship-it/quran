// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get applicationTitle => 'القرآن';

  @override
  String get applicationSubtitle => 'مساحة هادئة للقرآن';

  @override
  String get navQuran => 'القرآن';

  @override
  String get navChannels => 'القنوات';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get quranWelcome => 'رحلتك مع القرآن';

  @override
  String get quranWelcomeBody => 'مساحة هادئة للقراءة والاستماع والتدبر.';

  @override
  String get quranContentUnavailable =>
      'ستتوفر قراءة القرآن هنا في تحديث قادم.';

  @override
  String get channelsTitle => 'القنوات';

  @override
  String get channelsDescription =>
      'اختر صفحة البث الرسمية لإحدى قناتي المدينتين المقدستين.';

  @override
  String get makkahLiveName => 'مكة مباشر';

  @override
  String get makkahLiveDescription => 'بث مباشر من المسجد الحرام.';

  @override
  String get madinahLiveName => 'المدينة المنورة مباشر';

  @override
  String get madinahLiveDescription => 'بث مباشر من المسجد النبوي.';

  @override
  String get officialBroadcasterLabel => 'الجهة الرسمية';

  @override
  String get openOfficialLivePage => 'فتح صفحة البث الرسمية';

  @override
  String get openingOfficialLivePage => 'جارٍ فتح الصفحة الرسمية…';

  @override
  String get officialLivePageLabel =>
      'هيئة الإذاعة والتلفزيون السعودية (SBA) · صفحة العلا للبث';

  @override
  String get channelInAppPlaybackUnverified =>
      'تعذر التحقق من بث رسمي حالي داخل التطبيق. لن نعرض بثاً غير متحقق منه أو شارة LIVE؛ استخدم الصفحة الرسمية للجهة الناقلة.';

  @override
  String get officialLivePageOpenError =>
      'تعذر فتح صفحة البث الرسمية. تحقق من اتصالك وحاول مجدداً.';

  @override
  String get channelAudioPauseError =>
      'تعذر إيقاف تلاوة القرآن مؤقتاً، لذلك لم تُفتح صفحة القناة.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get languageSection => 'اللغة';

  @override
  String get languageLabel => 'لغة التطبيق';

  @override
  String get languageSorani => 'الكردية السورانية';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'الإنجليزية';

  @override
  String get appearanceSection => 'المظهر';

  @override
  String get themeLabel => 'السمة';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get readingSection => 'القراءة';

  @override
  String get quranFontSize => 'حجم نص القرآن';

  @override
  String fontSizeValue(String size) {
    return '$size';
  }

  @override
  String get preferenceSaveError => 'تعذر حفظ تفضيلك. يرجى المحاولة مرة أخرى.';

  @override
  String get fontPreparationNote =>
      'يستخدم التطبيق خط Amiri Quran بترخيص SIL OFL 1.1؛ ولا يعني اسمه أنه خط حفص رسمي.';

  @override
  String get soraniFrameworkLocalizationNote =>
      'تستخدم عناصر Flutter الداخلية النصوص العربية في وضع السورانية لعدم توفر ترجمة سورانية لها في Flutter.';

  @override
  String get surahsHeading => 'سور القرآن';

  @override
  String surahCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# سورة',
      many: '# سورة',
      few: '# سور',
      two: 'سورتان',
      one: 'سورة واحدة',
      zero: 'لا سور',
    );
    return '$_temp0';
  }

  @override
  String get searchSurahs => 'ابحث بالاسم أو الرقم';

  @override
  String get clearSearch => 'مسح البحث';

  @override
  String get noSurahsFound => 'لا توجد سور تطابق بحثك.';

  @override
  String get surahLoadError => 'تعذر تحميل معلومات السور.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get surahDetailTitle => 'تفاصيل السورة';

  @override
  String get surahNotFound => 'لم يتم العثور على هذه السورة.';

  @override
  String surahNumber(int number) {
    return 'السورة $number';
  }

  @override
  String get surahNumberLabel => 'الرقم';

  @override
  String get verseCountLabel => 'عدد الآيات';

  @override
  String verseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# آية',
      many: '# آية',
      few: '# آيات',
      two: 'آيتان',
      one: 'آية واحدة',
      zero: 'لا آيات',
    );
    return '$_temp0';
  }

  @override
  String get revelationOrderLabel => 'ترتيب النزول';

  @override
  String get makki => 'مكية';

  @override
  String get madani => 'مدنية';

  @override
  String get surahDetailComingSoon =>
      'ستضاف آيات القرآن وميزات القراءة في مرحلة لاحقة.';

  @override
  String get quranReaderTitle => 'قراءة القرآن';

  @override
  String get quranReaderLoadError =>
      'تعذر تحميل نص القرآن أو معانيه بالسورانية.';

  @override
  String get verseMeaningLabel => 'معنى الآية';

  @override
  String verseNumber(int number) {
    return 'الآية $number';
  }

  @override
  String get increaseQuranFontSize => 'تكبير خط القرآن';

  @override
  String get decreaseQuranFontSize => 'تصغير خط القرآن';

  @override
  String get audioPlayerTitle => 'تلاوة القرآن';

  @override
  String get audioPlaybackUnavailable => 'يتوفر تشغيل الصوت على Android وiOS.';

  @override
  String get selectReciter => 'القارئ';

  @override
  String get playSurah => 'تشغيل السورة';

  @override
  String get resumeAudio => 'استئناف التلاوة';

  @override
  String get pauseAudio => 'إيقاف التلاوة مؤقتاً';

  @override
  String playFromVerse(int verse) {
    return 'التشغيل من الآية $verse';
  }

  @override
  String get previousVerse => 'الآية السابقة';

  @override
  String get nextVerse => 'الآية التالية';

  @override
  String get repeatModeLabel => 'وضع التكرار';

  @override
  String get repeatOff => 'التكرار متوقف';

  @override
  String get repeatSurah => 'تكرار السورة';

  @override
  String get repeatVerse => 'تكرار الآية';

  @override
  String get audioLoading => 'جارٍ تحميل التلاوة…';

  @override
  String get audioPlaybackError =>
      'تعذر تشغيل الصوت. تحقق من الاتصال وحاول مجدداً.';

  @override
  String get audioPermissionDenied =>
      'اسمح بالإشعارات لإظهار عناصر التحكم بالتشغيل.';

  @override
  String get audioProgressLabel => 'تقدم التلاوة';

  @override
  String get showAudioControls => 'إظهار عناصر التحكم بالصوت';

  @override
  String get hideAudioControls => 'إخفاء عناصر التحكم بالصوت';

  @override
  String get audioStreamingAttribution =>
      'الصوت من Al Quran Cloud؛ استمع عبر الإنترنت أو نزّل السور للاستماع دون اتصال.';

  @override
  String get downloadSection => 'تنزيلات الصوت';

  @override
  String get downloadReciter => 'القارئ للتنزيل';

  @override
  String get downloadSurahAction => 'تنزيل هذه السورة';

  @override
  String get downloadQuranAction => 'تنزيل السور الـ 114';

  @override
  String get downloadAllConfirmationTitle => 'تنزيل القرآن كاملاً؟';

  @override
  String downloadAllConfirmationBody(String reciter) {
    return 'ستتم إضافة السور الـ 114 للقارئ $reciter إلى قائمة التنزيل. سيستخدم التنزيل بيانات الهاتف ومساحة التخزين؛ يُنصح باستخدام Wi‑Fi. لن يبدأ شيء قبل التأكيد.';
  }

  @override
  String get downloadSizeUnavailable =>
      'لا يتوفر تقدير موثوق للحجم الإجمالي قبل طلب الملفات الصوتية.';

  @override
  String get downloadQueued => 'أُضيف التنزيل إلى القائمة.';

  @override
  String downloadProgress(int completed, int total) {
    return 'تم التحقق من $completed من $total آية';
  }

  @override
  String downloadBatchProgress(int completed, int total) {
    return 'اكتملت $completed من $total سورة';
  }

  @override
  String downloadCurrentSurah(int surah, int verse) {
    return 'الحالي: السورة $surah، الآية $verse';
  }

  @override
  String downloadCurrentFileProgress(String received, String total) {
    return 'بايتات الآية الحالية: $received / $total';
  }

  @override
  String get downloadWaiting => 'في الانتظار';

  @override
  String get downloadDownloading => 'جارٍ التنزيل';

  @override
  String get downloadPaused => 'متوقف مؤقتاً';

  @override
  String get downloadCompleted => 'تم التنزيل';

  @override
  String get downloadFailed => 'غير مكتمل — أعد تنزيل الآيات الفاشلة';

  @override
  String get downloadCancelled => 'أُلغي';

  @override
  String get downloadNotDownloaded => 'لم يتم التنزيل';

  @override
  String get downloadPauseAll => 'إيقاف الكل مؤقتاً';

  @override
  String get downloadResumeAll => 'استئناف الكل';

  @override
  String get downloadCancelAll => 'إلغاء الكل';

  @override
  String get downloadPause => 'إيقاف التنزيل مؤقتاً';

  @override
  String get downloadResume => 'استئناف التنزيل';

  @override
  String get downloadCancel => 'إلغاء التنزيل';

  @override
  String get downloadRetry => 'إعادة تنزيل الآيات الفاشلة';

  @override
  String get downloadDelete => 'حذف';

  @override
  String get downloadDeleteAll => 'مسح كل الصوت المنزّل';

  @override
  String get downloadDeleteAllConfirmation =>
      'هل تريد حذف كل صوت القرآن المنزّل من هذا الجهاز؟ لا يمكن التراجع عن ذلك.';

  @override
  String get downloadDeleteReciter => 'حذف تنزيلات هذا القارئ';

  @override
  String downloadStorageUsed(String size) {
    return 'المساحة المستخدمة: $size';
  }

  @override
  String get downloadedSurahs => 'السور المنزّلة';

  @override
  String get downloadNoItems => 'لا توجد ملفات صوتية منزّلة بعد.';

  @override
  String get downloadSourceAttribution =>
      'الملفات الصوتية من Al Quran Cloud (مع الاحتفاظ بمعرّفات الإصدارات) للاستماع الشخصي والتعليمي. حقوق التلاوات محفوظة للقراء أو أصحاب الحقوق. https://alquran.cloud/cdn · https://alquran.cloud/terms-and-conditions';

  @override
  String get offlineAudioNotDownloaded =>
      'هذه الآية غير منزّلة للقارئ المحدد. اتصل بالإنترنت أو نزّل هذه السورة للاستماع دون اتصال.';

  @override
  String get downloadOperationError =>
      'تعذر إكمال التنزيل. تحقق من الاتصال ومساحة التخزين المتاحة ثم حاول مرة أخرى.';

  @override
  String get aboutSection => 'حول التطبيق';

  @override
  String get dataAttributionTitle => 'المصادر والتراخيص';

  @override
  String get surahMetadataAttribution =>
      'بيانات السور من بيانات تنـزيل، الإصدار 1.0، بترخيص CC BY. تمت مراجعة أعداد الآيات ومكان النزول عبر Quran.com API v4. https://tanzil.net/docs/Quran_Metadata';

  @override
  String get quranTextAttribution =>
      'نص القرآن من مشروع تنـزيل، الإصدار 1.1. حقوق النشر © 2007–2026 لمشروع تنـزيل. ترخيص CC BY 3.0؛ نُقل النص حرفياً دون تعديل. https://tanzil.net/docs/Text_License';

  @override
  String get soraniDataAttribution =>
      'Holy Quran Kurdish Sorani Translation Dataset (HQKSTD). المساهمون: Shakhawan Hares Wady وMhamad Bamoki وSoran Badawi. DOI: 10.17632/byyjd7kmvd.1. ترخيص CC BY 4.0: https://creativecommons.org/licenses/by/4.0/ المصدر: https://data.mendeley.com/datasets/byyjd7kmvd/1. حُوّلت البيانات إلى تنسيق JSON محلي للتطبيق.';

  @override
  String get quranFontAttribution =>
      'خط Amiri Quran، مشروع Amiri، الإصدار 1.003. ترخيص SIL Open Font License 1.1. https://github.com/aliftype/amiri';
}
