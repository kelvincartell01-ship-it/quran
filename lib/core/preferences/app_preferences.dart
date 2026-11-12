import 'package:flutter/material.dart';

@immutable
class AppPreferences {
  const AppPreferences({
    this.locale = const Locale('ckb'),
    this.themeMode = ThemeMode.system,
    this.quranFontSize = 32,
  });

  final Locale locale;
  final ThemeMode themeMode;
  final double quranFontSize;
}
