import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'quran_download_models.dart';

class QuranAudioStorage {
  QuranAudioStorage({required this.rootDirectory});

  static const _manifestVersion = 2;
  static const _surahManifestVersion = 1;
  final Directory rootDirectory;
  final Map<String, QuranDownloadedVerse> _records = {};
  List<QuranDownloadJobRecord> _jobs = const [];
  String _selectedReciterId = 'ar.alafasy';
  Future<void> _writeTail = Future<void>.value();

  Directory get audioDirectory =>
      Directory('${rootDirectory.path}${Platform.pathSeparator}audio');

  List<QuranDownloadedVerse> get records => List.unmodifiable(_records.values);

  List<QuranDownloadJobRecord> get jobs => List.unmodifiable(_jobs);

  String get selectedReciterId => _selectedReciterId;

  int recordCountForSurah(String reciterId, int surahNumber) => _records.values
      .where(
        (record) =>
            record.reciterId == reciterId && record.surahNumber == surahNumber,
      )
      .length;

  Future<void> initialize() async {
    await audioDirectory.create(recursive: true);
    final manifest = _manifestFile;
    final backup = _backupFile;
    File? source;
    var isLegacyManifest = false;
    if (await manifest.exists()) {
      source = manifest;
    } else if (await backup.exists()) {
      source = backup;
    }

    if (source != null) {
      final decoded = jsonDecode(await source.readAsString());
      if (decoded is! Map<String, dynamic> ||
          (decoded['version'] != 1 && decoded['version'] != _manifestVersion) ||
          decoded['jobs'] is! List) {
        throw const FormatException('The local audio manifest is malformed.');
      }

      final reciterId = decoded['selectedReciterId'];
      if (reciterId is String && _isSafeReciterId(reciterId)) {
        _selectedReciterId = reciterId;
      }
      isLegacyManifest = decoded['version'] == 1;
      if (isLegacyManifest) {
        final legacyVerses = decoded['verses'];
        if (legacyVerses is! List) {
          throw const FormatException('The local audio manifest is malformed.');
        }
        for (final value in legacyVerses) {
          if (value is! Map<String, dynamic>) {
            throw const FormatException(
              'A downloaded verse record is malformed.',
            );
          }
          final record = QuranDownloadedVerse.fromJson(value);
          if (_records.containsKey(record.key)) {
            throw const FormatException(
              'The audio manifest has duplicate verses.',
            );
          }
          _records[record.key] = record;
        }
      }
      _jobs = (decoded['jobs'] as List)
          .map((value) {
            if (value is! Map<String, dynamic>) {
              throw const FormatException('A Quran download job is malformed.');
            }
            final job = QuranDownloadJobRecord.fromJson(value);
            return switch (job.status) {
              QuranDownloadStatus.waiting || QuranDownloadStatus.downloading =>
                _copyJob(job, status: QuranDownloadStatus.paused),
              _ => job,
            };
          })
          .toList(growable: false);
    }

    await _loadSurahManifests();
    if (source != null) {
      if (isLegacyManifest) {
        final identities = _records.values
            .map((record) => '${record.reciterId}:${record.surahNumber}')
            .toSet();
        for (final identity in identities) {
          final parts = identity.split(':');
          await _persistSurah(parts[0], int.parse(parts[1]));
        }
      }
      await _persist();
    }
    await reconcile();
  }

  Future<int> reconcile() async {
    final invalidKeys = <String>[];
    for (final record in _records.values) {
      final file = audioFileFor(
        record.reciterId,
        record.surahNumber,
        record.verseNumber,
      );
      if (!await isValidAudioFile(file, expectedLength: record.fileSize)) {
        invalidKeys.add(record.key);
      }
    }
    for (final key in invalidKeys) {
      _records.remove(key);
    }
    if (invalidKeys.isNotEmpty) {
      final affected = <String>{};
      for (final key in invalidKeys) {
        final parts = key.split(':');
        affected.add('${parts[0]}:${parts[1]}');
      }
      for (final identity in affected) {
        final parts = identity.split(':');
        await _persistSurah(parts[0], int.parse(parts[1]));
      }
    }
    return invalidKeys.length;
  }

  File audioFileFor(String reciterId, int surahNumber, int verseNumber) {
    _validateIdentity(reciterId, surahNumber, verseNumber);
    return File(
      '${_surahDirectory(reciterId, surahNumber).path}'
      '${Platform.pathSeparator}ayah_${verseNumber.toString().padLeft(3, '0')}.mp3',
    );
  }

  File partialFileFor(String reciterId, int surahNumber, int verseNumber) {
    final audioFile = audioFileFor(reciterId, surahNumber, verseNumber);
    return File('${audioFile.path}.part');
  }

  Future<QuranDownloadedVerse?> findValidVerse(
    String reciterId,
    int surahNumber,
    int verseNumber,
    int globalVerseNumber,
  ) async {
    final key = '$reciterId:$surahNumber:$verseNumber';
    final record = _records[key];
    if (record == null) return null;
    if (record.globalVerseNumber != globalVerseNumber ||
        !await isValidAudioFile(
          audioFileFor(reciterId, surahNumber, verseNumber),
          expectedLength: record.fileSize,
        )) {
      _records.remove(key);
      await _persistSurah(reciterId, surahNumber);
      return null;
    }
    return record;
  }

  Future<QuranDownloadedVerse?> adoptExistingAudio(
    QuranDownloadedVerse record,
  ) async {
    final file = audioFileFor(
      record.reciterId,
      record.surahNumber,
      record.verseNumber,
    );
    if (!await isValidAudioFile(file)) return null;
    final adopted = _withFileSize(record, await file.length());
    _records[adopted.key] = adopted;
    await _persistSurah(adopted.reciterId, adopted.surahNumber);
    return adopted;
  }

  Future<QuranDownloadedVerse> commitAudioFile({
    required File partialFile,
    required QuranDownloadedVerse record,
  }) async {
    final destination = audioFileFor(
      record.reciterId,
      record.surahNumber,
      record.verseNumber,
    );
    if (partialFile.absolute.path !=
        partialFileFor(
          record.reciterId,
          record.surahNumber,
          record.verseNumber,
        ).absolute.path) {
      throw ArgumentError.value(partialFile.path, 'partialFile');
    }
    if (!await isValidAudioFile(partialFile, expectedLength: record.fileSize)) {
      throw const FormatException('The downloaded audio file is invalid.');
    }

    await destination.parent.create(recursive: true);
    if (await destination.exists()) {
      if (await isValidAudioFile(destination)) {
        await partialFile.delete();
        final existing = _withFileSize(record, await destination.length());
        _records[existing.key] = existing;
        await _persistSurah(existing.reciterId, existing.surahNumber);
        return existing;
      }
      await destination.delete();
    }
    await partialFile.rename(destination.path);
    final committed = _withFileSize(record, await destination.length());
    _records[committed.key] = committed;
    await _persistSurah(committed.reciterId, committed.surahNumber);
    return committed;
  }

  Future<void> saveJobs(List<QuranDownloadJobRecord> jobs) async {
    final unique = <String, QuranDownloadJobRecord>{};
    for (final job in jobs) {
      if (unique.containsKey(job.key)) {
        throw ArgumentError('Duplicate download job: ${job.key}.');
      }
      unique[job.key] = job;
    }
    _jobs = List.unmodifiable(unique.values);
    await _persist();
  }

  Future<void> setSelectedReciter(String reciterId) async {
    if (!_isSafeReciterId(reciterId)) {
      throw ArgumentError.value(reciterId, 'reciterId');
    }
    final previous = _selectedReciterId;
    _selectedReciterId = reciterId;
    try {
      await _persist();
    } catch (_) {
      _selectedReciterId = previous;
      rethrow;
    }
  }

  Future<int> storageBytes({String? reciterId}) async {
    var total = 0;
    for (final record in _records.values) {
      if (reciterId != null && record.reciterId != reciterId) continue;
      final file = audioFileFor(
        record.reciterId,
        record.surahNumber,
        record.verseNumber,
      );
      if (await file.exists()) {
        total += await file.length();
      }
    }
    return total;
  }

  Future<void> deleteSurah(String reciterId, int surahNumber) async {
    if (!_isSafeReciterId(reciterId) || surahNumber < 1 || surahNumber > 114) {
      throw ArgumentError('Invalid Quran download identity.');
    }
    final directory = _surahDirectory(reciterId, surahNumber);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    _records.removeWhere(
      (key, record) =>
          record.reciterId == reciterId && record.surahNumber == surahNumber,
    );
    _jobs = _jobs
        .where(
          (job) => job.reciterId != reciterId || job.surahNumber != surahNumber,
        )
        .toList(growable: false);
    await _persist();
  }

  Future<void> deleteReciter(String reciterId) async {
    if (!_isSafeReciterId(reciterId)) {
      throw ArgumentError.value(reciterId, 'reciterId');
    }
    final directory = Directory(
      '${audioDirectory.path}${Platform.pathSeparator}$reciterId',
    );
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    _records.removeWhere((_, record) => record.reciterId == reciterId);
    _jobs = _jobs
        .where((job) => job.reciterId != reciterId)
        .toList(growable: false);
    await _persist();
  }

  Future<void> clearAll() async {
    if (await audioDirectory.exists()) {
      await audioDirectory.delete(recursive: true);
    }
    await audioDirectory.create(recursive: true);
    _records.clear();
    _jobs = const [];
    await _persist();
  }

  Future<void> close() async {
    await _writeTail;
  }

  Directory _surahDirectory(String reciterId, int surahNumber) {
    if (!_isSafeReciterId(reciterId) || surahNumber < 1 || surahNumber > 114) {
      throw ArgumentError('Invalid Quran download identity.');
    }
    return Directory(
      '${audioDirectory.path}${Platform.pathSeparator}$reciterId'
      '${Platform.pathSeparator}surah_${surahNumber.toString().padLeft(3, '0')}',
    );
  }

  File get _manifestFile => File(
    '${rootDirectory.path}${Platform.pathSeparator}download_manifest.json',
  );

  File get _backupFile => File(
    '${rootDirectory.path}${Platform.pathSeparator}download_manifest.bak',
  );

  Future<File?> _existingSurahManifest(
    String reciterId,
    int surahNumber,
  ) async {
    final manifest = _surahManifestFile(reciterId, surahNumber);
    if (await manifest.exists()) return manifest;
    final backup = File('${manifest.path}.bak');
    return await backup.exists() ? backup : null;
  }

  File _surahManifestFile(String reciterId, int surahNumber) => File(
    '${_surahDirectory(reciterId, surahNumber).path}'
    '${Platform.pathSeparator}download_manifest.json',
  );

  Future<void> _loadSurahManifests() async {
    if (!await audioDirectory.exists()) return;
    await for (final reciterEntity in audioDirectory.list(followLinks: false)) {
      if (reciterEntity is! Directory) continue;
      final reciterId = reciterEntity.path.split(Platform.pathSeparator).last;
      if (!_isSafeReciterId(reciterId)) continue;
      await for (final surahEntity in reciterEntity.list(followLinks: false)) {
        if (surahEntity is! Directory) continue;
        final match = RegExp(r'^surah_(\d{3})$')
            .firstMatch(surahEntity.path.split(Platform.pathSeparator).last);
        final surahNumber = match == null
            ? null
            : int.tryParse(match.group(1)!);
        if (surahNumber == null || surahNumber < 1 || surahNumber > 114) {
          continue;
        }
        final manifest = await _existingSurahManifest(reciterId, surahNumber);
        if (manifest == null) continue;
        final decoded = jsonDecode(await manifest.readAsString());
        if (decoded is! Map<String, dynamic> ||
            decoded['version'] != _surahManifestVersion ||
            decoded['reciterId'] != reciterId ||
            decoded['surahNumber'] != surahNumber ||
            decoded['verses'] is! List) {
          throw const FormatException('A Surah audio manifest is malformed.');
        }
        var requiresRewrite = false;
        for (final value in decoded['verses'] as List) {
          if (value is! Map<String, dynamic>) {
            throw const FormatException(
              'A downloaded verse record is malformed.',
            );
          }
          final record = QuranDownloadedVerse.fromJson(value);
          final existing = _records[record.key];
          if (record.reciterId != reciterId ||
              record.surahNumber != surahNumber ||
              (existing != null && existing.fileSize != record.fileSize)) {
            throw const FormatException(
              'A Surah audio manifest contains mismatched or duplicate verses.',
            );
          }
          final file = audioFileFor(reciterId, surahNumber, record.verseNumber);
          if (await isValidAudioFile(file, expectedLength: record.fileSize)) {
            _records.putIfAbsent(record.key, () => record);
          } else {
            requiresRewrite = true;
          }
        }
        if (requiresRewrite) {
          await _persistSurah(reciterId, surahNumber);
        }
      }
    }
  }

  Future<void> _persistSurah(String reciterId, int surahNumber) =>
      _writeSerially(() async {
        final records = _records.values
            .where(
              (record) =>
                  record.reciterId == reciterId &&
                  record.surahNumber == surahNumber,
            )
            .toList(growable: false);
        if (records.isEmpty) {
          final manifest = _surahManifestFile(reciterId, surahNumber);
          for (final file in [
            manifest,
            File('${manifest.path}.bak'),
            File('${manifest.path}.tmp'),
          ]) {
            if (await file.exists()) await file.delete();
          }
          return;
        }
        await _writeAtomically(
          _surahManifestFile(reciterId, surahNumber),
          jsonEncode({
            'version': _surahManifestVersion,
            'reciterId': reciterId,
            'surahNumber': surahNumber,
            'verses': records.map((record) => record.toJson()).toList(),
          }),
        );
      });

  Future<void> _persist() => _writeSerially(() async {
    await _writeAtomically(
      _manifestFile,
      jsonEncode({
        'version': _manifestVersion,
        'selectedReciterId': _selectedReciterId,
        'jobs': _jobs.map((job) => job.toJson()).toList(),
      }),
    );
  });

  Future<void> _writeSerially(Future<void> Function() write) {
    final completed = Completer<void>();
    final previous = _writeTail;
    _writeTail = completed.future;
    return () async {
      try {
        await previous;
        await rootDirectory.create(recursive: true);
        await write();
      } finally {
        completed.complete();
      }
    }();
  }

  Future<void> _writeAtomically(File target, String contents) async {
    await target.parent.create(recursive: true);
    final temporary = File('${target.path}.tmp');
    final backup = File('${target.path}.bak');
    await temporary.writeAsString(contents, flush: true);
    if (await backup.exists()) await backup.delete();
    if (await target.exists()) await target.rename(backup.path);
    try {
      await temporary.rename(target.path);
    } catch (_) {
      if (!await target.exists() && await backup.exists()) {
        await backup.rename(target.path);
      }
      rethrow;
    }
    if (await backup.exists()) await backup.delete();
  }

  static Future<bool> isValidAudioFile(File file, {int? expectedLength}) async {
    if (!await file.exists()) return false;
    final length = await file.length();
    if (length < 128 || (expectedLength != null && length != expectedLength)) {
      return false;
    }
    final handle = await file.open();
    try {
      final prefix = await handle.read(10);
      var scanStart = 0;
      if (prefix.length >= 10 &&
          prefix[0] == 0x49 &&
          prefix[1] == 0x44 &&
          prefix[2] == 0x33) {
        final tagSize =
            ((prefix[6] & 0x7f) << 21) |
            ((prefix[7] & 0x7f) << 14) |
            ((prefix[8] & 0x7f) << 7) |
            (prefix[9] & 0x7f);
        scanStart = 10 + tagSize;
      }
      if (scanStart >= length) return false;
      await handle.setPosition(scanStart);
      final audio = await handle.read(
        (length - scanStart).clamp(0, 8192).toInt(),
      );
      for (var index = 0; index + 3 < audio.length; index++) {
        final first = audio[index];
        final second = audio[index + 1];
        final third = audio[index + 2];
        if (first == 0xff &&
            (second & 0xe0) == 0xe0 &&
            ((second >> 1) & 0x03) == 0x01 &&
            ((third >> 4) & 0x0f) != 0 &&
            ((third >> 4) & 0x0f) != 0x0f &&
            ((third >> 2) & 0x03) != 0x03) {
          return true;
        }
      }
      return false;
    } finally {
      await handle.close();
    }
  }

  static QuranDownloadedVerse _withFileSize(
    QuranDownloadedVerse record,
    int fileSize,
  ) => QuranDownloadedVerse(
    reciterId: record.reciterId,
    surahNumber: record.surahNumber,
    verseNumber: record.verseNumber,
    globalVerseNumber: record.globalVerseNumber,
    fileSize: fileSize,
    downloadedAt: record.downloadedAt,
    sourceUrl: record.sourceUrl,
    sourceName: record.sourceName,
  );

  static QuranDownloadJobRecord _copyJob(
    QuranDownloadJobRecord job, {
    required QuranDownloadStatus status,
  }) => QuranDownloadJobRecord(
    reciterId: job.reciterId,
    surahNumber: job.surahNumber,
    totalVerseCount: job.totalVerseCount,
    status: status,
    failedVerseNumbers: job.failedVerseNumbers,
    createdAt: job.createdAt,
    currentVerseNumber: job.currentVerseNumber,
    error: job.error,
    batchId: job.batchId,
  );

  static void _validateIdentity(
    String reciterId,
    int surahNumber,
    int verseNumber,
  ) {
    if (!_isSafeReciterId(reciterId) ||
        surahNumber < 1 ||
        surahNumber > 114 ||
        verseNumber < 1) {
      throw ArgumentError('Invalid Quran audio file identity.');
    }
  }

  static bool _isSafeReciterId(String value) =>
      RegExp(r'^[a-z0-9._-]+$').hasMatch(value);
}
