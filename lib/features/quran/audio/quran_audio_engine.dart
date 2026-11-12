import 'dart:async';

import 'package:just_audio/just_audio.dart' as ja;

import 'quran_audio_queue.dart';

class QuranAudioEngineSnapshot {
  const QuranAudioEngineSnapshot({
    this.playing = false,
    this.processingState = ja.ProcessingState.idle,
    this.currentIndex,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.duration,
    this.error,
  });

  final bool playing;
  final ja.ProcessingState processingState;
  final int? currentIndex;
  final Duration position;
  final Duration bufferedPosition;
  final Duration? duration;
  final String? error;
}

abstract interface class QuranAudioEngine {
  QuranAudioEngineSnapshot get snapshot;
  Stream<QuranAudioEngineSnapshot> get snapshots;

  Future<void> setQueue(
    List<QuranAudioTrack> tracks, {
    required int initialIndex,
    required Duration initialPosition,
  });
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position, {int? index});
  Future<void> setRepeatMode(ja.LoopMode mode);
  Future<void> setVolume(double volume);
  Future<void> stop();
  Future<void> dispose();
}

class JustAudioQuranAudioEngine implements QuranAudioEngine {
  JustAudioQuranAudioEngine()
    : _player = ja.AudioPlayer(handleInterruptions: false) {
    _subscriptions.addAll([
      _player.playerStateStream.listen((_) => _publish()),
      _player.positionStream.listen((_) => _publish()),
      _player.bufferedPositionStream.listen((_) => _publish()),
      _player.currentIndexStream.listen((_) => _publish()),
      _player.durationStream.listen((_) => _publish()),
      _player.errorStream.listen((error) {
        _error = error.toString();
        _publish();
      }),
    ]);
  }

  final ja.AudioPlayer _player;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final StreamController<QuranAudioEngineSnapshot> _snapshots =
      StreamController<QuranAudioEngineSnapshot>.broadcast();
  String? _error;

  @override
  QuranAudioEngineSnapshot get snapshot => QuranAudioEngineSnapshot(
    playing: _player.playing,
    processingState: _player.processingState,
    currentIndex: _player.currentIndex,
    position: _player.position,
    bufferedPosition: _player.bufferedPosition,
    duration: _player.duration,
    error: _error,
  );

  @override
  Stream<QuranAudioEngineSnapshot> get snapshots => _snapshots.stream;

  @override
  Future<void> setQueue(
    List<QuranAudioTrack> tracks, {
    required int initialIndex,
    required Duration initialPosition,
  }) async {
    _error = null;
    await _player.setAudioSources(
      tracks
          .map((track) => ja.AudioSource.uri(track.uri, tag: track.mediaItem))
          .toList(growable: false),
      initialIndex: initialIndex,
      initialPosition: initialPosition,
      preload: false,
    );
    _publish();
  }

  @override
  Future<void> play() async {
    unawaited(
      _player.play().catchError((Object error, StackTrace stackTrace) {
        _error = error.toString();
        _publish();
      }),
    );
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position, {int? index}) =>
      _player.seek(position, index: index);

  @override
  Future<void> setRepeatMode(ja.LoopMode mode) => _player.setLoopMode(mode);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _snapshots.close();
    await _player.dispose();
  }

  void _publish() {
    if (!_snapshots.isClosed) {
      _snapshots.add(snapshot);
    }
  }
}
