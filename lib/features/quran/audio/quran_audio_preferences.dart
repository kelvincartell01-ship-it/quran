import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuranAudioPreferences {
  const QuranAudioPreferences({
    required this.reciterId,
    required this.repeatMode,
    this.lastSurahNumber,
    this.lastVerseNumber,
    this.positionMilliseconds = 0,
  });

  static const defaults = QuranAudioPreferences(
    reciterId: 'ar.alafasy',
    repeatMode: LoopMode.off,
  );

  final String reciterId;
  final LoopMode repeatMode;
  final int? lastSurahNumber;
  final int? lastVerseNumber;
  final int positionMilliseconds;
}

class QuranAudioPreferencesRepository {
  QuranAudioPreferencesRepository(this._preferences);

  static const _reciterKey = 'audio.reciter';
  static const _repeatKey = 'audio.repeat_mode';
  static const _surahKey = 'audio.last_surah';
  static const _verseKey = 'audio.last_verse';
  static const _positionKey = 'audio.last_position_ms';

  final SharedPreferences _preferences;

  QuranAudioPreferences load() {
    final position = _preferences.getInt(_positionKey) ?? 0;
    final surah = _preferences.getInt(_surahKey);
    final verse = _preferences.getInt(_verseKey);
    return QuranAudioPreferences(
      reciterId: _preferences.getString(_reciterKey) ?? 'ar.alafasy',
      repeatMode: switch (_preferences.getString(_repeatKey)) {
        'surah' => LoopMode.all,
        'verse' => LoopMode.one,
        _ => LoopMode.off,
      },
      lastSurahNumber: surah != null && surah >= 1 && surah <= 114
          ? surah
          : null,
      lastVerseNumber: verse != null && verse > 0 ? verse : null,
      positionMilliseconds: position >= 0 ? position : 0,
    );
  }

  Future<void> saveReciter(String identifier) async {
    await _save(_preferences.setString(_reciterKey, identifier));
  }

  Future<void> saveRepeatMode(LoopMode mode) async {
    final value = switch (mode) {
      LoopMode.all => 'surah',
      LoopMode.one => 'verse',
      LoopMode.off => 'off',
    };
    await _save(_preferences.setString(_repeatKey, value));
  }

  Future<void> savePlaybackContext({
    required int surahNumber,
    required int verseNumber,
    required int positionMilliseconds,
  }) async {
    await _save(_preferences.setInt(_surahKey, surahNumber));
    await _save(_preferences.setInt(_verseKey, verseNumber));
    await _save(
      _preferences.setInt(
        _positionKey,
        positionMilliseconds.clamp(0, 1 << 31).toInt(),
      ),
    );
  }

  Future<void> _save(Future<bool> write) async {
    if (!await write) {
      throw StateError('The audio preference could not be saved.');
    }
  }
}
