import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/preference_update.dart';
import '../../quran/downloads/quran_audio_download_settings.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider);
    final themeMode = ref.watch(themeControllerProvider);
    final fontSize = ref.watch(quranFontSizeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle, key: const ValueKey('settings-title')),
      ),
      body: ListView(
        key: const ValueKey('settings-scroll-view'),
        padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 28),
        children: [
          _SectionHeading(title: l10n.languageSection),
          const SizedBox(height: 10),
          DropdownButtonFormField<Locale>(
            key: const ValueKey('language-selector'),
            initialValue: locale,
            decoration: InputDecoration(labelText: l10n.languageLabel),
            isExpanded: true,
            items: [
              DropdownMenuItem(
                value: const Locale('ckb'),
                child: Text(l10n.languageSorani),
              ),
              DropdownMenuItem(
                value: const Locale('ar'),
                child: Text(l10n.languageArabic),
              ),
              DropdownMenuItem(
                value: const Locale('en'),
                child: Text(l10n.languageEnglish),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                unawaited(
                  runPreferenceUpdate(
                    context,
                    () => ref
                        .read(localeControllerProvider.notifier)
                        .setLocale(value),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 26),
          _SectionHeading(title: l10n.appearanceSection),
          const SizedBox(height: 10),
          _ThemeSelector(
            value: themeMode,
            onChanged: (value) {
              unawaited(
                runPreferenceUpdate(
                  context,
                  () => ref
                      .read(themeControllerProvider.notifier)
                      .setThemeMode(value),
                ),
              );
            },
          ),
          const SizedBox(height: 26),
          _SectionHeading(title: l10n.readingSection),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.quranFontSize,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        l10n.fontSizeValue(fontSize.round().toString()),
                        key: const ValueKey('quran-font-size-value'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Slider(
                    key: const ValueKey('quran-font-size'),
                    value: fontSize,
                    min: 24,
                    max: 44,
                    divisions: 20,
                    label: fontSize.round().toString(),
                    onChanged: (value) {
                      ref
                          .read(quranFontSizeControllerProvider.notifier)
                          .previewFontSize(value);
                    },
                    onChangeEnd: (_) {
                      unawaited(
                        runPreferenceUpdate(
                          context,
                          () => ref
                              .read(quranFontSizeControllerProvider.notifier)
                              .saveFontSize(),
                        ),
                      );
                    },
                  ),
                  Text(
                    l10n.fontPreparationNote,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.62),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (locale.languageCode == 'ckb') ...[
            const SizedBox(height: 18),
            Text(
              l10n.soraniFrameworkLocalizationNote,
              key: const ValueKey('sorani-framework-localization-note'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.62),
              ),
            ),
          ],
          const SizedBox(height: 26),
          const QuranAudioDownloadSettings(),
          const SizedBox(height: 26),
          _SectionHeading(title: l10n.aboutSection),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              key: const ValueKey('data-attribution'),
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(l10n.dataAttributionTitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: l10n.applicationTitle,
                children: [
                  Text(l10n.surahMetadataAttribution),
                  const SizedBox(height: 12),
                  Text(l10n.quranTextAttribution),
                  const SizedBox(height: 12),
                  Text(l10n.soraniDataAttribution),
                  const SizedBox(height: 12),
                  Text(l10n.quranFontAttribution),
                  const SizedBox(height: 12),
                  Text(l10n.downloadSourceAttribution),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SegmentedButton<ThemeMode>(
      key: const ValueKey('theme-selector'),
      segments: [
        ButtonSegment(
          value: ThemeMode.system,
          icon: const Icon(Icons.brightness_auto_outlined),
          label: Text(l10n.themeSystem),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          icon: const Icon(Icons.light_mode_outlined),
          label: Text(l10n.themeLight),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: const Icon(Icons.dark_mode_outlined),
          label: Text(l10n.themeDark),
        ),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
