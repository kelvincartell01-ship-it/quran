import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/presentation/settings_controller.dart';

final themeControllerProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);

class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ref.read(initialAppPreferencesProvider).themeMode;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await ref.read(preferencesRepositoryProvider).saveThemeMode(mode);
    state = mode;
  }
}
