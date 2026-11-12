import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';

Future<void> runPreferenceUpdate(
  BuildContext context,
  Future<void> Function() update,
) async {
  try {
    await update();
  } on StateError {
    if (context.mounted) {
      _showPreferenceError(context);
    }
  } on PlatformException {
    if (context.mounted) {
      _showPreferenceError(context);
    }
  }
}

void _showPreferenceError(BuildContext context) {
  if (!context.mounted) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context).preferenceSaveError)),
  );
}
