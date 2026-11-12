import 'package:flutter/material.dart';

import 'app_preferences.dart';

abstract interface class PreferencesRepository {
  Future<AppPreferences> load();

  Future<void> saveLocale(Locale locale);

  Future<void> saveThemeMode(ThemeMode themeMode);

  Future<void> saveQuranFontSize(double size);
}
