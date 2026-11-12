import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/features/quran/audio/quran_audio_engine.dart';
import 'package:quran/features/quran/audio/quran_audio_catalog.dart';
import 'package:quran/features/quran/audio/quran_audio_controller.dart';
import 'package:quran/features/quran/audio/quran_audio_handler.dart';
import 'package:quran/features/quran/audio/quran_audio_preferences.dart';
import 'package:quran/features/quran/audio/quran_audio_queue.dart';
import 'package:quran/features/quran/audio/quran_audio_session.dart';
import 'package:quran/features/quran/audio/quran_reciter.dart';
import 'package:quran/features/quran/audio/quran_reciter_data_source.dart';
import 'package:quran/features/quran/domain/quran_verse.dart';
import 'package:quran/features/quran/domain/surah.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'local catalog has 11 distinct reciters with complete coverage',
    () async {
      final reciters = await const AssetQuranReciterDataSource().loadReciters();

      expect(reciters, hasLength(11));
      expect(
        reciters.map((reciter) => reciter.identifier).toSet(),
        hasLength(11),
      );
      expect(
        reciters.every((reciter) => reciter.verifiedAyahCount == 6236),
        isTrue,
      );
    },
  );

  test('local media artwork is registered as a bundled image asset', () async {
    final artwork = await rootBundle.load('assets/images/quran_audio_art.png');

    expect(artwork.lengthInBytes, greaterThan(0));
  });

  test(
    'queue uses canonical global ayah IDs and verified reciter endpoints',
    () {
      final tracks = const QuranAudioQueueBuilder().build(
        surah: _testSurah,
        verses: _testVerses,
        reciter: _alafasy,
        artworkUri: Uri.file('C:\\audio-art.png'),
      );

      expect(tracks, hasLength(2));
      expect(tracks.map((track) => track.uri.toString()), [
        'https://cdn.islamic.network/quran/audio/128/ar.alafasy/8.mp3',
        'https://cdn.islamic.network/quran/audio/128/ar.alafasy/9.mp3',
      ]);
      expect(tracks[0].mediaItem.id, '8');
      expect(tracks[0].mediaItem.artUri, Uri.file('C:\\audio-art.png'));
      expect(tracks[0].mediaItem.extras?['surahNumber'], 2);
      expect(tracks[0].mediaItem.extras?['verseNumber'], 1);
      expect(tracks[1].mediaItem.extras?['globalVerseNumber'], 9);
    },
  );

  test(
    'audio preferences persist reciter, repeat mode, and resume position',
    () async {
      final sharedPreferences = await SharedPreferences.getInstance();
      final repository = QuranAudioPreferencesRepository(sharedPreferences);

      await repository.saveReciter(_husary.identifier);
      await repository.saveRepeatMode(LoopMode.one);
      await repository.savePlaybackContext(
        surahNumber: 2,
        verseNumber: 2,
        positionMilliseconds: 4200,
      );

      final restored = repository.load();
      expect(restored.reciterId, _husary.identifier);
      expect(restored.repeatMode, LoopMode.one);
      expect(restored.lastSurahNumber, 2);
      expect(restored.lastVerseNumber, 2);
      expect(restored.positionMilliseconds, 4200);
    },
  );

  test('switching reciters preserves the current ayah and position', () async {
    final harness = await _createHarness(resumeOnInterruptionEnd: true);
    addTearDown(harness.dispose);

    await harness.handler.playSurah(
      surah: _testSurah,
      verses: _testVerses,
      reciter: _alafasy,
    );
    await harness.engine.seek(const Duration(seconds: 4), index: 1);
    await harness.handler.selectReciter(_husary);

    expect(harness.engine.tracks, hasLength(2));
    expect(
      harness.engine.tracks[1].uri.toString(),
      'https://cdn.islamic.network/quran/audio/64/ar.husary/9.mp3',
    );
    expect(harness.engine.snapshot.currentIndex, 1);
    expect(harness.engine.snapshot.position, const Duration(seconds: 4));
    expect(harness.engine.snapshot.playing, isTrue);
    expect(harness.handler.status.verseNumber, 2);
  });

  test(
    'starting from an ayah creates a full-Surah queue at that ayah',
    () async {
      final harness = await _createHarness(resumeOnInterruptionEnd: true);
      addTearDown(harness.dispose);

      await harness.handler.playVerse(
        surah: _testSurah,
        verses: _testVerses,
        reciter: _alafasy,
        verseNumber: 2,
      );

      expect(harness.engine.tracks, hasLength(2));
      expect(harness.engine.snapshot.currentIndex, 1);
      expect(harness.engine.snapshot.position, Duration.zero);
      expect(harness.handler.status.globalVerseNumber, 9);
      expect(harness.engine.snapshot.playing, isTrue);
    },
  );

  test(
    'saved position is restored only after an explicit play action',
    () async {
      final sharedPreferences = await SharedPreferences.getInstance();
      final preferences = QuranAudioPreferencesRepository(sharedPreferences);
      await preferences.savePlaybackContext(
        surahNumber: 2,
        verseNumber: 2,
        positionMilliseconds: 4200,
      );
      final engine = _FakeQuranAudioEngine();
      final session = _FakeQuranAudioSession();
      final handler = QuranAudioHandler(
        engine: engine,
        session: session,
        preferences: preferences,
        initialPreferences: preferences.load(),
        artworkUri: Uri.file('C:\\audio-art.png'),
        resumeOnInterruptionEnd: true,
      );
      final harness = _AudioHarness(
        engine: engine,
        session: session,
        preferences: preferences,
        handler: handler,
      );
      addTearDown(harness.dispose);

      expect(engine.snapshot.playing, isFalse);
      expect(engine.tracks, isEmpty);
      await handler.playSurah(
        surah: _testSurah,
        verses: _testVerses,
        reciter: _alafasy,
      );

      expect(engine.snapshot.currentIndex, 1);
      expect(engine.snapshot.position, const Duration(milliseconds: 4200));
      expect(engine.snapshot.playing, isTrue);
    },
  );

  test(
    'Android focus restoration resumes only playback that was active',
    () async {
      final harness = await _createHarness(resumeOnInterruptionEnd: true);
      addTearDown(harness.dispose);
      await harness.handler.playSurah(
        surah: _testSurah,
        verses: _testVerses,
        reciter: _alafasy,
      );

      harness.session.emit(
        const QuranAudioInterruption(
          begin: true,
          kind: QuranAudioInterruptionKind.pause,
        ),
      );
      await _flushEvents();
      expect(harness.engine.snapshot.playing, isFalse);

      harness.session.emit(
        const QuranAudioInterruption(
          begin: false,
          kind: QuranAudioInterruptionKind.pause,
        ),
      );
      await _flushEvents();
      expect(harness.engine.snapshot.playing, isTrue);
    },
  );

  test(
    'iOS interruption end does not resume without shouldResume metadata',
    () async {
      final harness = await _createHarness(resumeOnInterruptionEnd: false);
      addTearDown(harness.dispose);
      await harness.handler.playSurah(
        surah: _testSurah,
        verses: _testVerses,
        reciter: _alafasy,
      );

      harness.session.emit(
        const QuranAudioInterruption(
          begin: true,
          kind: QuranAudioInterruptionKind.pause,
        ),
      );
      await _flushEvents();
      harness.session.emit(
        const QuranAudioInterruption(
          begin: false,
          kind: QuranAudioInterruptionKind.pause,
        ),
      );
      await _flushEvents();

      expect(harness.engine.snapshot.playing, isFalse);
    },
  );

  test(
    'user pause during interruption prevents automatic resumption',
    () async {
      final harness = await _createHarness(resumeOnInterruptionEnd: true);
      addTearDown(harness.dispose);
      await harness.handler.playSurah(
        surah: _testSurah,
        verses: _testVerses,
        reciter: _alafasy,
      );
      harness.session.emit(
        const QuranAudioInterruption(
          begin: true,
          kind: QuranAudioInterruptionKind.pause,
        ),
      );
      await _flushEvents();
      await harness.handler.pause();
      harness.session.emit(
        const QuranAudioInterruption(
          begin: false,
          kind: QuranAudioInterruptionKind.pause,
        ),
      );
      await _flushEvents();

      expect(harness.engine.snapshot.playing, isFalse);
    },
  );

  test('pause persists the current ayah and playback position', () async {
    final harness = await _createHarness(resumeOnInterruptionEnd: true);
    addTearDown(harness.dispose);
    await harness.handler.playSurah(
      surah: _testSurah,
      verses: _testVerses,
      reciter: _alafasy,
    );
    await harness.engine.seek(const Duration(milliseconds: 4200), index: 1);

    await harness.handler.pause();

    final restored = harness.preferences.load();
    expect(restored.lastSurahNumber, 2);
    expect(restored.lastVerseNumber, 2);
    expect(restored.positionMilliseconds, 4200);
  });

  test('repeat cycling persists Surah and verse repeat modes', () async {
    final harness = await _createHarness(resumeOnInterruptionEnd: true);
    addTearDown(harness.dispose);

    await harness.handler.cycleRepeatMode();
    expect(harness.preferences.load().repeatMode, LoopMode.all);
    await harness.handler.cycleRepeatMode();
    expect(harness.preferences.load().repeatMode, LoopMode.one);
    await harness.handler.cycleRepeatMode();
    expect(harness.preferences.load().repeatMode, LoopMode.off);
  });

  test('repeat-off playback advances through canonical Surah order', () async {
    final catalog = _FakeQuranAudioCatalog([
      _tinySurah(1),
      _tinySurah(2),
      _tinySurah(3),
    ]);
    final harness = await _createHarness(
      resumeOnInterruptionEnd: true,
      playbackCatalog: catalog,
    );
    addTearDown(harness.dispose);

    await harness.handler.playSurah(
      surah: _tinySurah(1),
      verses: [_tinyVerse(1, 1)],
      reciter: _alafasy,
    );

    for (var surahNumber = 2; surahNumber <= 3; surahNumber++) {
      final nextSurahPlaying = expectLater(
        harness.handler.statusStream,
        emitsThrough(
          predicate<QuranAudioStatus>(
            (status) =>
                status.surahNumber == surahNumber &&
                status.verseNumber == 1 &&
                status.playing,
          ),
        ),
      );
      harness.engine.completeCurrentQueue();
      await nextSurahPlaying;

      expect(harness.engine.tracks, hasLength(1));
      expect(harness.engine.tracks.single.mediaItem.id, '$surahNumber');
      expect(
        harness.engine.tracks.single.mediaItem.artist,
        _alafasy.englishName,
      );
      expect(harness.handler.status.selectedReciterId, _alafasy.identifier);
    }
  });

  test('repeat mode prevents automatic cross-Surah advancement', () async {
    final catalog = _FakeQuranAudioCatalog([_tinySurah(1), _tinySurah(2)]);
    final harness = await _createHarness(
      resumeOnInterruptionEnd: true,
      playbackCatalog: catalog,
    );
    addTearDown(harness.dispose);
    await harness.handler.cycleRepeatMode();
    await harness.handler.playSurah(
      surah: _tinySurah(1),
      verses: [_tinyVerse(1, 1)],
      reciter: _alafasy,
    );

    harness.engine.completeCurrentQueue();
    await _flushEvents();

    expect(catalog.getSurahCalls, 0);
    expect(harness.handler.status.surahNumber, 1);
    expect(harness.engine.tracks.single.mediaItem.id, '1');
  });

  test('playback stops cleanly after An-Nas completes', () async {
    final harness = await _createHarness(resumeOnInterruptionEnd: true);
    addTearDown(harness.dispose);
    await harness.handler.playSurah(
      surah: _tinySurah(114),
      verses: [_tinyVerse(114, 6236)],
      reciter: _alafasy,
    );
    final stopped = expectLater(
      harness.handler.statusStream,
      emitsThrough(
        predicate<QuranAudioStatus>(
          (status) => status.surahNumber == null && !status.playing,
        ),
      ),
    );

    harness.engine.completeCurrentQueue();
    await stopped;
    await _flushEvents();

    expect(harness.handler.queue.value, isEmpty);
    expect(harness.handler.status.surahNumber, isNull);
    expect(harness.session.active, isFalse);
  });

  test('user pause cancels a pending Surah transition', () async {
    final catalog = _GatedQuranAudioCatalog();
    final harness = await _createHarness(
      resumeOnInterruptionEnd: true,
      playbackCatalog: catalog,
    );
    addTearDown(harness.dispose);
    await harness.handler.playSurah(
      surah: _tinySurah(1),
      verses: [_tinyVerse(1, 1)],
      reciter: _alafasy,
    );

    harness.engine.completeCurrentQueue();
    await _flushEvents();
    await harness.handler.pause();
    catalog.nextSurah.complete(_tinySurah(2));
    await _flushEvents();

    expect(harness.engine.tracks.single.mediaItem.id, '1');
    expect(harness.handler.status.surahNumber, 1);
    expect(harness.engine.snapshot.playing, isFalse);
  });
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
    arabicText: 'test Arabic text',
    soraniTranslation: 'test Sorani meaning',
  ),
  QuranVerse(
    surahNumber: 2,
    verseNumber: 2,
    globalVerseNumber: 9,
    arabicText: 'test Arabic text',
    soraniTranslation: 'test Sorani meaning',
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

Surah _tinySurah(int number) => Surah(
  number: number,
  arabicName: 'Test Surah $number',
  transliteration: 'Test Surah $number',
  verseCount: 1,
  revelationOrder: number,
  revelationType: RevelationType.makki,
);

QuranVerse _tinyVerse(int surahNumber, int globalVerseNumber) => QuranVerse(
  surahNumber: surahNumber,
  verseNumber: 1,
  globalVerseNumber: globalVerseNumber,
  arabicText: 'test Arabic text',
  soraniTranslation: 'test Sorani meaning',
);

Future<_AudioHarness> _createHarness({
  required bool resumeOnInterruptionEnd,
  QuranAudioCatalog? playbackCatalog,
}) async {
  final sharedPreferences = await SharedPreferences.getInstance();
  final preferences = QuranAudioPreferencesRepository(sharedPreferences);
  final engine = _FakeQuranAudioEngine();
  final session = _FakeQuranAudioSession();
  final handler = QuranAudioHandler(
    engine: engine,
    session: session,
    preferences: preferences,
    initialPreferences: preferences.load(),
    artworkUri: Uri.file('C:\\audio-art.png'),
    resumeOnInterruptionEnd: resumeOnInterruptionEnd,
    playbackCatalog: playbackCatalog,
  );
  return _AudioHarness(
    engine: engine,
    session: session,
    preferences: preferences,
    handler: handler,
  );
}

class _FakeQuranAudioCatalog implements QuranAudioCatalog {
  _FakeQuranAudioCatalog(this._surahs);

  final List<Surah> _surahs;
  int getSurahCalls = 0;

  @override
  Future<Surah?> getSurah(int number) async {
    getSurahCalls++;
    for (final surah in _surahs) {
      if (surah.number == number) return surah;
    }
    return null;
  }

  @override
  Future<List<QuranVerse>> getVerses(int surahNumber) async => [
    _tinyVerse(surahNumber, surahNumber),
  ];
}

class _GatedQuranAudioCatalog implements QuranAudioCatalog {
  final Completer<Surah?> nextSurah = Completer<Surah?>();

  @override
  Future<Surah?> getSurah(int number) => nextSurah.future;

  @override
  Future<List<QuranVerse>> getVerses(int surahNumber) async => [
    _tinyVerse(surahNumber, surahNumber),
  ];
}

Future<void> _flushEvents() => Future<void>.delayed(Duration.zero);

class _AudioHarness {
  const _AudioHarness({
    required this.engine,
    required this.session,
    required this.preferences,
    required this.handler,
  });

  final _FakeQuranAudioEngine engine;
  final _FakeQuranAudioSession session;
  final QuranAudioPreferencesRepository preferences;
  final QuranAudioHandler handler;

  Future<void> dispose() async {
    await handler.dispose();
    await session.dispose();
  }
}

class _FakeQuranAudioEngine implements QuranAudioEngine {
  final StreamController<QuranAudioEngineSnapshot> _controller =
      StreamController<QuranAudioEngineSnapshot>.broadcast(sync: true);
  QuranAudioEngineSnapshot _snapshot = const QuranAudioEngineSnapshot();
  List<QuranAudioTrack> tracks = const [];
  LoopMode repeatMode = LoopMode.off;
  double volume = 1;

  @override
  QuranAudioEngineSnapshot get snapshot => _snapshot;

  @override
  Stream<QuranAudioEngineSnapshot> get snapshots => _controller.stream;

  @override
  Future<void> setQueue(
    List<QuranAudioTrack> newTracks, {
    required int initialIndex,
    required Duration initialPosition,
  }) async {
    tracks = List.unmodifiable(newTracks);
    _update(
      playing: false,
      processingState: ProcessingState.ready,
      currentIndex: initialIndex,
      position: initialPosition,
      duration: const Duration(seconds: 12),
    );
  }

  @override
  Future<void> play() async {
    _update(playing: true, processingState: ProcessingState.ready);
  }

  @override
  Future<void> pause() async {
    _update(playing: false);
  }

  @override
  Future<void> seek(Duration position, {int? index}) async {
    _update(position: position, currentIndex: index);
  }

  @override
  Future<void> setRepeatMode(LoopMode mode) async {
    repeatMode = mode;
  }

  @override
  Future<void> setVolume(double value) async {
    volume = value;
  }

  @override
  Future<void> stop() async {
    _snapshot = const QuranAudioEngineSnapshot();
    _controller.add(_snapshot);
  }

  void completeCurrentQueue() {
    _update(
      playing: false,
      processingState: ProcessingState.completed,
      currentIndex: tracks.length - 1,
      position: Duration.zero,
    );
  }

  @override
  Future<void> dispose() => _controller.close();

  void _update({
    bool? playing,
    ProcessingState? processingState,
    int? currentIndex,
    Duration? position,
    Duration? duration,
  }) {
    _snapshot = QuranAudioEngineSnapshot(
      playing: playing ?? _snapshot.playing,
      processingState: processingState ?? _snapshot.processingState,
      currentIndex: currentIndex ?? _snapshot.currentIndex,
      position: position ?? _snapshot.position,
      bufferedPosition: _snapshot.bufferedPosition,
      duration: duration ?? _snapshot.duration,
      error: _snapshot.error,
    );
    _controller.add(_snapshot);
  }
}

class _FakeQuranAudioSession implements QuranAudioSession {
  final StreamController<QuranAudioInterruption> _interruptionController =
      StreamController<QuranAudioInterruption>.broadcast(sync: true);
  final StreamController<void> _noisyController =
      StreamController<void>.broadcast(sync: true);
  bool active = false;

  @override
  Stream<QuranAudioInterruption> get interruptions =>
      _interruptionController.stream;

  @override
  Stream<void> get becomingNoisy => _noisyController.stream;

  @override
  Future<bool> activate() async {
    active = true;
    return true;
  }

  @override
  Future<void> deactivate() async {
    active = false;
  }

  void emit(QuranAudioInterruption event) => _interruptionController.add(event);

  Future<void> dispose() async {
    await _interruptionController.close();
    await _noisyController.close();
  }
}
