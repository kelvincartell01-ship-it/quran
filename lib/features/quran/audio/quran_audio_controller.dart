import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../domain/quran_verse.dart';
import '../domain/surah.dart';
import 'quran_reciter.dart';

@immutable
class QuranAudioStatus {
  const QuranAudioStatus({
    required this.isSupported,
    required this.selectedReciterId,
    this.playing = false,
    this.buffering = false,
    this.surahNumber,
    this.verseNumber,
    this.globalVerseNumber,
    this.repeatMode = LoopMode.off,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
  });

  final bool isSupported;
  final String selectedReciterId;
  final bool playing;
  final bool buffering;
  final int? surahNumber;
  final int? verseNumber;
  final int? globalVerseNumber;
  final LoopMode repeatMode;
  final Duration position;
  final Duration duration;
  final String? error;

  QuranAudioStatus copyWith({
    String? selectedReciterId,
    bool? playing,
    bool? buffering,
    int? surahNumber,
    int? verseNumber,
    int? globalVerseNumber,
    LoopMode? repeatMode,
    Duration? position,
    Duration? duration,
    String? error,
    bool clearError = false,
  }) {
    return QuranAudioStatus(
      isSupported: isSupported,
      selectedReciterId: selectedReciterId ?? this.selectedReciterId,
      playing: playing ?? this.playing,
      buffering: buffering ?? this.buffering,
      surahNumber: surahNumber ?? this.surahNumber,
      verseNumber: verseNumber ?? this.verseNumber,
      globalVerseNumber: globalVerseNumber ?? this.globalVerseNumber,
      repeatMode: repeatMode ?? this.repeatMode,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: clearError ? null : error ?? this.error,
    );
  }
}

abstract interface class QuranAudioController {
  QuranAudioStatus get status;
  Stream<QuranAudioStatus> get statusStream;

  Future<void> playSurah({
    required Surah surah,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
  });
  Future<void> playVerse({
    required Surah surah,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
    required int verseNumber,
  });
  Future<void> selectReciter(QuranReciter reciter);
  Future<void> play();
  Future<void> pause();
  Future<void> skipToNext();
  Future<void> skipToPrevious();
  Future<void> seek(Duration position);
  Future<void> cycleRepeatMode();
}

class UnavailableQuranAudioController implements QuranAudioController {
  const UnavailableQuranAudioController();

  static final _unavailable = UnsupportedError(
    'Quran audio playback requires Android or iOS.',
  );

  @override
  QuranAudioStatus get status => const QuranAudioStatus(
    isSupported: false,
    selectedReciterId: 'ar.alafasy',
  );

  @override
  Stream<QuranAudioStatus> get statusStream => const Stream.empty();

  @override
  Future<void> play() => Future.error(_unavailable);

  @override
  Future<void> playSurah({
    required Surah surah,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
  }) => Future.error(_unavailable);

  @override
  Future<void> playVerse({
    required Surah surah,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
    required int verseNumber,
  }) => Future.error(_unavailable);

  @override
  Future<void> pause() => Future.error(_unavailable);

  @override
  Future<void> selectReciter(QuranReciter reciter) =>
      Future.error(_unavailable);

  @override
  Future<void> seek(Duration position) => Future.error(_unavailable);

  @override
  Future<void> skipToNext() => Future.error(_unavailable);

  @override
  Future<void> skipToPrevious() => Future.error(_unavailable);

  @override
  Future<void> cycleRepeatMode() => Future.error(_unavailable);
}
