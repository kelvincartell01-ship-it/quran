import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_preferences.dart';
import 'preferences_repository.dart';

class SharedPreferencesRepository implements PreferencesRepository {
  SharedPreferencesRepository(this._preferences);

  static const _localeKey = 'settings.locale';
  static const _themeModeKey = 'settings.theme_mode';
  static const _quranFontSizeKey = 'settings.quran_font_size';

  final SharedPreferences _preferences;

  @override
  Future<AppPreferences> load() async {
    final localeCode = _preferences.getString(_localeKey);
    final themeModeName = _preferences.getString(_themeModeKey);
    final savedFontSize = _preferences.getDouble(_quranFontSizeKey);
    final fontSize = savedFontSize != null && savedFontSize.isFinite
        ? savedFontSize.clamp(24.0, 44.0)
        : 32.0;

    return AppPreferences(
      locale: switch (localeCode) {
        'ar' => const Locale('ar'),
        'en' => const Locale('en'),
        _ => const Locale('ckb'),
      },
      themeMode: switch (themeModeName) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      quranFontSize: fontSize,
    );
  }

  @override
  Future<void> saveLocale(Locale locale) async {
    await _save(_preferences.setString(_localeKey, locale.languageCode));
  }

  @override
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    await _save(_preferences.setString(_themeModeKey, themeMode.name));
  }

  @override
  Future<void> saveQuranFontSize(double size) async {
    await _save(
      _preferences.setDouble(_quranFontSizeKey, size.clamp(24.0, 44.0)),
    );
  }

  Future<void> _save(Future<bool> write) async {
    if (!await write) {
      throw StateError('The preference could not be saved.');
    }
  }
}
