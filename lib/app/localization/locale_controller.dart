import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/presentation/settings_controller.dart';

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    return ref.read(initialAppPreferencesProvider).locale;
  }

  Future<void> setLocale(Locale locale) async {
    await ref.read(preferencesRepositoryProvider).saveLocale(locale);
    state = locale;
  }
}
