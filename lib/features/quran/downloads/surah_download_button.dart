import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../audio/quran_audio_providers.dart';
import '../audio/quran_reciter.dart';
import '../domain/quran_verse.dart';
import '../domain/surah.dart';
import '../presentation/quran_verse_providers.dart';
import 'quran_download_controller.dart';
import 'quran_download_models.dart';
import 'quran_download_providers.dart';

class SurahDownloadButton extends ConsumerWidget {
  const SurahDownloadButton({required this.surah, this.verses, super.key});

  final Surah surah;
  final List<QuranVerse>? verses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(quranDownloadControllerProvider);
    if (!controller.isSupported) return const SizedBox.shrink();

    return StreamBuilder<QuranDownloadState>(
      stream: controller.stateStream,
      initialData: controller.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? controller.state;
        final reciterId = state.selectedReciterId;
        final progress = state.forSurah(reciterId, surah.number);
        final l10n = AppLocalizations.of(context);
        final reciters =
            ref.watch(quranRecitersProvider).asData?.value ??
            const <QuranReciter>[];
        final reciter = reciters
            .where((item) => item.identifier == reciterId)
            .firstOrNull;
        final reciterName = reciter == null
            ? reciterId
            : Localizations.localeOf(context).languageCode == 'en'
            ? reciter.englishName
            : reciter.arabicName;
        final isBusy = progress?.status == QuranDownloadStatus.downloading;
        final statusLabel = switch (progress?.status) {
          QuranDownloadStatus.waiting => l10n.downloadWaiting,
          QuranDownloadStatus.downloading => l10n.downloadDownloading,
          QuranDownloadStatus.paused => l10n.downloadPaused,
          QuranDownloadStatus.completed => l10n.downloadCompleted,
          QuranDownloadStatus.failed => l10n.downloadFailed,
          QuranDownloadStatus.cancelled => l10n.downloadCancelled,
          null => l10n.downloadNotDownloaded,
        };
        final tooltip =
            '${l10n.downloadSurahAction} · $reciterName · $statusLabel';

        return IconButton(
          key: ValueKey('download-surah-${surah.number}'),
          tooltip: tooltip,
          onPressed: isBusy
              ? () => _run(
                  context,
                  () => controller.pauseSurah(reciterId, surah.number),
                )
              : progress?.status == QuranDownloadStatus.waiting
              ? () => _run(
                  context,
                  () => controller.cancelSurah(reciterId, surah.number),
                )
              : progress?.status == QuranDownloadStatus.completed
              ? null
              : () => _startDownload(context, ref, controller, reciterId),
          icon: _DownloadStatusIcon(progress: progress),
        );
      },
    );
  }

  Future<void> _startDownload(
    BuildContext context,
    WidgetRef ref,
    QuranDownloadController controller,
    String reciterId,
  ) async {
    try {
      final reciters = await ref.read(quranRecitersProvider.future);
      final reciter = _findReciter(reciters, reciterId);
      final loadedVerses =
          verses ??
          (await ref.read(quranVersesProvider.future))
              .where((verse) => verse.surahNumber == surah.number)
              .toList(growable: false);
      final current = controller.state.forSurah(reciterId, surah.number);
      if (current?.status == QuranDownloadStatus.failed) {
        await controller.retrySurah(
          surah: surah,
          verses: loadedVerses,
          reciter: reciter,
        );
      } else {
        await controller.resumeSurah(
          surah: surah,
          verses: loadedVerses,
          reciter: reciter,
        );
      }
    } catch (error, stackTrace) {
      if (!context.mounted) return;
      _reportError(context, error, stackTrace);
    }
  }

  static QuranReciter _findReciter(
    List<QuranReciter> reciters,
    String identifier,
  ) {
    for (final reciter in reciters) {
      if (reciter.identifier == identifier) return reciter;
    }
    throw StateError('The selected download reciter is unavailable.');
  }

  static void _run(BuildContext context, Future<void> Function() action) {
    unawaited(
      action().catchError((Object error, StackTrace stackTrace) {
        if (!context.mounted) return;
        _reportError(context, error, stackTrace);
      }),
    );
  }

  static void _reportError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'Quran audio downloads',
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).downloadOperationError),
      ),
    );
  }
}

class _DownloadStatusIcon extends StatelessWidget {
  const _DownloadStatusIcon({required this.progress});

  final QuranSurahDownloadProgress? progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return switch (progress?.status) {
      QuranDownloadStatus.completed => Icon(
        Icons.download_done_rounded,
        color: colors.primary,
      ),
      QuranDownloadStatus.downloading => SizedBox.square(
        dimension: 21,
        child: CircularProgressIndicator(
          value: progress!.progress,
          strokeWidth: 2,
        ),
      ),
      QuranDownloadStatus.waiting => const Icon(Icons.hourglass_top_rounded),
      QuranDownloadStatus.failed => Icon(
        Icons.error_outline_rounded,
        color: colors.error,
      ),
      _ => const Icon(Icons.download_rounded),
    };
  }
}
