import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../domain/quran_verse.dart';
import '../domain/surah.dart';

@immutable
class QuranHomeWidgetData {
  const QuranHomeWidgetData({
    required this.surahNumber,
    required this.verseNumber,
    required this.arabicSurahName,
    required this.surahTransliteration,
    required this.arabicText,
    required this.soraniTranslation,
  });

  static const appGroupId = 'group.com.example.quran';
  static const widgetKind = 'QuranReadingWidget';
  static const payloadKey = 'quran.widget.payload';
  static const schemaVersion = 1;

  static const _canonicalVerseCounts = <int>[
    7,
    286,
    200,
    176,
    120,
    165,
    206,
    75,
    129,
    109,
    123,
    111,
    43,
    52,
    99,
    128,
    111,
    110,
    98,
    135,
    112,
    78,
    118,
    64,
    77,
    227,
    93,
    88,
    69,
    60,
    34,
    30,
    73,
    54,
    45,
    83,
    182,
    88,
    75,
    85,
    54,
    53,
    89,
    59,
    37,
    35,
    38,
    29,
    18,
    45,
    60,
    49,
    62,
    55,
    78,
    96,
    29,
    22,
    24,
    13,
    14,
    11,
    11,
    18,
    12,
    12,
    30,
    52,
    52,
    44,
    28,
    28,
    20,
    56,
    40,
    31,
    50,
    40,
    46,
    42,
    29,
    19,
    36,
    25,
    22,
    17,
    19,
    26,
    30,
    20,
    15,
    21,
    11,
    8,
    8,
    19,
    5,
    8,
    8,
    11,
    11,
    8,
    3,
    9,
    5,
    4,
    7,
    3,
    6,
    3,
    5,
    4,
    5,
    6,
  ];

  final int surahNumber;
  final int verseNumber;
  final String arabicSurahName;
  final String surahTransliteration;
  final String arabicText;
  final String soraniTranslation;

  factory QuranHomeWidgetData.fromVerse({
    required Surah surah,
    required QuranVerse verse,
  }) {
    final canonicalVerseCount = verseCountForSurah(surah.number);
    if (canonicalVerseCount == null ||
        surah.number != verse.surahNumber ||
        verse.verseNumber < 1 ||
        verse.verseNumber > canonicalVerseCount) {
      throw ArgumentError('The Ayah must belong to the supplied Surah.');
    }

    final data = QuranHomeWidgetData(
      surahNumber: surah.number,
      verseNumber: verse.verseNumber,
      arabicSurahName: surah.arabicName,
      surahTransliteration: surah.transliteration,
      arabicText: verse.arabicText,
      soraniTranslation: verse.soraniTranslation,
    );
    if (!data.isValid) {
      throw ArgumentError('Widget reading text must not be empty.');
    }
    return data;
  }

  bool get isValid {
    final verseCount = verseCountForSurah(surahNumber);
    return verseCount != null &&
        verseNumber >= 1 &&
        verseNumber <= verseCount &&
        _hasText(arabicSurahName) &&
        _hasText(surahTransliteration) &&
        _hasText(arabicText) &&
        _hasText(soraniTranslation);
  }

  String toPayload() {
    if (!isValid) {
      throw ArgumentError('Cannot serialize invalid Quran widget data.');
    }
    return jsonEncode({
      'schemaVersion': schemaVersion,
      'surahNumber': surahNumber,
      'verseNumber': verseNumber,
      'arabicSurahName': arabicSurahName,
      'surahTransliteration': surahTransliteration,
      'arabicText': arabicText,
      'soraniTranslation': soraniTranslation,
    });
  }

  Uri? get widgetUri {
    if (!isValid) return null;
    return Uri.parse(
      'quran:///quran/surah/$surahNumber?ayah=$verseNumber&homeWidget',
    );
  }

  static int? verseCountForSurah(int surahNumber) {
    if (surahNumber < 1 || surahNumber > _canonicalVerseCounts.length) {
      return null;
    }
    return _canonicalVerseCounts[surahNumber - 1];
  }

  static QuranHomeWidgetData? fromPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;

    Object? decoded;
    try {
      decoded = jsonDecode(payload);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final payloadVersion = decoded['schemaVersion'];
    if (payloadVersion is! int || payloadVersion != schemaVersion) return null;

    final surahNumber = decoded['surahNumber'];
    final verseNumber = decoded['verseNumber'];
    final arabicSurahName = decoded['arabicSurahName'];
    final surahTransliteration = decoded['surahTransliteration'];
    final arabicText = decoded['arabicText'];
    final soraniTranslation = decoded['soraniTranslation'];
    if (surahNumber is! int ||
        verseNumber is! int ||
        arabicSurahName is! String ||
        surahTransliteration is! String ||
        arabicText is! String ||
        soraniTranslation is! String) {
      return null;
    }

    final data = QuranHomeWidgetData(
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      arabicSurahName: arabicSurahName,
      surahTransliteration: surahTransliteration,
      arabicText: arabicText,
      soraniTranslation: soraniTranslation,
    );
    return data.isValid ? data : null;
  }

  static String? routeLocation(Uri? uri) {
    if (uri == null || uri.scheme != 'quran') return null;

    final match = RegExp(r'^/quran/surah/([1-9]\d*)$').firstMatch(uri.path);
    final surahNumber = int.tryParse(match?.group(1) ?? '');
    final verseNumber = int.tryParse(uri.queryParameters['ayah'] ?? '');
    final verseCount = surahNumber == null
        ? null
        : verseCountForSurah(surahNumber);
    if (surahNumber == null ||
        verseCount == null ||
        verseNumber == null ||
        verseNumber < 1) {
      return null;
    }
    if (verseNumber > verseCount) return null;

    return '/quran/surah/$surahNumber?ayah=$verseNumber';
  }

  static bool _hasText(String text) => text.trim().isNotEmpty;
}

class QuranHomeWidgetSync {
  const QuranHomeWidgetSync();

  static Future<void> _updateQueue = Future<void>.value();
  static int _latestUpdate = 0;

  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static Future<void> initialize() async {
    if (!_isIOS) return;

    final configured = await HomeWidget.setAppGroupId(
      QuranHomeWidgetData.appGroupId,
    );
    if (configured != true) {
      throw StateError('The Quran Widget App Group could not be configured.');
    }
  }

  void updateLastRead(QuranHomeWidgetData data) {
    if (!_isIOS) return;
    if (!data.isValid) {
      throw ArgumentError('Cannot save invalid Quran widget data.');
    }

    final update = ++_latestUpdate;
    _updateQueue = _updateQueue
        .then((_) async {
          if (update != _latestUpdate) return;
          await _saveAndRefresh(data);
        })
        .catchError((Object error, StackTrace stackTrace) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'Quran home widget',
              context: ErrorDescription(
                'while saving the current Quran reading position',
              ),
            ),
          );
        });
  }

  Future<void> _saveAndRefresh(QuranHomeWidgetData data) async {
    final saved = await HomeWidget.saveWidgetData<String>(
      QuranHomeWidgetData.payloadKey,
      data.toPayload(),
      appGroupId: QuranHomeWidgetData.appGroupId,
    );
    if (saved != true) {
      throw StateError('The Quran Widget data could not be saved.');
    }

    final refreshed = await HomeWidget.updateWidget(
      iOSName: QuranHomeWidgetData.widgetKind,
    );
    if (refreshed != true) {
      throw StateError('The Quran reading widget could not be refreshed.');
    }
  }
}
