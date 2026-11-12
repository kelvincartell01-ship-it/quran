import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/app_preferences.dart';
import '../../../core/preferences/preferences_repository.dart';

final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (ref) => throw StateError('A preferences repository must be provided.'),
);

final initialAppPreferencesProvider = Provider<AppPreferences>(
  (ref) => throw StateError('Initial app preferences must be provided.'),
);

final quranFontSizeControllerProvider =
    NotifierProvider<QuranFontSizeController, double>(
      QuranFontSizeController.new,
    );

class QuranFontSizeController extends Notifier<double> {
  @override
  double build() {
    return ref.read(initialAppPreferencesProvider).quranFontSize;
  }

  void previewFontSize(double size) {
    state = size.clamp(24.0, 44.0);
  }

  Future<void> saveFontSize() async {
    await ref.read(preferencesRepositoryProvider).saveQuranFontSize(state);
  }
}
