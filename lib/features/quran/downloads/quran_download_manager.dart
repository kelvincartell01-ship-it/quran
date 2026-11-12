import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../audio/quran_audio_queue.dart';
import '../audio/quran_reciter.dart';
import '../domain/quran_verse.dart';
import '../domain/surah.dart';
import 'quran_audio_download_client.dart';
import 'quran_audio_storage.dart';
import 'quran_download_controller.dart';
import 'quran_download_models.dart';

class QuranDownloadManager implements QuranDownloadController {
  QuranDownloadManager._({
    required this.storage,
    required this.client,
    required int initialStorageBytes,
  }) : _totalStorageBytes = initialStorageBytes {
    for (final record in storage.jobs) {
      final restoredStatus = switch (record.status) {
        QuranDownloadStatus.waiting ||
        QuranDownloadStatus.downloading => QuranDownloadStatus.paused,
        _ => record.status,
      };
      _jobs[record.key] = _DownloadJob(
        record: _copyRecord(record, status: restoredStatus),
      );
    }
  }

  static const maxConcurrentDownloads = 1;
  static const _maxAttempts = 3;
  static const _sourceName = 'Al Quran Cloud';

  final QuranAudioStorage storage;
  final QuranAudioDownloadClient client;
  final Map<String, _DownloadJob> _jobs = {};
  final List<_DownloadJob> _pendingJobs = [];
  final StreamController<QuranDownloadState> _stateController =
      StreamController<QuranDownloadState>.broadcast(sync: true);
  int _totalStorageBytes;
  bool _isDraining = false;
  bool _pauseRequestedAll = false;
  String? _stateError;
  _DownloadJob? _activeJob;
  QuranAudioDownloadResponse? _activeResponse;
  Completer<void>? _activeCompletion;

  static Future<QuranDownloadManager> create({
    required QuranAudioStorage storage,
    QuranAudioDownloadClient? client,
  }) async {
    await storage.initialize();
    return QuranDownloadManager._(
      storage: storage,
      client: client ?? IoQuranAudioDownloadClient(),
      initialStorageBytes: await storage.storageBytes(),
    );
  }

  @override
  bool get isSupported => true;

  @override
  String get selectedReciterId => storage.selectedReciterId;

  @override
  Stream<QuranDownloadState> get stateStream => _stateController.stream;

  @override
  QuranDownloadState get state => _buildState();

  @override
  Future<void> selectReciter(QuranReciter reciter) async {
    await storage.setSelectedReciter(reciter.identifier);
    _stateError = null;
    _emit();
  }

  @override
  Future<void> downloadSurah({
    required Surah surah,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
  }) async {
    _validateSurahAndVerses(surah, verses);
    _validateReciter(reciter);
    _pauseRequestedAll = false;
    final job = _getOrCreateJob(surah: surah, reciter: reciter, batchId: null);
    _attachWork(job, surah, verses, reciter);
    if (_isComplete(job)) {
      job.record = _withStatus(
        job.record,
        QuranDownloadStatus.completed,
        clearError: true,
      );
      await _persistJobs();
      _emit();
      return;
    }
    _enqueue(job, prioritize: true);
    await _persistJobs();
    _stateError = null;
    _emit();
    _schedule();
  }

  @override
  Future<void> downloadAll({
    required List<Surah> surahs,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
  }) async {
    if (surahs.length != 114 ||
        surahs.indexed.any((entry) => entry.$1 + 1 != entry.$2.number)) {
      throw ArgumentError(
        'The complete Quran queue must contain all 114 '
        'Surahs in canonical order.',
      );
    }
    _validateReciter(reciter);
    final versesBySurah = _validateAndGroupVerses(surahs, verses);
    _pauseRequestedAll = false;

    final reusableBatch = _jobs.values
        .where(
          (job) =>
              job.record.batchId != null &&
              job.record.reciterId == reciter.identifier &&
              job.record.status != QuranDownloadStatus.cancelled,
        )
        .map((job) => job.record.batchId!)
        .firstOrNull;
    final batchId =
        reusableBatch ??
        'bulk-${reciter.identifier}-${DateTime.now().microsecondsSinceEpoch}';

    for (final surah in surahs) {
      final job = _getOrCreateJob(
        surah: surah,
        reciter: reciter,
        batchId: batchId,
      );
      job.record = _copyRecord(job.record, batchId: batchId);
      _attachWork(job, surah, versesBySurah[surah.number]!, reciter);
      if (_isComplete(job)) {
        job.record = _withStatus(
          job.record,
          QuranDownloadStatus.completed,
          clearError: true,
        );
        _pendingJobs.remove(job);
      } else {
        _enqueue(job, prioritize: false);
      }
    }
    await _persistJobs();
    _stateError = null;
    _emit();
    _schedule();
  }

  @override
  Future<void> retrySurah({
    required Surah surah,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
  }) async {
    _validateSurahAndVerses(surah, verses);
    _validateReciter(reciter);
    final job = _getOrCreateJob(surah: surah, reciter: reciter, batchId: null);
    if (identical(_activeJob, job)) {
      if (job.record.status == QuranDownloadStatus.downloading) return;
      final activeCompletion = _activeCompletion?.future;
      if (activeCompletion != null) await activeCompletion;
    }
    _attachWork(job, surah, verses, reciter);
    job.retryOnlyFailed = job.record.failedVerseNumbers.isNotEmpty;
    job.record = _withStatus(
      job.record,
      QuranDownloadStatus.waiting,
      clearError: true,
    );
    _pauseRequestedAll = false;
    _enqueue(job, prioritize: true);
    await _persistJobs();
    _stateError = null;
    _emit();
    _schedule();
  }

  @override
  Future<void> pauseSurah(String reciterId, int surahNumber) async {
    final job = _jobs[quranDownloadKey(reciterId, surahNumber)];
    if (job == null ||
        (job.record.status != QuranDownloadStatus.downloading &&
            job.record.status != QuranDownloadStatus.waiting)) {
      return;
    }
    _pendingJobs.remove(job);
    job.record = _withStatus(job.record, QuranDownloadStatus.paused);
    final activeCompletion = identical(_activeJob, job)
        ? _activeCompletion?.future
        : null;
    if (identical(_activeJob, job)) {
      _activeResponse?.abort();
    }
    await _persistJobs();
    _emit();
    if (activeCompletion != null) {
      await activeCompletion;
    }
  }

  @override
  Future<void> resumeSurah({
    required Surah surah,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
  }) => downloadSurah(surah: surah, verses: verses, reciter: reciter);

  @override
  Future<void> cancelSurah(String reciterId, int surahNumber) async {
    final job = _jobs[quranDownloadKey(reciterId, surahNumber)];
    if (job == null) return;
    _pendingJobs.remove(job);
    job.record = _withStatus(job.record, QuranDownloadStatus.cancelled);
    final activeCompletion = identical(_activeJob, job)
        ? _activeCompletion?.future
        : null;
    if (identical(_activeJob, job)) {
      _activeResponse?.abort();
    }
    await _persistJobs();
    _emit();
    if (activeCompletion != null) {
      await activeCompletion;
    }
  }

  @override
  Future<void> pauseAll() async {
    _pauseRequestedAll = true;
    for (final job in _pendingJobs.toList()) {
      job.record = _withStatus(job.record, QuranDownloadStatus.paused);
    }
    _pendingJobs.clear();
    final active = _activeJob;
    final activeCompletion = _activeCompletion?.future;
    if (active != null &&
        active.record.status == QuranDownloadStatus.downloading) {
      active.record = _withStatus(active.record, QuranDownloadStatus.paused);
      _activeResponse?.abort();
    }
    await _persistJobs();
    _emit();
    if (active != null && activeCompletion != null) {
      await activeCompletion;
    }
  }

  @override
  Future<void> resumeAll({
    required List<Surah> surahs,
    required List<QuranVerse> verses,
    required List<QuranReciter> reciters,
  }) async {
    final surahsByNumber = {for (final surah in surahs) surah.number: surah};
    final versesBySurah = <int, List<QuranVerse>>{};
    for (final verse in verses) {
      versesBySurah.putIfAbsent(verse.surahNumber, () => []).add(verse);
    }
    final recitersById = {
      for (final reciter in reciters) reciter.identifier: reciter,
    };
    _pauseRequestedAll = false;

    final resumableJobs = _jobs.values.where(
      (job) =>
          job.record.status == QuranDownloadStatus.paused ||
          job.record.status == QuranDownloadStatus.cancelled ||
          job.record.status == QuranDownloadStatus.waiting,
    );
    for (final job in resumableJobs) {
      final surah = surahsByNumber[job.record.surahNumber];
      final reciter = recitersById[job.record.reciterId];
      final surahVerses = versesBySurah[job.record.surahNumber];
      if (surah == null || reciter == null || surahVerses == null) {
        continue;
      }
      _validateSurahAndVerses(surah, surahVerses);
      _attachWork(job, surah, surahVerses, reciter);
      job.record = _withStatus(
        job.record,
        QuranDownloadStatus.waiting,
        clearError: true,
      );
      _enqueue(job, prioritize: false);
    }
    await _persistJobs();
    _stateError = null;
    _emit();
    _schedule();
  }

  @override
  Future<void> cancelAll() async {
    _pauseRequestedAll = true;
    for (final job in _jobs.values) {
      if (job.record.status == QuranDownloadStatus.waiting ||
          job.record.status == QuranDownloadStatus.downloading) {
        job.record = _withStatus(job.record, QuranDownloadStatus.cancelled);
      }
    }
    _pendingJobs.clear();
    final active = _activeJob;
    final activeCompletion = _activeCompletion?.future;
    _activeResponse?.abort();
    await _persistJobs();
    _emit();
    if (active != null && activeCompletion != null) {
      await activeCompletion;
    }
  }

  @override
  Future<void> deleteSurah(String reciterId, int surahNumber) async {
    await cancelSurah(reciterId, surahNumber);
    final job = _jobs.remove(quranDownloadKey(reciterId, surahNumber));
    if (job != null) _pendingJobs.remove(job);
    await storage.deleteSurah(reciterId, surahNumber);
    _totalStorageBytes = await storage.storageBytes();
    await _persistJobs();
    _emit();
  }

  @override
  Future<void> deleteReciterDownloads(String reciterId) async {
    final jobs = _jobs.values
        .where((job) => job.record.reciterId == reciterId)
        .toList();
    for (final job in jobs) {
      await cancelSurah(reciterId, job.record.surahNumber);
    }
    _jobs.removeWhere((_, job) => job.record.reciterId == reciterId);
    _pendingJobs.removeWhere((job) => job.record.reciterId == reciterId);
    await storage.deleteReciter(reciterId);
    _totalStorageBytes = await storage.storageBytes();
    await _persistJobs();
    _emit();
  }

  @override
  Future<void> clearAll() async {
    await cancelAll();
    await storage.clearAll();
    _jobs.clear();
    _pendingJobs.clear();
    _totalStorageBytes = 0;
    _stateError = null;
    _emit();
  }

  Future<void> dispose() async {
    await cancelAll();
    await client.close();
    await storage.close();
    await _stateController.close();
  }

  void _enqueue(_DownloadJob job, {required bool prioritize}) {
    _pendingJobs.remove(job);
    if (identical(_activeJob, job)) return;
    job.record = _withStatus(job.record, QuranDownloadStatus.waiting);
    if (prioritize) {
      _pendingJobs.insert(0, job);
    } else {
      _pendingJobs.add(job);
    }
  }

  void _schedule() {
    if (_isDraining || _pauseRequestedAll || _pendingJobs.isEmpty) return;
    _isDraining = true;
    unawaited(
      _drain().catchError((Object error, StackTrace stackTrace) {
        _stateError = error.toString();
        _emit();
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'Quran audio downloads',
          ),
        );
      }),
    );
  }

  Future<void> _drain() async {
    try {
      while (_pendingJobs.isNotEmpty && !_pauseRequestedAll) {
        final job = _pendingJobs.removeAt(0);
        if (job.record.status != QuranDownloadStatus.waiting) continue;
        if (job.surah == null || job.verses == null || job.reciter == null) {
          job.record = _withStatus(
            job.record,
            QuranDownloadStatus.paused,
            error: 'Download data must be reloaded before resuming.',
          );
          await _persistJobs();
          _emit();
          continue;
        }

        _activeJob = job;
        _activeCompletion = Completer<void>();
        try {
          await _runJob(job);
        } catch (error, stackTrace) {
          job.record = _withStatus(
            job.record,
            QuranDownloadStatus.failed,
            error: error.toString(),
          );
          _stateError = error.toString();
          await _persistJobs();
          _emit();
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'Quran audio downloads',
            ),
          );
        } finally {
          _activeResponse = null;
          _activeJob = null;
          _activeCompletion?.complete();
          _activeCompletion = null;
        }
      }
    } finally {
      _isDraining = false;
      if (_pendingJobs.isNotEmpty && !_pauseRequestedAll) {
        _schedule();
      }
    }
  }

  Future<void> _runJob(_DownloadJob job) async {
    job.record = _withStatus(
      _withCurrentVerse(job.record, null),
      QuranDownloadStatus.downloading,
      clearError: true,
    );
    _emit();

    final verses = job.verses!;
    final reciter = job.reciter!;
    final retryNumbers = job.retryOnlyFailed
        ? job.record.failedVerseNumbers
        : const <int>{};
    final targetVerses = retryNumbers.isEmpty
        ? verses
        : verses
              .where((verse) => retryNumbers.contains(verse.verseNumber))
              .toList(growable: false);
    job.retryOnlyFailed = false;

    for (final verse in targetVerses) {
      if (job.record.status != QuranDownloadStatus.downloading) break;
      if (await _isVerseDownloaded(job, verse)) {
        job.record = _withoutFailedVerse(job.record, verse.verseNumber);
        continue;
      }
      job.record = _withCurrentVerse(job.record, verse.verseNumber);
      job.currentBytes = 0;
      job.currentTotalBytes = null;
      _emit();
      try {
        final downloaded = await _downloadVerse(job, verse, reciter);
        job.record = _withoutFailedVerse(job.record, verse.verseNumber);
        job.currentBytes = 0;
        job.currentTotalBytes = null;
        job.record = _withCurrentVerse(job.record, null);
        _totalStorageBytes += downloaded.fileSize;
        _emit();
      } on _DownloadInterrupted {
        break;
      } catch (error) {
        job.record = _withFailedVerse(job.record, verse.verseNumber);
        job.record = _withCurrentVerse(
          _withError(job.record, error.toString()),
          null,
        );
        job.currentBytes = 0;
        job.currentTotalBytes = null;
        _emit();
      }
    }

    if (job.record.status != QuranDownloadStatus.downloading) {
      return;
    }
    final completedCount = _completedVerseCount(job);
    final status = completedCount == job.record.totalVerseCount
        ? QuranDownloadStatus.completed
        : QuranDownloadStatus.failed;
    job.record = _withCurrentVerse(
      _withStatus(
        job.record,
        status,
        error: status == QuranDownloadStatus.failed
            ? job.record.error ?? 'Some verse files could not be verified.'
            : null,
        clearError: status == QuranDownloadStatus.completed,
      ),
      null,
    );
    await _persistJobs();
    _emit();
  }

  Future<bool> _isVerseDownloaded(_DownloadJob job, QuranVerse verse) async {
    final record = await storage.findValidVerse(
      job.record.reciterId,
      verse.surahNumber,
      verse.verseNumber,
      verse.globalVerseNumber,
    );
    if (record != null) return true;

    final proposed = _recordFor(job, verse, 1);
    final adopted = await storage.adoptExistingAudio(proposed);
    if (adopted == null) return false;
    _totalStorageBytes += adopted.fileSize;
    return true;
  }

  Future<QuranDownloadedVerse> _downloadVerse(
    _DownloadJob job,
    QuranVerse verse,
    QuranReciter reciter,
  ) async {
    final uri = QuranAudioQueueBuilder.audioUriForVerse(verse, reciter);
    final part = storage.partialFileFor(
      reciter.identifier,
      verse.surahNumber,
      verse.verseNumber,
    );

    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      if (job.record.status != QuranDownloadStatus.downloading) {
        throw const _DownloadInterrupted();
      }
      QuranAudioDownloadResponse? response;
      try {
        final offset = await part.exists() ? await part.length() : 0;
        response = await client.get(
          uri,
          rangeStart: offset > 0 ? offset : null,
        );
        _activeResponse = response;
        if (job.record.status != QuranDownloadStatus.downloading) {
          response.abort();
          throw const _DownloadInterrupted();
        }
        if (response.statusCode == HttpStatus.requestedRangeNotSatisfiable &&
            offset > 0) {
          response.abort();
          if (await part.exists()) {
            await part.delete();
          }
          continue;
        }
        final append = _validateResponse(response, offset);
        final effectiveOffset = append ? offset : 0;
        final expectedLength = response.contentLength == null
            ? null
            : effectiveOffset + response.contentLength!;
        job.currentBytes = effectiveOffset;
        job.currentTotalBytes = expectedLength;
        await part.parent.create(recursive: true);
        final sink = part.openWrite(
          mode: append ? FileMode.append : FileMode.write,
        );
        var lastEmit = DateTime.now();
        try {
          await for (final chunk in response.body) {
            if (job.record.status != QuranDownloadStatus.downloading) {
              response.abort();
              throw const _DownloadInterrupted();
            }
            sink.add(chunk);
            job.currentBytes += chunk.length;
            if (DateTime.now().difference(lastEmit).inMilliseconds >= 120) {
              lastEmit = DateTime.now();
              _emit();
            }
          }
          await sink.flush();
        } finally {
          await sink.close();
          _activeResponse = null;
        }
        if (job.record.status != QuranDownloadStatus.downloading) {
          throw const _DownloadInterrupted();
        }
        final fileLength = await part.length();
        if (expectedLength != null && fileLength != expectedLength) {
          throw const QuranAudioDownloadException(
            'The downloaded audio length does not match the server response.',
            retryable: true,
          );
        }
        if (!await QuranAudioStorage.isValidAudioFile(part)) {
          if (await part.exists()) {
            await part.delete();
          }
          throw const FormatException(
            'The server response is not valid MP3 audio.',
          );
        }
        final record = _recordFor(job, verse, fileLength);
        return await storage.commitAudioFile(partialFile: part, record: record);
      } on _DownloadInterrupted {
        rethrow;
      } catch (error) {
        _activeResponse = null;
        if (job.record.status != QuranDownloadStatus.downloading) {
          throw const _DownloadInterrupted();
        }
        final retryable = _isRetryable(error);
        if (!retryable || attempt + 1 >= _maxAttempts) {
          rethrow;
        }
        await Future<void>.delayed(
          Duration(milliseconds: 300 * (1 << attempt)),
        );
      } finally {
        response?.abort();
        _activeResponse = null;
      }
    }
    throw const QuranAudioDownloadException(
      'The audio download could not be completed.',
      retryable: false,
    );
  }

  QuranDownloadedVerse _recordFor(
    _DownloadJob job,
    QuranVerse verse,
    int fileSize,
  ) => QuranDownloadedVerse(
    reciterId: job.record.reciterId,
    surahNumber: verse.surahNumber,
    verseNumber: verse.verseNumber,
    globalVerseNumber: verse.globalVerseNumber,
    fileSize: fileSize,
    downloadedAt: DateTime.now().toUtc(),
    sourceUrl: QuranAudioQueueBuilder.audioUriForVerse(
      verse,
      job.reciter!,
    ).toString(),
    sourceName: _sourceName,
  );

  QuranDownloadState _buildState() {
    final downloadedVerses = <String, Set<int>>{};
    for (final record in storage.records) {
      downloadedVerses
          .putIfAbsent(
            quranDownloadKey(record.reciterId, record.surahNumber),
            () => <int>{},
          )
          .add(record.verseNumber);
    }
    int completedCount(_DownloadJob job) =>
        downloadedVerses[job.record.key]
            ?.where((verseNumber) => verseNumber <= job.record.totalVerseCount)
            .length ??
        0;

    final progress = <String, QuranSurahDownloadProgress>{};
    for (final job in _jobs.values) {
      final verseCount = completedCount(job);
      final status =
          job.record.status == QuranDownloadStatus.completed &&
              verseCount == job.record.totalVerseCount
          ? QuranDownloadStatus.completed
          : job.record.status == QuranDownloadStatus.completed
          ? QuranDownloadStatus.paused
          : job.record.status;
      progress[job.record.key] = QuranSurahDownloadProgress(
        reciterId: job.record.reciterId,
        surahNumber: job.record.surahNumber,
        status: status,
        completedVerseCount: verseCount,
        totalVerseCount: job.record.totalVerseCount,
        failedVerseNumbers: job.record.failedVerseNumbers,
        currentVerseNumber: job.record.currentVerseNumber,
        currentBytes: job.currentBytes,
        currentTotalBytes: job.currentTotalBytes,
        error: job.record.error,
        batchId: job.record.batchId,
      );
    }

    final batches = <String, QuranDownloadBatchProgress>{};
    final grouped = <String, List<_DownloadJob>>{};
    for (final job in _jobs.values) {
      final batchId = job.record.batchId;
      if (batchId != null) {
        grouped.putIfAbsent(batchId, () => []).add(job);
      }
    }
    for (final entry in grouped.entries) {
      final jobs = entry.value;
      final completedSurahs = jobs
          .where(
            (job) =>
                job.record.status == QuranDownloadStatus.completed &&
                completedCount(job) == job.record.totalVerseCount,
          )
          .length;
      final waitingSurahs = jobs
          .where(
            (job) =>
                job.record.status == QuranDownloadStatus.waiting ||
                job.record.status == QuranDownloadStatus.paused ||
                job.record.status == QuranDownloadStatus.cancelled,
          )
          .length;
      final failedSurahs = jobs
          .where((job) => job.record.status == QuranDownloadStatus.failed)
          .length;
      final completedVerses = jobs.fold<int>(
        0,
        (sum, job) => sum + completedCount(job),
      );
      final totalVerses = jobs.fold<int>(
        0,
        (sum, job) => sum + job.record.totalVerseCount,
      );
      final batchStatus = completedSurahs == jobs.length
          ? QuranDownloadStatus.completed
          : jobs.any(
              (job) => job.record.status == QuranDownloadStatus.downloading,
            )
          ? QuranDownloadStatus.downloading
          : jobs.any((job) => job.record.status == QuranDownloadStatus.waiting)
          ? QuranDownloadStatus.waiting
          : failedSurahs > 0
          ? QuranDownloadStatus.failed
          : jobs.any((job) => job.record.status == QuranDownloadStatus.paused)
          ? QuranDownloadStatus.paused
          : QuranDownloadStatus.cancelled;
      final currentJob = _activeJob?.record.batchId == entry.key
          ? _activeJob
          : jobs.where((job) => job.currentBytes > 0).firstOrNull;
      batches[entry.key] = QuranDownloadBatchProgress(
        batchId: entry.key,
        reciterId: jobs.first.record.reciterId,
        totalSurahs: jobs.length,
        completedSurahs: completedSurahs,
        pendingSurahs: waitingSurahs,
        failedSurahs: failedSurahs,
        completedVerseCount: completedVerses,
        totalVerseCount: totalVerses,
        status: batchStatus,
        currentSurahNumber: currentJob?.record.surahNumber,
        currentVerseNumber: currentJob?.record.currentVerseNumber,
        currentBytes: currentJob?.currentBytes ?? 0,
        currentTotalBytes: currentJob?.currentTotalBytes,
      );
    }
    return QuranDownloadState(
      isSupported: true,
      selectedReciterId: selectedReciterId,
      surahs: Map.unmodifiable(progress),
      batches: Map.unmodifiable(batches),
      totalStorageBytes: _totalStorageBytes,
      error: _stateError,
    );
  }

  int _completedVerseCount(_DownloadJob job) {
    return storage
        .recordCountForSurah(job.record.reciterId, job.record.surahNumber)
        .clamp(0, job.record.totalVerseCount)
        .toInt();
  }

  bool _isComplete(_DownloadJob job) =>
      _completedVerseCount(job) == job.record.totalVerseCount;

  _DownloadJob _getOrCreateJob({
    required Surah surah,
    required QuranReciter reciter,
    required String? batchId,
  }) {
    final key = quranDownloadKey(reciter.identifier, surah.number);
    final existing = _jobs[key];
    if (existing != null) {
      if (existing.record.totalVerseCount != surah.verseCount) {
        throw StateError('Saved download metadata does not match the Surah.');
      }
      if (batchId != null && existing.record.batchId != batchId) {
        existing.record = _copyRecord(existing.record, batchId: batchId);
      }
      return existing;
    }
    final created = _DownloadJob(
      record: QuranDownloadJobRecord(
        reciterId: reciter.identifier,
        surahNumber: surah.number,
        totalVerseCount: surah.verseCount,
        status: QuranDownloadStatus.waiting,
        failedVerseNumbers: const {},
        createdAt: DateTime.now().toUtc(),
        batchId: batchId,
      ),
    );
    _jobs[key] = created;
    return created;
  }

  void _attachWork(
    _DownloadJob job,
    Surah surah,
    List<QuranVerse> verses,
    QuranReciter reciter,
  ) {
    job
      ..surah = surah
      ..verses = List.unmodifiable(verses)
      ..reciter = reciter;
  }

  Future<void> _persistJobs() async {
    await storage.saveJobs(
      _jobs.values.map((job) => job.record).toList(growable: false),
    );
  }

  void _emit() {
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  void _validateReciter(QuranReciter reciter) {
    if (reciter.verifiedAyahCount != 6236 ||
        !RegExp(r'^[a-z0-9._-]+$').hasMatch(reciter.identifier) ||
        ![32, 40, 48, 64, 128, 192].contains(reciter.bitrateKbps)) {
      throw ArgumentError(
        'The selected reciter is not in the verified catalog.',
      );
    }
  }

  void _validateSurahAndVerses(Surah surah, List<QuranVerse> verses) {
    if (verses.length != surah.verseCount) {
      throw ArgumentError('All canonical verses for the Surah are required.');
    }
    for (var index = 0; index < verses.length; index++) {
      final verse = verses[index];
      if (verse.surahNumber != surah.number ||
          verse.verseNumber != index + 1 ||
          verse.globalVerseNumber <= 0 ||
          (index > 0 &&
              verse.globalVerseNumber !=
                  verses[index - 1].globalVerseNumber + 1)) {
        throw ArgumentError('The Surah verses are not in canonical order.');
      }
    }
  }

  Map<int, List<QuranVerse>> _validateAndGroupVerses(
    List<Surah> surahs,
    List<QuranVerse> verses,
  ) {
    final grouped = <int, List<QuranVerse>>{};
    for (final verse in verses) {
      grouped.putIfAbsent(verse.surahNumber, () => []).add(verse);
    }
    for (final surah in surahs) {
      final surahVerses = grouped[surah.number];
      if (surahVerses == null) {
        throw ArgumentError('Surah ${surah.number} has no verse records.');
      }
      _validateSurahAndVerses(surah, surahVerses);
    }
    if (grouped.length != surahs.length) {
      throw ArgumentError('The verse list contains an unknown Surah.');
    }
    return grouped;
  }

  bool _validateResponse(QuranAudioDownloadResponse response, int offset) {
    if (response.statusCode == HttpStatus.ok) {
      return false;
    }
    if (response.statusCode == HttpStatus.partialContent) {
      final range = RegExp(r'^bytes\s+(\d+)-\d+/(?:\d+|\*)$')
          .firstMatch(response.contentRange ?? '');
      final start = range == null ? null : int.tryParse(range.group(1)!);
      if (start == null || start != offset) {
        throw const FormatException('The CDN returned an invalid byte range.');
      }
      return true;
    }
    final status = response.statusCode;
    throw QuranAudioDownloadException(
      'Audio CDN returned HTTP $status.',
      statusCode: status,
      retryable:
          status == HttpStatus.requestTimeout ||
          status == HttpStatus.tooManyRequests ||
          status >= HttpStatus.internalServerError,
    );
  }

  bool _isRetryable(Object error) {
    if (error is QuranAudioDownloadException) return error.retryable;
    return error is SocketException ||
        error is HttpException ||
        error is TimeoutException;
  }
}

class _DownloadJob {
  _DownloadJob({required this.record});

  QuranDownloadJobRecord record;
  Surah? surah;
  List<QuranVerse>? verses;
  QuranReciter? reciter;
  bool retryOnlyFailed = false;
  int currentBytes = 0;
  int? currentTotalBytes;
}

class _DownloadInterrupted implements Exception {
  const _DownloadInterrupted();
}

QuranDownloadJobRecord _copyRecord(
  QuranDownloadJobRecord record, {
  QuranDownloadStatus? status,
  String? error,
  String? batchId,
  bool clearError = false,
}) => QuranDownloadJobRecord(
  reciterId: record.reciterId,
  surahNumber: record.surahNumber,
  totalVerseCount: record.totalVerseCount,
  status: status ?? record.status,
  failedVerseNumbers: record.failedVerseNumbers,
  createdAt: record.createdAt,
  currentVerseNumber: record.currentVerseNumber,
  error: clearError ? null : error ?? record.error,
  batchId: batchId ?? record.batchId,
);

QuranDownloadJobRecord _withStatus(
  QuranDownloadJobRecord record,
  QuranDownloadStatus status, {
  String? error,
  bool clearError = false,
}) => _copyRecord(record, status: status, error: error, clearError: clearError);

QuranDownloadJobRecord _withCurrentVerse(
  QuranDownloadJobRecord record,
  int? verseNumber,
) => QuranDownloadJobRecord(
  reciterId: record.reciterId,
  surahNumber: record.surahNumber,
  totalVerseCount: record.totalVerseCount,
  status: record.status,
  failedVerseNumbers: record.failedVerseNumbers,
  createdAt: record.createdAt,
  currentVerseNumber: verseNumber,
  error: record.error,
  batchId: record.batchId,
);

QuranDownloadJobRecord _withFailedVerse(
  QuranDownloadJobRecord record,
  int verseNumber,
) => QuranDownloadJobRecord(
  reciterId: record.reciterId,
  surahNumber: record.surahNumber,
  totalVerseCount: record.totalVerseCount,
  status: record.status,
  failedVerseNumbers: {...record.failedVerseNumbers, verseNumber},
  createdAt: record.createdAt,
  currentVerseNumber: record.currentVerseNumber,
  error: record.error,
  batchId: record.batchId,
);

QuranDownloadJobRecord _withoutFailedVerse(
  QuranDownloadJobRecord record,
  int verseNumber,
) => QuranDownloadJobRecord(
  reciterId: record.reciterId,
  surahNumber: record.surahNumber,
  totalVerseCount: record.totalVerseCount,
  status: record.status,
  failedVerseNumbers: {...record.failedVerseNumbers}..remove(verseNumber),
  createdAt: record.createdAt,
  currentVerseNumber: record.currentVerseNumber,
  error: record.failedVerseNumbers.length <= 1 ? null : record.error,
  batchId: record.batchId,
);

QuranDownloadJobRecord _withError(
  QuranDownloadJobRecord record,
  String error,
) => _copyRecord(record, error: error);
