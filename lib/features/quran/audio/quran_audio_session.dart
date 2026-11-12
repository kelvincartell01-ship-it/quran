import 'package:audio_session/audio_session.dart';

enum QuranAudioInterruptionKind { pause, duck, unknown }

class QuranAudioInterruption {
  const QuranAudioInterruption({required this.begin, required this.kind});

  final bool begin;
  final QuranAudioInterruptionKind kind;
}

abstract interface class QuranAudioSession {
  Stream<QuranAudioInterruption> get interruptions;
  Stream<void> get becomingNoisy;

  Future<bool> activate();
  Future<void> deactivate();
}

class AudioSessionCoordinator implements QuranAudioSession {
  AudioSessionCoordinator(this._session);

  static Future<AudioSessionCoordinator> create() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    return AudioSessionCoordinator(session);
  }

  final AudioSession _session;

  @override
  Stream<QuranAudioInterruption> get interruptions =>
      _session.interruptionEventStream.map(
        (event) => QuranAudioInterruption(
          begin: event.begin,
          kind: switch (event.type) {
            AudioInterruptionType.pause => QuranAudioInterruptionKind.pause,
            AudioInterruptionType.duck => QuranAudioInterruptionKind.duck,
            AudioInterruptionType.unknown => QuranAudioInterruptionKind.unknown,
          },
        ),
      );

  @override
  Stream<void> get becomingNoisy => _session.becomingNoisyEventStream;

  @override
  Future<bool> activate() => _session.setActive(true);

  @override
  Future<void> deactivate() async {
    await _session.setActive(false);
  }
}
