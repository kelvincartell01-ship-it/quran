import 'package:flutter/foundation.dart';

enum QuranDownloadStatus {
  waiting,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

String quranDownloadKey(String reciterId, int surahNumber) =>
    '$reciterId:$surahNumber';

@immutable
class QuranDownloadedVerse {
  const QuranDownloadedVerse({
    required this.reciterId,
    required this.surahNumber,
    required this.verseNumber,
    required this.globalVerseNumber,
    required this.fileSize,
    required this.downloadedAt,
    required this.sourceUrl,
    this.sourceName = 'Al Quran Cloud',
  });

  factory QuranDownloadedVerse.fromJson(Map<String, dynamic> json) {
    final reciterId = json['reciterId'];
    final surahNumber = json['surahNumber'];
    final verseNumber = json['verseNumber'];
    final globalVerseNumber = json['globalVerseNumber'];
    final fileSize = json['fileSize'];
    final downloadedAt = json['downloadedAt'];
    final sourceUrl = json['sourceUrl'];
    final sourceName = json['sourceName'];
    if (reciterId is! String ||
        reciterId.isEmpty ||
        surahNumber is! int ||
        surahNumber < 1 ||
        surahNumber > 114 ||
        verseNumber is! int ||
        verseNumber < 1 ||
        globalVerseNumber is! int ||
        globalVerseNumber < 1 ||
        fileSize is! int ||
        fileSize <= 0 ||
        downloadedAt is! String ||
        sourceUrl is! String ||
        Uri.tryParse(sourceUrl)?.scheme != 'https' ||
        (sourceName != null && sourceName is! String)) {
      throw const FormatException('A downloaded verse record is malformed.');
    }

    return QuranDownloadedVerse(
      reciterId: reciterId,
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      globalVerseNumber: globalVerseNumber,
      fileSize: fileSize,
      downloadedAt: DateTime.parse(downloadedAt),
      sourceUrl: sourceUrl,
      sourceName: sourceName as String? ?? 'Al Quran Cloud',
    );
  }

  final String reciterId;
  final int surahNumber;
  final int verseNumber;
  final int globalVerseNumber;
  final int fileSize;
  final DateTime downloadedAt;
  final String sourceUrl;
  final String sourceName;

  String get key => '$reciterId:$surahNumber:$verseNumber';

  Map<String, Object> toJson() => {
    'reciterId': reciterId,
    'surahNumber': surahNumber,
    'verseNumber': verseNumber,
    'globalVerseNumber': globalVerseNumber,
    'fileSize': fileSize,
    'downloadedAt': downloadedAt.toUtc().toIso8601String(),
    'sourceUrl': sourceUrl,
    'sourceName': sourceName,
  };
}

@immutable
class QuranDownloadJobRecord {
  const QuranDownloadJobRecord({
    required this.reciterId,
    required this.surahNumber,
    required this.totalVerseCount,
    required this.status,
    required this.failedVerseNumbers,
    required this.createdAt,
    this.currentVerseNumber,
    this.error,
    this.batchId,
  });

  factory QuranDownloadJobRecord.fromJson(Map<String, dynamic> json) {
    final reciterId = json['reciterId'];
    final surahNumber = json['surahNumber'];
    final totalVerseCount = json['totalVerseCount'];
    final statusName = json['status'];
    final failedVerses = json['failedVerseNumbers'];
    final createdAt = json['createdAt'];
    final currentVerseNumber = json['currentVerseNumber'];
    final error = json['error'];
    final batchId = json['batchId'];
    if (reciterId is! String ||
        reciterId.isEmpty ||
        surahNumber is! int ||
        surahNumber < 1 ||
        surahNumber > 114 ||
        totalVerseCount is! int ||
        totalVerseCount < 1 ||
        statusName is! String ||
        failedVerses is! List ||
        failedVerses.any((value) => value is! int || value < 1) ||
        createdAt is! String ||
        (currentVerseNumber != null &&
            (currentVerseNumber is! int || currentVerseNumber < 1)) ||
        (error != null && error is! String) ||
        (batchId != null && batchId is! String)) {
      throw const FormatException('A Quran download job is malformed.');
    }

    return QuranDownloadJobRecord(
      reciterId: reciterId,
      surahNumber: surahNumber,
      totalVerseCount: totalVerseCount,
      status: switch (statusName) {
        'waiting' => QuranDownloadStatus.waiting,
        'downloading' => QuranDownloadStatus.downloading,
        'paused' => QuranDownloadStatus.paused,
        'completed' => QuranDownloadStatus.completed,
        'failed' => QuranDownloadStatus.failed,
        'cancelled' => QuranDownloadStatus.cancelled,
        _ => throw const FormatException('Unknown Quran download status.'),
      },
      failedVerseNumbers: Set<int>.unmodifiable(failedVerses.cast<int>()),
      createdAt: DateTime.parse(createdAt),
      currentVerseNumber: currentVerseNumber as int?,
      error: error as String?,
      batchId: batchId as String?,
    );
  }

  final String reciterId;
  final int surahNumber;
  final int totalVerseCount;
  final QuranDownloadStatus status;
  final Set<int> failedVerseNumbers;
  final DateTime createdAt;
  final int? currentVerseNumber;
  final String? error;
  final String? batchId;

  String get key => quranDownloadKey(reciterId, surahNumber);

  Map<String, Object?> toJson() => {
    'reciterId': reciterId,
    'surahNumber': surahNumber,
    'totalVerseCount': totalVerseCount,
    'status': status.name,
    'failedVerseNumbers': failedVerseNumbers.toList()..sort(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'currentVerseNumber': currentVerseNumber,
    'error': error,
    'batchId': batchId,
  };
}

@immutable
class QuranSurahDownloadProgress {
  const QuranSurahDownloadProgress({
    required this.reciterId,
    required this.surahNumber,
    required this.status,
    required this.completedVerseCount,
    required this.totalVerseCount,
    required this.failedVerseNumbers,
    this.currentVerseNumber,
    this.currentBytes = 0,
    this.currentTotalBytes,
    this.error,
    this.batchId,
  });

  final String reciterId;
  final int surahNumber;
  final QuranDownloadStatus status;
  final int completedVerseCount;
  final int totalVerseCount;
  final Set<int> failedVerseNumbers;
  final int? currentVerseNumber;
  final int currentBytes;
  final int? currentTotalBytes;
  final String? error;
  final String? batchId;

  double get progress => totalVerseCount == 0
      ? 0
      : (completedVerseCount / totalVerseCount).clamp(0, 1).toDouble();
}

@immutable
class QuranDownloadBatchProgress {
  const QuranDownloadBatchProgress({
    required this.batchId,
    required this.reciterId,
    required this.totalSurahs,
    required this.completedSurahs,
    required this.pendingSurahs,
    required this.failedSurahs,
    required this.completedVerseCount,
    required this.totalVerseCount,
    required this.status,
    this.currentSurahNumber,
    this.currentVerseNumber,
    this.currentBytes = 0,
    this.currentTotalBytes,
  });

  final String batchId;
  final String reciterId;
  final int totalSurahs;
  final int completedSurahs;
  final int pendingSurahs;
  final int failedSurahs;
  final int completedVerseCount;
  final int totalVerseCount;
  final QuranDownloadStatus status;
  final int? currentSurahNumber;
  final int? currentVerseNumber;
  final int currentBytes;
  final int? currentTotalBytes;

  double get progress => totalVerseCount == 0
      ? 0
      : (completedVerseCount / totalVerseCount).clamp(0, 1).toDouble();
}

@immutable
class QuranDownloadState {
  const QuranDownloadState({
    required this.isSupported,
    required this.selectedReciterId,
    required this.surahs,
    required this.batches,
    required this.totalStorageBytes,
    this.error,
  });

  const QuranDownloadState.unavailable()
    : isSupported = false,
      selectedReciterId = 'ar.alafasy',
      surahs = const {},
      batches = const {},
      totalStorageBytes = 0,
      error = null;

  final bool isSupported;
  final String selectedReciterId;
  final Map<String, QuranSurahDownloadProgress> surahs;
  final Map<String, QuranDownloadBatchProgress> batches;
  final int totalStorageBytes;
  final String? error;

  QuranSurahDownloadProgress? forSurah(String reciterId, int surahNumber) =>
      surahs[quranDownloadKey(reciterId, surahNumber)];

  List<QuranSurahDownloadProgress> forReciter(String reciterId) =>
      List.unmodifiable(
        surahs.values.where((download) => download.reciterId == reciterId),
      );
}
