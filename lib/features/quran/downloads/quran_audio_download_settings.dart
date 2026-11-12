import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../audio/quran_audio_providers.dart';
import '../audio/quran_reciter.dart';
import '../presentation/quran_verse_providers.dart';
import '../presentation/surah_providers.dart';
import 'quran_download_controller.dart';
import 'quran_download_models.dart';
import 'quran_download_providers.dart';

class QuranAudioDownloadSettings extends ConsumerWidget {
  const QuranAudioDownloadSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(quranDownloadControllerProvider);
    if (!controller.isSupported) return const SizedBox.shrink();
    return StreamBuilder<QuranDownloadState>(
      stream: controller.stateStream,
      initialData: controller.state,
      builder: (context, snapshot) => _DownloadSettingsContent(
        controller: controller,
        state: snapshot.data ?? controller.state,
      ),
    );
  }
}

class _DownloadSettingsContent extends ConsumerWidget {
  const _DownloadSettingsContent({
    required this.controller,
    required this.state,
  });

  final QuranDownloadController controller;
  final QuranDownloadState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reciters = ref.watch(quranRecitersProvider).asData?.value ?? const [];
    final selected = _findReciter(reciters, state.selectedReciterId);
    final downloads = state.surahs.values.toList()
      ..sort((left, right) {
        final reciterComparison = left.reciterId.compareTo(right.reciterId);
        return reciterComparison != 0
            ? reciterComparison
            : left.surahNumber.compareTo(right.surahNumber);
      });
    final currentBatch = _currentBatch(state.batches.values);
    final hasActiveJobs = downloads.any(
      (item) =>
          item.status == QuranDownloadStatus.waiting ||
          item.status == QuranDownloadStatus.downloading,
    );
    final hasResumableJobs = downloads.any(
      (item) =>
          item.status == QuranDownloadStatus.paused ||
          item.status == QuranDownloadStatus.cancelled,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(title: l10n.downloadSection),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<QuranReciter>(
                  key: const ValueKey('download-reciter-selector'),
                  initialValue: selected,
                  decoration: InputDecoration(labelText: l10n.downloadReciter),
                  isExpanded: true,
                  items: [
                    for (final reciter in reciters)
                      DropdownMenuItem(
                        value: reciter,
                        child: Text(_reciterName(context, reciter)),
                      ),
                  ],
                  onChanged: reciters.isEmpty
                      ? null
                      : (reciter) {
                          if (reciter != null) {
                            _run(
                              context,
                              () => controller.selectReciter(reciter),
                            );
                          }
                        },
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.downloadStorageUsed(
                    _formatBytes(state.totalStorageBytes),
                  ),
                  key: const ValueKey('download-storage-usage'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  key: const ValueKey('download-all-surahs'),
                  onPressed: selected == null
                      ? null
                      : () => _confirmAndDownloadAll(
                          context,
                          ref,
                          controller,
                          selected,
                        ),
                  icon: const Icon(Icons.library_add_rounded),
                  label: Text(l10n.downloadQuranAction),
                ),
                if (currentBatch != null) ...[
                  const SizedBox(height: 12),
                  _BatchProgress(batch: currentBatch),
                ],
                if (hasActiveJobs || hasResumableJobs) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    children: [
                      if (hasActiveJobs)
                        TextButton(
                          onPressed: () => _run(context, controller.pauseAll),
                          child: Text(l10n.downloadPauseAll),
                        ),
                      if (hasResumableJobs)
                        TextButton(
                          onPressed: () => _resumeAll(context, ref, controller),
                          child: Text(l10n.downloadResumeAll),
                        ),
                      if (hasActiveJobs || hasResumableJobs)
                        TextButton(
                          onPressed: () => _run(context, controller.cancelAll),
                          child: Text(l10n.downloadCancelAll),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                ExpansionTile(
                  key: const ValueKey('downloaded-surahs-section'),
                  tilePadding: EdgeInsets.zero,
                  title: Text(l10n.downloadedSurahs),
                  subtitle: Text(
                    l10n.downloadStorageUsed(
                      _formatBytes(state.totalStorageBytes),
                    ),
                  ),
                  children: [
                    if (downloads.isEmpty)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: 8,
                          end: 8,
                          bottom: 12,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(l10n.downloadNoItems),
                        ),
                      )
                    else
                      for (final item in downloads)
                        _DownloadEntryTile(
                          progress: item,
                          reciter: _findReciter(reciters, item.reciterId),
                          controller: controller,
                        ),
                  ],
                ),
                OutlinedButton.icon(
                  key: const ValueKey('delete-reciter-downloads'),
                  onPressed: selected == null
                      ? null
                      : () => _confirmDeleteReciter(
                          context,
                          controller,
                          selected,
                        ),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: Text(l10n.downloadDeleteReciter),
                ),
                TextButton(
                  key: const ValueKey('clear-all-downloads'),
                  onPressed: downloads.isEmpty
                      ? null
                      : () => _confirmClearAll(context, controller),
                  child: Text(l10n.downloadDeleteAll),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.downloadSourceAttribution,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndDownloadAll(
    BuildContext context,
    WidgetRef ref,
    QuranDownloadController controller,
    QuranReciter reciter,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.downloadAllConfirmationTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.downloadAllConfirmationBody(_reciterName(context, reciter)),
            ),
            const SizedBox(height: 12),
            Text(l10n.downloadSizeUnavailable),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            key: const ValueKey('confirm-download-all-surahs'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.downloadQuranAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _run(context, () async {
      final surahs = await ref.read(surahsProvider.future);
      final verses = await ref.read(quranVersesProvider.future);
      await controller.downloadAll(
        surahs: surahs,
        verses: verses,
        reciter: reciter,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.downloadQueued)));
      }
    });
  }

  Future<void> _resumeAll(
    BuildContext context,
    WidgetRef ref,
    QuranDownloadController controller,
  ) async {
    await _run(context, () async {
      final surahs = await ref.read(surahsProvider.future);
      final verses = await ref.read(quranVersesProvider.future);
      final reciters = await ref.read(quranRecitersProvider.future);
      await controller.resumeAll(
        surahs: surahs,
        verses: verses,
        reciters: reciters,
      );
    });
  }

  Future<void> _confirmDeleteReciter(
    BuildContext context,
    QuranDownloadController controller,
    QuranReciter reciter,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.downloadDeleteReciter),
        content: Text(l10n.downloadDeleteAllConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.downloadDelete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _run(
        context,
        () => controller.deleteReciterDownloads(reciter.identifier),
      );
    }
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    QuranDownloadController controller,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.downloadDeleteAll),
        content: Text(l10n.downloadDeleteAllConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.downloadDelete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _run(context, controller.clearAll);
    }
  }

  static Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error, stackTrace) {
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
}

class _DownloadEntryTile extends ConsumerWidget {
  const _DownloadEntryTile({
    required this.progress,
    required this.reciter,
    required this.controller,
  });

  final QuranSurahDownloadProgress progress;
  final QuranReciter? reciter;
  final QuranDownloadController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final subtitle = StringBuffer(
      l10n.downloadProgress(
        progress.completedVerseCount,
        progress.totalVerseCount,
      ),
    );
    if (reciter != null) {
      subtitle.write(' · ${_reciterName(context, reciter!)}');
    }
    subtitle.write(' · ${downloadStatusLabel(l10n, progress.status)}');
    if (progress.currentTotalBytes case final totalBytes? when totalBytes > 0) {
      subtitle.write(
        ' · ${l10n.downloadCurrentFileProgress(_formatBytes(progress.currentBytes), _formatBytes(totalBytes))}',
      );
    }
    return ListTile(
      dense: true,
      title: Text(l10n.surahNumber(progress.surahNumber)),
      subtitle: Text(subtitle.toString()),
      leading: _StatusIcon(progress: progress),
      trailing: Wrap(
        spacing: 0,
        children: [
          if (progress.status == QuranDownloadStatus.downloading)
            IconButton(
              tooltip: l10n.downloadPause,
              onPressed: () => _run(
                context,
                () => controller.pauseSurah(
                  progress.reciterId,
                  progress.surahNumber,
                ),
              ),
              icon: const Icon(Icons.pause_rounded),
            ),
          if (progress.status == QuranDownloadStatus.waiting)
            IconButton(
              tooltip: l10n.downloadCancel,
              onPressed: () => _run(
                context,
                () => controller.cancelSurah(
                  progress.reciterId,
                  progress.surahNumber,
                ),
              ),
              icon: const Icon(Icons.close_rounded),
            ),
          if ((progress.status == QuranDownloadStatus.paused ||
                  progress.status == QuranDownloadStatus.cancelled) &&
              reciter != null)
            IconButton(
              tooltip: l10n.downloadResume,
              onPressed: () => _loadAndQueue(context, ref, reciter!),
              icon: const Icon(Icons.play_arrow_rounded),
            ),
          if (progress.status == QuranDownloadStatus.failed && reciter != null)
            IconButton(
              tooltip: l10n.downloadRetry,
              onPressed: () => _loadAndQueue(context, ref, reciter!),
              icon: const Icon(Icons.refresh_rounded),
            ),
          IconButton(
            tooltip: l10n.downloadDelete,
            onPressed: () => _run(
              context,
              () => controller.deleteSurah(
                progress.reciterId,
                progress.surahNumber,
              ),
            ),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }

  Future<void> _loadAndQueue(
    BuildContext context,
    WidgetRef ref,
    QuranReciter reciter,
  ) async {
    try {
      final surahs = await ref.read(surahsProvider.future);
      final allVerses = await ref.read(quranVersesProvider.future);
      final surah = surahs.firstWhere(
        (item) => item.number == progress.surahNumber,
      );
      final verses = allVerses
          .where((verse) => verse.surahNumber == surah.number)
          .toList(growable: false);
      if (progress.status == QuranDownloadStatus.failed) {
        await controller.retrySurah(
          surah: surah,
          verses: verses,
          reciter: reciter,
        );
      } else {
        await controller.resumeSurah(
          surah: surah,
          verses: verses,
          reciter: reciter,
        );
      }
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Quran audio downloads',
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).downloadOperationError),
          ),
        );
      }
    }
  }

  static Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error, stackTrace) {
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
}

class _BatchProgress extends StatelessWidget {
  const _BatchProgress({required this.batch});

  final QuranDownloadBatchProgress batch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(value: batch.progress),
        const SizedBox(height: 6),
        Text(
          l10n.downloadBatchProgress(batch.completedSurahs, batch.totalSurahs),
        ),
        if (batch.currentSurahNumber case final surahNumber?)
          Text(
            l10n.downloadCurrentSurah(
              surahNumber,
              batch.currentVerseNumber ?? 1,
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (batch.currentTotalBytes case final totalBytes? when totalBytes > 0)
          Text(
            l10n.downloadCurrentFileProgress(
              _formatBytes(batch.currentBytes),
              _formatBytes(totalBytes),
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (batch.failedSurahs > 0)
          Text(
            l10n.downloadFailed,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}

String downloadStatusLabel(AppLocalizations l10n, QuranDownloadStatus status) =>
    switch (status) {
      QuranDownloadStatus.waiting => l10n.downloadWaiting,
      QuranDownloadStatus.downloading => l10n.downloadDownloading,
      QuranDownloadStatus.paused => l10n.downloadPaused,
      QuranDownloadStatus.completed => l10n.downloadCompleted,
      QuranDownloadStatus.failed => l10n.downloadFailed,
      QuranDownloadStatus.cancelled => l10n.downloadCancelled,
    };

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.progress});

  final QuranSurahDownloadProgress progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return switch (progress.status) {
      QuranDownloadStatus.completed => Icon(
        Icons.download_done_rounded,
        color: colors.primary,
      ),
      QuranDownloadStatus.downloading => SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(
          value: progress.progress,
          strokeWidth: 2,
        ),
      ),
      QuranDownloadStatus.failed => Icon(
        Icons.error_outline_rounded,
        color: colors.error,
      ),
      QuranDownloadStatus.waiting => const Icon(Icons.hourglass_top_rounded),
      _ => const Icon(Icons.download_rounded),
    };
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(context).textTheme.titleMedium
        ?.copyWith(color: Theme.of(context).colorScheme.primary),
  );
}

QuranReciter? _findReciter(List<QuranReciter> reciters, String identifier) {
  for (final reciter in reciters) {
    if (reciter.identifier == identifier) return reciter;
  }
  return null;
}

QuranDownloadBatchProgress? _currentBatch(
  Iterable<QuranDownloadBatchProgress> batches,
) {
  final values = batches.toList();
  if (values.isEmpty) return null;
  return values.last;
}

String _reciterName(BuildContext context, QuranReciter reciter) =>
    Localizations.localeOf(context).languageCode == 'en'
    ? reciter.englishName
    : reciter.arabicName;

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}
