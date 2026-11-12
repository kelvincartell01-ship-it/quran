import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran/audio/quran_audio_source_resolver.dart';
import 'package:quran/features/quran/audio/quran_reciter.dart';
import 'package:quran/features/quran/domain/quran_verse.dart';
import 'package:quran/features/quran/domain/surah.dart';
import 'package:quran/features/quran/downloads/quran_audio_download_client.dart';
import 'package:quran/features/quran/downloads/quran_audio_storage.dart';
import 'package:quran/features/quran/downloads/quran_download_manager.dart';
import 'package:quran/features/quran/downloads/quran_download_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'individual download saves canonical verse identity and survives restart',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'quran-audio-download-',
      );
      final firstClient = _FakeAudioDownloadClient();
      final manager = await _createManager(root, firstClient);
      var managerDisposed = false;
      addTearDown(() async {
        if (!managerDisposed) await manager.dispose();
        if (await root.exists()) await root.delete(recursive: true);
      });

      await manager.downloadSurah(
        surah: _testSurah,
        verses: _testVerses,
        reciter: _alafasy,
      );
      await _waitFor(
        () =>
            manager.state
                .forSurah(_alafasy.identifier, _testSurah.number)
                ?.status ==
            QuranDownloadStatus.completed,
      );

      final record = manager.storage.records.first;
      final file = manager.storage.audioFileFor(
        record.reciterId,
        record.surahNumber,
        record.verseNumber,
      );
      expect(record.globalVerseNumber, 8);
      expect(record.sourceUrl, contains('/8.mp3'));
      expect(await file.exists(), isTrue);
      expect(
        file.path,
        contains(
          '${Platform.pathSeparator}audio${Platform.pathSeparator}'
          'ar.alafasy${Platform.pathSeparator}surah_002',
        ),
      );
      expect(manager.state.totalStorageBytes, 2 * _validMp3.length);

      await manager.dispose();
      managerDisposed = true;
      final restored = await _createManager(root, _FakeAudioDownloadClient());
      addTearDown(restored.dispose);
      expect(
        restored.state.forSurah(_alafasy.identifier, _testSurah.number)?.status,
        QuranDownloadStatus.completed,
      );
      expect(restored.storage.records, hasLength(2));
    },
  );

  test(
    'duplicate Surah requests do not create duplicate verse downloads',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'quran-audio-duplicate-',
      );
      final client = _FakeAudioDownloadClient();
      final manager = await _createManager(root, client);
      addTearDown(() async {
        await manager.dispose();
        if (await root.exists()) await root.delete(recursive: true);
      });

      await manager.downloadSurah(
        surah: _testSurah,
        verses: _testVerses,
        reciter: _alafasy,
      );
      await manager.downloadSurah(
        surah: _testSurah,
        verses: _testVerses,
        reciter: _alafasy,
      );
      await _waitFor(
        () =>
            manager.state
                .forSurah(_alafasy.identifier, _testSurah.number)
                ?.status ==
            QuranDownloadStatus.completed,
      );

      expect(client.requestedUris, hasLength(2));
      expect(client.maxConcurrentResponses, 1);
    },
  );

  test('a complete Quran batch schedules 114 Surahs with one worker', () async {
    final root = await Directory.systemTemp.createTemp('quran-audio-bulk-');
    final client = _FakeAudioDownloadClient();
    final manager = await _createManager(root, client);
    addTearDown(() async {
      await manager.dispose();
      if (await root.exists()) await root.delete(recursive: true);
    });
    final surahs = [
      for (var number = 1; number <= 114; number++)
        Surah(
          number: number,
          arabicName: 'Surah $number',
          transliteration: 'Surah $number',
          verseCount: 1,
          revelationOrder: number,
          revelationType: RevelationType.makki,
        ),
    ];
    final verses = [
      for (var number = 1; number <= 114; number++)
        QuranVerse(
          surahNumber: number,
          verseNumber: 1,
          globalVerseNumber: number,
          arabicText: 'unused',
          soraniTranslation: 'unused',
        ),
    ];

    await manager.downloadAll(
      surahs: surahs,
      verses: verses,
      reciter: _alafasy,
    );
    await _waitFor(
      () => manager.state.batches.values.any(
        (batch) => batch.status == QuranDownloadStatus.completed,
      ),
      timeout: const Duration(seconds: 60),
    );

    final batch = manager.state.batches.values.single;
    expect(batch.totalSurahs, 114);
    expect(batch.completedSurahs, 114);
    expect(batch.totalVerseCount, 114);
    expect(client.requestedUris, hasLength(114));
    expect(client.maxConcurrentResponses, 1);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test(
    'pause and resume uses HTTP range without losing partial bytes',
    () async {
      final root = await Directory.systemTemp.createTemp('quran-audio-resume-');
      var manager = await _createManager(
        root,
        _FakeAudioDownloadClient(stallFirstResponse: true),
      );
      var managerDisposed = false;
      addTearDown(() async {
        if (!managerDisposed) await manager.dispose();
        if (await root.exists()) await root.delete(recursive: true);
      });

      await manager.downloadSurah(
        surah: _testSurah,
        verses: _testVerses,
        reciter: _alafasy,
      );
      final firstClient = manager.client as _FakeAudioDownloadClient;
      await _waitFor(
        () =>
            firstClient.sentPartialResponse &&
            (manager.state
                        .forSurah(_alafasy.identifier, _testSurah.number)
                        ?.currentBytes ??
                    0) >
                0,
      );
      await manager.pauseSurah(_alafasy.identifier, _testSurah.number);
      await _waitFor(
        () =>
            manager.state
                .forSurah(_alafasy.identifier, _testSurah.number)
                ?.status ==
            QuranDownloadStatus.paused,
      );
      final partial = manager.storage.partialFileFor(
        _alafasy.identifier,
        _testSurah.number,
        1,
      );
      final partialLength = await partial.length();
      expect(partialLength, greaterThan(0));

      await manager.dispose();
      managerDisposed = true;
      final resumedClient = _FakeAudioDownloadClient();
      manager = await _createManager(root, resumedClient);
      managerDisposed = false;
      expect(
        manager.state.forSurah(_alafasy.identifier, _testSurah.number)?.status,
        QuranDownloadStatus.paused,
      );
      await manager.resumeSurah(
        surah: _testSurah,
        verses: _testVerses,
        reciter: _alafasy,
      );
      await _waitFor(
        () =>
            manager.state
                .forSurah(_alafasy.identifier, _testSurah.number)
                ?.status ==
            QuranDownloadStatus.completed,
      );

      expect(resumedClient.rangeStarts, contains(partialLength));
      expect(
        await manager.storage
            .audioFileFor(_alafasy.identifier, _testSurah.number, 1)
            .length(),
        _validMp3.length,
      );
    },
  );

  test(
    'invalid audio is never committed and failed verses can be retried',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'quran-audio-invalid-',
      );
      final client = _FakeAudioDownloadClient(invalidFirstVerse: true);
      final manager = await _createManager(root, client);
      addTearDown(() async {
        await manager.dispose();
        if (await root.exists()) await root.delete(recursive: true);
      });

      await manager.downloadSurah(
        surah: _testSurah,
        verses: _testVerses,
        reciter: _alafasy,
      );
      await _waitFor(
        () =>
            manager.state
                .forSurah(_alafasy.identifier, _testSurah.number)
                ?.status ==
            QuranDownloadStatus.failed,
      );

      expect(
        manager.state
            .forSurah(_alafasy.identifier, _testSurah.number)
            ?.failedVerseNumbers,
        contains(1),
      );
      expect(
        manager.storage
            .audioFileFor(_alafasy.identifier, _testSurah.number, 1)
            .existsSync(),
        isFalse,
      );
      expect(manager.storage.records, hasLength(1));

      await manager.retrySurah(
        surah: _testSurah,
        verses: _testVerses,
        reciter: _alafasy,
      );
      await _waitFor(
        () =>
            manager.state
                .forSurah(_alafasy.identifier, _testSurah.number)
                ?.status ==
            QuranDownloadStatus.completed,
      );
      expect(manager.storage.records, hasLength(2));
      expect(client.requestedUris, hasLength(3));
    },
  );

  test('offline playback prefers the matching reciter file and falls back remotely', () async {
    final root = await Directory.systemTemp.createTemp('quran-audio-source-');
    final manager = await _createManager(root, _FakeAudioDownloadClient());
    addTearDown(() async {
      await manager.dispose();
      if (await root.exists()) await root.delete(recursive: true);
    });
    await manager.downloadSurah(
      surah: _testSurah,
      verses: _testVerses,
      reciter: _alafasy,
    );
    await _waitFor(
      () =>
          manager.state
              .forSurah(_alafasy.identifier, _testSurah.number)
              ?.status ==
          QuranDownloadStatus.completed,
    );

    final resolver = LocalFirstQuranAudioSourceResolver(manager.storage);
    final localUri = await resolver.resolve(_testVerses.first, _alafasy);
    final remoteUri = await resolver.resolve(_testVerses.first, _husary);

    expect(localUri.scheme, 'file');
    expect(remoteUri.toString(), contains('/64/ar.husary/8.mp3'));
  });

  test('delete removes only the requested reciter and Surah files', () async {
    final root = await Directory.systemTemp.createTemp('quran-audio-delete-');
    final manager = await _createManager(root, _FakeAudioDownloadClient());
    addTearDown(() async {
      await manager.dispose();
      if (await root.exists()) await root.delete(recursive: true);
    });
    await manager.downloadSurah(
      surah: _testSurah,
      verses: _testVerses,
      reciter: _alafasy,
    );
    await manager.downloadSurah(
      surah: _testSurah,
      verses: _testVerses,
      reciter: _husary,
    );
    await _waitFor(
      () =>
          manager.state
                  .forSurah(_alafasy.identifier, _testSurah.number)
                  ?.status ==
              QuranDownloadStatus.completed &&
          manager.state
                  .forSurah(_husary.identifier, _testSurah.number)
                  ?.status ==
              QuranDownloadStatus.completed,
    );

    await manager.deleteSurah(_alafasy.identifier, _testSurah.number);

    expect(manager.storage.records, hasLength(2));
    expect(manager.state.forSurah(_alafasy.identifier, 2), isNull);
    expect(
      manager.state.forSurah(_husary.identifier, _testSurah.number)?.status,
      QuranDownloadStatus.completed,
    );
    expect(manager.state.totalStorageBytes, 2 * _validMp3.length);
    expect(
      await manager.storage
          .audioFileFor(_husary.identifier, _testSurah.number, 1)
          .exists(),
      isTrue,
    );
  });
}

Future<QuranDownloadManager> _createManager(
  Directory root,
  _FakeAudioDownloadClient client,
) => QuranDownloadManager.create(
  storage: QuranAudioStorage(rootDirectory: root),
  client: client,
);

Future<void> _waitFor(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException(
        'The Quran audio download did not finish in time.',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 8));
  }
}

const _testSurah = Surah(
  number: 2,
  arabicName: 'Test Surah',
  transliteration: 'Test Surah',
  verseCount: 2,
  revelationOrder: 1,
  revelationType: RevelationType.makki,
);

const _testVerses = [
  QuranVerse(
    surahNumber: 2,
    verseNumber: 1,
    globalVerseNumber: 8,
    arabicText: 'unused',
    soraniTranslation: 'unused',
  ),
  QuranVerse(
    surahNumber: 2,
    verseNumber: 2,
    globalVerseNumber: 9,
    arabicText: 'unused',
    soraniTranslation: 'unused',
  ),
];

const _alafasy = QuranReciter(
  identifier: 'ar.alafasy',
  arabicName: 'Alafasy',
  englishName: 'Alafasy',
  bitrateKbps: 128,
  verifiedAyahCount: 6236,
);

const _husary = QuranReciter(
  identifier: 'ar.husary',
  arabicName: 'Husary',
  englishName: 'Husary',
  bitrateKbps: 64,
  verifiedAyahCount: 6236,
);

final _validMp3 = Uint8List.fromList([
  0xff,
  0xfb,
  0x90,
  0x64,
  ...List<int>.filled(252, 0),
]);

class _FakeAudioDownloadClient implements QuranAudioDownloadClient {
  _FakeAudioDownloadClient({
    this.stallFirstResponse = false,
    this.invalidFirstVerse = false,
  });

  final bool stallFirstResponse;
  final bool invalidFirstVerse;
  final List<Uri> requestedUris = [];
  final List<int?> rangeStarts = [];
  bool sentPartialResponse = false;
  bool _stalled = false;
  int _activeResponses = 0;
  int maxConcurrentResponses = 0;
  bool _invalidResponseUsed = false;

  @override
  Future<QuranAudioDownloadResponse> get(Uri uri, {int? rangeStart}) async {
    requestedUris.add(uri);
    rangeStarts.add(rangeStart);
    final verseNumber = int.parse(uri.pathSegments.last.split('.').first);
    if (invalidFirstVerse && verseNumber == 8 && !_invalidResponseUsed) {
      _invalidResponseUsed = true;
      return _response(
        statusCode: HttpStatus.ok,
        body: _track(Stream.value(List<int>.filled(256, 0))),
        contentLength: 256,
      );
    }

    if (stallFirstResponse && !_stalled && rangeStart == null) {
      _stalled = true;
      final controller = StreamController<List<int>>();
      scheduleMicrotask(() {
        if (!controller.isClosed) {
          controller.add(_validMp3.sublist(0, 160));
          sentPartialResponse = true;
        }
      });
      return _response(
        statusCode: HttpStatus.ok,
        body: _track(controller.stream),
        contentLength: _validMp3.length,
        abort: () {
          if (!controller.isClosed) {
            controller.addError(const HttpException('paused'));
            unawaited(controller.close());
          }
        },
      );
    }

    final bytes = rangeStart == null
        ? _validMp3
        : _validMp3.sublist(rangeStart);
    final statusCode = rangeStart == null
        ? HttpStatus.ok
        : HttpStatus.partialContent;
    return _response(
      statusCode: statusCode,
      body: _track(Stream.value(bytes)),
      contentLength: bytes.length,
      contentRange: rangeStart == null
          ? null
          : 'bytes $rangeStart-${_validMp3.length - 1}/${_validMp3.length}',
    );
  }

  QuranAudioDownloadResponse _response({
    required int statusCode,
    required Stream<List<int>> body,
    required int contentLength,
    String? contentRange,
    void Function()? abort,
  }) => QuranAudioDownloadResponse(
    statusCode: statusCode,
    body: body,
    contentLength: contentLength,
    contentRange: contentRange,
    abort: abort ?? () {},
  );

  Stream<List<int>> _track(Stream<List<int>> source) async* {
    _activeResponses++;
    if (_activeResponses > maxConcurrentResponses) {
      maxConcurrentResponses = _activeResponses;
    }
    try {
      await for (final chunk in source) {
        yield chunk;
      }
    } finally {
      _activeResponses--;
    }
  }

  @override
  Future<void> close() async {}
}
