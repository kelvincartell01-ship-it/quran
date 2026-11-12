import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/quran_verse.dart';
import '../domain/surah.dart';
import 'quran_audio_controller.dart';
import 'quran_audio_providers.dart';
import 'quran_reciter.dart';
import '../downloads/surah_download_button.dart';

class QuranAudioPlayer extends ConsumerWidget {
  const QuranAudioPlayer({
    required this.surah,
    required this.verses,
    super.key,
  });

  final Surah surah;
  final List<QuranVerse> verses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(quranAudioControllerProvider);
    final reciters = ref.watch(quranRecitersProvider);

    return StreamBuilder<QuranAudioStatus>(
      stream: controller.statusStream,
      initialData: controller.status,
      builder: (context, snapshot) {
        final status = snapshot.data ?? controller.status;
        return Card(
          key: const ValueKey('quran-audio-player'),
          margin: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 10),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!status.isSupported)
                  Text(
                    AppLocalizations.of(context).audioPlaybackUnavailable,
                    key: const ValueKey('audio-playback-unavailable'),
                  )
                else
                  reciters.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, stackTrace) =>
                        Text(AppLocalizations.of(context).audioPlaybackError),
                    data: (items) => _PlayerControls(
                      surah: surah,
                      verses: verses,
                      status: status,
                      reciters: items,
                      onCommandError: (error, stackTrace) =>
                          reportAudioCommandError(context, error, stackTrace),
                    ),
                  ),
                Text(
                  AppLocalizations.of(context).audioStreamingAttribution,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlayerControls extends ConsumerStatefulWidget {
  const _PlayerControls({
    required this.surah,
    required this.verses,
    required this.status,
    required this.reciters,
    required this.onCommandError,
  });

  final Surah surah;
  final List<QuranVerse> verses;
  final QuranAudioStatus status;
  final List<QuranReciter> reciters;
  final void Function(Object error, StackTrace stackTrace) onCommandError;

  @override
  ConsumerState<_PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends ConsumerState<_PlayerControls> {
  bool? _expanded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.watch(quranAudioControllerProvider);
    final surah = widget.surah;
    final verses = widget.verses;
    final status = widget.status;
    final reciters = widget.reciters;
    final onCommandError = widget.onCommandError;
    final selectedReciter = reciters.firstWhere(
      (reciter) => reciter.identifier == status.selectedReciterId,
      orElse: () => reciters.first,
    );
    final sameSurah = status.surahNumber == surah.number;
    final expanded = _expanded ?? (status.playing || sameSurah);
    final repeatLabel = switch (status.repeatMode) {
      LoopMode.off => l10n.repeatOff,
      LoopMode.all => l10n.repeatSurah,
      LoopMode.one => l10n.repeatVerse,
    };
    final durationMilliseconds = status.duration.inMilliseconds;
    final progress = durationMilliseconds <= 0
        ? 0.0
        : status.position.inMilliseconds
              .clamp(0, durationMilliseconds)
              .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.audioPlayerTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(
                    height: 36,
                    child: Semantics(
                      label: l10n.selectReciter,
                      child: DropdownButton<QuranReciter>(
                        key: const ValueKey('audio-reciter-selector'),
                        value: selectedReciter,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: [
                          for (final reciter in reciters)
                            DropdownMenuItem(
                              value: reciter,
                              child: Text(
                                Localizations.localeOf(context).languageCode ==
                                        'en'
                                    ? reciter.englishName
                                    : reciter.arabicName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (reciter) {
                          if (reciter != null) {
                            _runCommand(
                              context,
                              () => controller.selectReciter(reciter),
                              onCommandError,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filled(
              key: const ValueKey('audio-play-pause'),
              tooltip: status.playing
                  ? l10n.pauseAudio
                  : (sameSurah ? l10n.resumeAudio : l10n.playSurah),
              onPressed: status.buffering
                  ? null
                  : () {
                      if (status.playing && sameSurah) {
                        _runCommand(context, controller.pause, onCommandError);
                      } else if (sameSurah && status.verseNumber != null) {
                        _requestPermissionAndRun(context, ref, controller.play);
                      } else {
                        _requestPermissionAndRun(
                          context,
                          ref,
                          () => controller.playSurah(
                            surah: surah,
                            verses: verses,
                            reciter: selectedReciter,
                          ),
                        );
                      }
                    },
              icon: Icon(
                status.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
            ),
            SurahDownloadButton(surah: surah, verses: verses),
            IconButton(
              key: const ValueKey('audio-expand-controls'),
              tooltip: expanded
                  ? l10n.hideAudioControls
                  : l10n.showAudioControls,
              onPressed: () => setState(() => _expanded = !expanded),
              icon: Icon(
                expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
              ),
            ),
          ],
        ),
        if (expanded) ...[
          Semantics(
            label: l10n.audioProgressLabel,
            child: Slider(
              key: const ValueKey('audio-progress-slider'),
              value: progress,
              max: durationMilliseconds > 0
                  ? durationMilliseconds.toDouble()
                  : 1,
              onChanged: durationMilliseconds <= 0
                  ? null
                  : (value) => _runCommand(
                      context,
                      () => controller.seek(
                        Duration(milliseconds: value.round()),
                      ),
                      onCommandError,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(status.position)),
                Text(_formatDuration(status.duration)),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                key: const ValueKey('audio-previous-verse'),
                tooltip: l10n.previousVerse,
                onPressed: status.buffering
                    ? null
                    : () => _runCommand(
                        context,
                        controller.skipToPrevious,
                        onCommandError,
                      ),
                icon: const Icon(Icons.skip_previous_rounded),
              ),
              IconButton(
                key: const ValueKey('audio-next-verse'),
                tooltip: l10n.nextVerse,
                onPressed: status.buffering
                    ? null
                    : () => _runCommand(
                        context,
                        controller.skipToNext,
                        onCommandError,
                      ),
                icon: const Icon(Icons.skip_next_rounded),
              ),
              IconButton(
                key: const ValueKey('audio-repeat-mode'),
                tooltip: '${l10n.repeatModeLabel}: $repeatLabel',
                onPressed: () => _runCommand(
                  context,
                  controller.cycleRepeatMode,
                  onCommandError,
                ),
                icon: Icon(
                  status.repeatMode == LoopMode.one
                      ? Icons.repeat_one_rounded
                      : Icons.repeat_rounded,
                  color: status.repeatMode == LoopMode.off
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          if (status.buffering)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 4),
              child: Text(
                l10n.audioLoading,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (status.error != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 4),
              child: Text(
                l10n.offlineAudioNotDownloaded,
                key: const ValueKey('audio-playback-error'),
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ],
    );
  }
}

Future<void> requestAudioPermissionAndRun(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() action,
) async {
  final l10n = AppLocalizations.of(context);
  try {
    final allowed = await ref
        .read(audioNotificationPermissionRequesterProvider)
        .request();
    if (!context.mounted) return;
    if (!allowed) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.audioPermissionDenied)));
      return;
    }
    await action();
  } catch (error, stackTrace) {
    if (!context.mounted) return;
    reportAudioCommandError(context, error, stackTrace);
  }
}

void reportAudioCommandError(
  BuildContext context,
  Object error,
  StackTrace stackTrace,
) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'Quran audio playback',
    ),
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(AppLocalizations.of(context).offlineAudioNotDownloaded),
    ),
  );
}

void _runCommand(
  BuildContext context,
  Future<void> Function() action,
  void Function(Object error, StackTrace stackTrace) onError,
) {
  unawaited(
    action().catchError((Object error, StackTrace stackTrace) {
      onError(error, stackTrace);
    }),
  );
}

void _requestPermissionAndRun(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() action,
) {
  unawaited(requestAudioPermissionAndRun(context, ref, action));
}

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
