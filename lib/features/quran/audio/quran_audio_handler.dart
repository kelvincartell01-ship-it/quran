import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../domain/quran_verse.dart';
import '../domain/surah.dart';
import 'quran_audio_controller.dart';
import 'quran_audio_catalog.dart';
import 'quran_audio_engine.dart';
import 'quran_audio_preferences.dart';
import 'quran_audio_queue.dart';
import 'quran_audio_session.dart';
import 'quran_audio_source_resolver.dart';
import 'quran_reciter.dart';

class QuranAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler
    implements QuranAudioController {
  QuranAudioHandler({
    required QuranAudioEngine engine,
    required QuranAudioSession session,
    required QuranAudioPreferencesRepository preferences,
    required QuranAudioPreferences initialPreferences,
    required Uri artworkUri,
    required bool resumeOnInterruptionEnd,
    QuranAudioCatalog? playbackCatalog,
    QuranAudioSourceResolver sourceResolver =
        const RemoteQuranAudioSourceResolver(),
  }) : // Keep constructor parameters public while the injected fields remain private.
       // ignore: prefer_initializing_formals
       _engine = engine,
       // ignore: prefer_initializing_formals
       _session = session,
       // ignore: prefer_initializing_formals
       _preferences = preferences,
       // ignore: prefer_initializing_formals
       _artworkUri = artworkUri,
       // ignore: prefer_initializing_formals
       _sourceResolver = sourceResolver,
       // ignore: prefer_initializing_formals
       _playbackCatalog = playbackCatalog,
       // ignore: prefer_initializing_formals
       _resumeOnInterruptionEnd = resumeOnInterruptionEnd,
       _selectedReciterId = initialPreferences.reciterId,
       _repeatMode = initialPreferences.repeatMode,
       _status = QuranAudioStatus(
         isSupported: true,
         selectedReciterId: initialPreferences.reciterId,
         repeatMode: initialPreferences.repeatMode,
       ) {
    _subscriptions
      ..add(_engine.snapshots.listen(_publish, onError: _onStreamError))
      ..add(
        _session.interruptions.listen(
          (event) =>
              unawaited(_handleInterruption(event).catchError(_onStreamError)),
          onError: _onStreamError,
        ),
      )
      ..add(
        _session.becomingNoisy.listen(
          (_) => unawaited(pause().catchError(_onStreamError)),
          onError: _onStreamError,
        ),
      );
    _publish(_engine.snapshot);
  }

  final QuranAudioEngine _engine;
  final QuranAudioSession _session;
  final QuranAudioPreferencesRepository _preferences;
  final Uri _artworkUri;
  final QuranAudioSourceResolver _sourceResolver;
  final QuranAudioCatalog? _playbackCatalog;
  final bool _resumeOnInterruptionEnd;
  final QuranAudioQueueBuilder _queueBuilder = const QuranAudioQueueBuilder();
  final StreamController<QuranAudioStatus> _statusController =
      StreamController<QuranAudioStatus>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  List<QuranAudioTrack> _tracks = const [];
  Surah? _currentSurah;
  List<QuranVerse> _currentVerses = const [];
  QuranReciter? _currentReciter;
  String _selectedReciterId;
  ja.LoopMode _repeatMode;
  QuranAudioStatus _status;
  bool _interruptionWasActive = false;
  bool _resumeAfterInterruption = false;
  int? _lastPersistedGlobalVerse;
  int _lastPersistedPositionSeconds = -10;
  int _queueGeneration = 0;
  bool _isAdvancing = false;
  bool _completionHandled = false;

  @override
  QuranAudioStatus get status => _status;

  @override
  Stream<QuranAudioStatus> get statusStream => _statusController.stream;

  @override
  Future<void> playSurah({
    required Surah surah,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
  }) async {
    _cancelPendingAdvance();
    if (_isCurrentQueue(surah, reciter)) {
      await play();
      return;
    }

    await _selectReciterIfChanged(reciter);
    final saved = _preferences.load();
    final shouldResumeSavedPosition =
        saved.lastSurahNumber == surah.number &&
        saved.lastVerseNumber != null &&
        saved.lastVerseNumber! <= surah.verseCount &&
        saved.reciterId == reciter.identifier;
    final startingVerse = shouldResumeSavedPosition
        ? saved.lastVerseNumber!
        : 1;
    final startingPosition = shouldResumeSavedPosition
        ? Duration(milliseconds: saved.positionMilliseconds)
        : Duration.zero;
    await _loadQueue(
      surah: surah,
      verses: verses,
      reciter: reciter,
      startingVerseNumber: startingVerse,
      startingPosition: startingPosition,
    );
    await play();
  }

  @override
  Future<void> playVerse({
    required Surah surah,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
    required int verseNumber,
  }) async {
    _cancelPendingAdvance();
    if (_isCurrentQueue(surah, reciter)) {
      await _engine.seek(Duration.zero, index: verseNumber - 1);
    } else {
      await _selectReciterIfChanged(reciter);
      await _loadQueue(
        surah: surah,
        verses: verses,
        reciter: reciter,
        startingVerseNumber: verseNumber,
        startingPosition: Duration.zero,
      );
    }
    await play();
  }

  @override
  Future<void> selectReciter(QuranReciter reciter) async {
    _cancelPendingAdvance();
    final wasPlaying = _engine.snapshot.playing;
    final currentIndex = _engine.snapshot.currentIndex;
    final position = _engine.snapshot.position;
    await _selectReciterIfChanged(reciter);
    if (_tracks.isEmpty || _currentSurah == null || _currentVerses.isEmpty) {
      return;
    }

    final verseNumber = currentIndex != null && currentIndex < _tracks.length
        ? _trackVerseNumber(_tracks[currentIndex])
        : 1;
    _tracks = await _queueBuilder.buildWithSourceResolver(
      surah: _currentSurah!,
      verses: _currentVerses,
      reciter: reciter,
      artworkUri: _artworkUri,
      sourceResolver: _sourceResolver,
    );
    _currentReciter = reciter;
    queue.add(_tracks.map((track) => track.mediaItem).toList());
    await _engine.setQueue(
      _tracks,
      initialIndex: verseNumber - 1,
      initialPosition: position,
    );
    if (wasPlaying) {
      await play();
    }
  }

  @override
  Future<void> play() async {
    if (_tracks.isEmpty) return;
    final activated = await _session.activate();
    if (!activated) {
      throw StateError('The audio session could not be activated.');
    }
    await _engine.play();
  }

  @override
  Future<void> pause() async {
    _cancelPendingAdvance();
    _resumeAfterInterruption = false;
    await _engine.pause();
    await _session.deactivate();
    await _persistCurrentPosition();
  }

  @override
  Future<void> skipToNext() async {
    final index = _engine.snapshot.currentIndex;
    if (index == null || _tracks.isEmpty) return;
    final nextIndex = index + 1;
    if (nextIndex < _tracks.length) {
      _cancelPendingAdvance();
      await _engine.seek(Duration.zero, index: nextIndex);
    } else if (_repeatMode == ja.LoopMode.all) {
      _cancelPendingAdvance();
      await _engine.seek(Duration.zero, index: 0);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    final snapshot = _engine.snapshot;
    final index = snapshot.currentIndex;
    if (index == null || _tracks.isEmpty) return;
    if (snapshot.position > const Duration(seconds: 3)) {
      _cancelPendingAdvance();
      await _engine.seek(Duration.zero, index: index);
    } else if (index > 0) {
      _cancelPendingAdvance();
      await _engine.seek(Duration.zero, index: index - 1);
    } else if (_repeatMode == ja.LoopMode.all) {
      _cancelPendingAdvance();
      await _engine.seek(Duration.zero, index: _tracks.length - 1);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    _cancelPendingAdvance();
    await _engine.seek(position);
  }

  @override
  Future<void> cycleRepeatMode() async {
    final nextMode = switch (_repeatMode) {
      ja.LoopMode.off => ja.LoopMode.all,
      ja.LoopMode.all => ja.LoopMode.one,
      ja.LoopMode.one => ja.LoopMode.off,
    };
    await _setRepeatMode(nextMode);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await _setRepeatMode(switch (repeatMode) {
      AudioServiceRepeatMode.one => ja.LoopMode.one,
      AudioServiceRepeatMode.all ||
      AudioServiceRepeatMode.group => ja.LoopMode.all,
      AudioServiceRepeatMode.none => ja.LoopMode.off,
    });
  }

  @override
  Future<void> stop() async {
    _cancelPendingAdvance();
    _resumeAfterInterruption = false;
    await _persistCurrentPosition();
    _tracks = const [];
    _currentSurah = null;
    _currentVerses = const [];
    _currentReciter = null;
    _completionHandled = false;
    queue.add(const []);
    mediaItem.add(null);
    await _engine.stop();
    await _session.deactivate();
    _publish(_engine.snapshot);
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _statusController.close();
    await _engine.dispose();
  }

  Future<void> _loadQueue({
    required Surah surah,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
    required int startingVerseNumber,
    required Duration startingPosition,
  }) async {
    _queueGeneration++;
    _tracks = await _queueBuilder.buildWithSourceResolver(
      surah: surah,
      verses: verses,
      reciter: reciter,
      artworkUri: _artworkUri,
      sourceResolver: _sourceResolver,
      startingVerseNumber: startingVerseNumber,
    );
    _currentSurah = surah;
    _currentVerses = List.unmodifiable(verses);
    _currentReciter = reciter;
    _completionHandled = false;
    queue.add(_tracks.map((track) => track.mediaItem).toList());
    await _engine.setQueue(
      _tracks,
      initialIndex: startingVerseNumber - 1,
      initialPosition: startingPosition,
    );
    _lastPersistedGlobalVerse = null;
    _publish(_engine.snapshot);
  }

  Future<void> _selectReciterIfChanged(QuranReciter reciter) async {
    if (_selectedReciterId == reciter.identifier) return;
    await _preferences.saveReciter(reciter.identifier);
    _selectedReciterId = reciter.identifier;
    _status = _status.copyWith(selectedReciterId: reciter.identifier);
    _emitStatus();
  }

  Future<void> _setRepeatMode(ja.LoopMode mode) async {
    await _engine.setRepeatMode(mode);
    _repeatMode = mode;
    _publish(_engine.snapshot);
    await _preferences.saveRepeatMode(mode);
  }

  bool _isCurrentQueue(Surah surah, QuranReciter reciter) =>
      _tracks.isNotEmpty &&
      _currentSurah?.number == surah.number &&
      _selectedReciterId == reciter.identifier;

  int _trackVerseNumber(QuranAudioTrack track) =>
      track.mediaItem.extras?['verseNumber'] as int;

  Future<void> _handleInterruption(QuranAudioInterruption event) async {
    if (event.kind == QuranAudioInterruptionKind.duck) {
      await _engine.setVolume(event.begin ? 0.2 : 1);
      return;
    }

    if (event.begin) {
      _interruptionWasActive = _engine.snapshot.playing;
      _resumeAfterInterruption =
          _interruptionWasActive &&
          event.kind == QuranAudioInterruptionKind.pause;
      if (_interruptionWasActive) {
        await _engine.pause();
        await _session.deactivate();
      }
      return;
    }

    final shouldResume =
        _interruptionWasActive &&
        _resumeAfterInterruption &&
        _resumeOnInterruptionEnd &&
        event.kind == QuranAudioInterruptionKind.pause;
    _interruptionWasActive = false;
    _resumeAfterInterruption = false;
    if (shouldResume) {
      await play();
    }
  }

  void _publish(QuranAudioEngineSnapshot snapshot) {
    _advanceAfterCompletion(snapshot);
    final index = snapshot.currentIndex;
    final track = index != null && index >= 0 && index < _tracks.length
        ? _tracks[index]
        : null;
    if (track != null) {
      mediaItem.add(track.mediaItem);
    }

    final extras = track?.mediaItem.extras;
    _status = QuranAudioStatus(
      isSupported: true,
      selectedReciterId: _selectedReciterId,
      playing: snapshot.playing,
      buffering:
          snapshot.processingState == ja.ProcessingState.loading ||
          snapshot.processingState == ja.ProcessingState.buffering,
      surahNumber: extras?['surahNumber'] as int?,
      verseNumber: extras?['verseNumber'] as int?,
      globalVerseNumber: extras?['globalVerseNumber'] as int?,
      repeatMode: _repeatMode,
      position: snapshot.position,
      duration: snapshot.duration ?? Duration.zero,
      error: snapshot.error,
    );
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          snapshot.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: switch (snapshot.processingState) {
          ja.ProcessingState.idle => AudioProcessingState.idle,
          ja.ProcessingState.loading => AudioProcessingState.loading,
          ja.ProcessingState.buffering => AudioProcessingState.buffering,
          ja.ProcessingState.ready => AudioProcessingState.ready,
          ja.ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: snapshot.playing,
        updatePosition: snapshot.position,
        bufferedPosition: snapshot.bufferedPosition,
        speed: 1,
        queueIndex: index,
        repeatMode: switch (_repeatMode) {
          ja.LoopMode.off => AudioServiceRepeatMode.none,
          ja.LoopMode.all => AudioServiceRepeatMode.all,
          ja.LoopMode.one => AudioServiceRepeatMode.one,
        },
        errorCode: snapshot.error == null ? 0 : 1,
        errorMessage: snapshot.error,
      ),
    );
    _emitStatus();
    _persistIfNeeded(snapshot, track);
  }

  void _advanceAfterCompletion(QuranAudioEngineSnapshot snapshot) {
    if (snapshot.processingState != ja.ProcessingState.completed) {
      _completionHandled = false;
      return;
    }
    if (_completionHandled ||
        _isAdvancing ||
        _repeatMode != ja.LoopMode.off ||
        snapshot.currentIndex != _tracks.length - 1 ||
        _tracks.isEmpty ||
        _currentSurah == null) {
      return;
    }

    _completionHandled = true;
    _isAdvancing = true;
    final generation = _queueGeneration;
    unawaited(
      _loadNextSurah(generation)
          .catchError((Object error, StackTrace stackTrace) {
            if (generation == _queueGeneration) {
              _isAdvancing = false;
              _onStreamError(error, stackTrace);
            }
          }),
    );
  }

  Future<void> _loadNextSurah(int generation) async {
    final currentSurah = _currentSurah!;
    if (currentSurah.number == 114) {
      if (generation == _queueGeneration) await stop();
      return;
    }

    final catalog = _playbackCatalog;
    final reciter = _currentReciter;
    if (catalog == null || reciter == null) {
      throw StateError('Automatic Surah playback is not configured.');
    }

    final nextSurah = await catalog.getSurah(currentSurah.number + 1);
    if (generation != _queueGeneration || !_isAdvancing) return;
    if (nextSurah == null) {
      throw StateError(
        'The local Quran catalog is missing Surah ${currentSurah.number + 1}.',
      );
    }

    final verses = await catalog.getVerses(nextSurah.number);
    if (generation != _queueGeneration || !_isAdvancing) return;
    await _loadQueue(
      surah: nextSurah,
      verses: verses,
      reciter: reciter,
      startingVerseNumber: 1,
      startingPosition: Duration.zero,
    );
    if (generation + 1 != _queueGeneration || !_isAdvancing) return;
    await play();
    _isAdvancing = false;
  }

  void _cancelPendingAdvance() {
    _queueGeneration++;
    _isAdvancing = false;
  }

  void _persistIfNeeded(
    QuranAudioEngineSnapshot snapshot,
    QuranAudioTrack? track,
  ) {
    if (track == null ||
        _status.surahNumber == null ||
        _status.verseNumber == null) {
      return;
    }
    final globalVerse = _status.globalVerseNumber;
    final positionSeconds = snapshot.position.inSeconds;
    final shouldPersist =
        globalVerse != _lastPersistedGlobalVerse ||
        positionSeconds - _lastPersistedPositionSeconds >= 10 ||
        !snapshot.playing;
    if (!shouldPersist) return;
    _lastPersistedGlobalVerse = globalVerse;
    _lastPersistedPositionSeconds = positionSeconds;
    unawaited(_persistCurrentPosition().catchError(_onStreamError));
  }

  Future<void> _persistCurrentPosition() async {
    final snapshot = _engine.snapshot;
    final index = snapshot.currentIndex;
    if (index == null || index < 0 || index >= _tracks.length) return;
    final track = _tracks[index];
    final surahNumber = track.mediaItem.extras?['surahNumber'] as int?;
    final verseNumber = track.mediaItem.extras?['verseNumber'] as int?;
    if (surahNumber == null || verseNumber == null) return;
    await _preferences.savePlaybackContext(
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      positionMilliseconds: snapshot.position.inMilliseconds,
    );
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    _status = _status.copyWith(error: error.toString());
    _emitStatus();
  }

  void _emitStatus() {
    if (!_statusController.isClosed) {
      _statusController.add(_status);
    }
  }
}
