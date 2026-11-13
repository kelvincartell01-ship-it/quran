import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../app/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/islamic_pattern.dart';
import '../../../shared/widgets/preference_update.dart';
import '../../settings/presentation/settings_controller.dart';
import '../audio/quran_audio_controller.dart';
import '../audio/quran_audio_player.dart';
import '../audio/quran_audio_providers.dart';
import '../domain/quran_verse.dart';
import '../domain/surah.dart';
import '../widget/quran_home_widget.dart';
import 'quran_verse_providers.dart';
import 'surah_providers.dart';

class SurahReaderScreen extends ConsumerWidget {
  const SurahReaderScreen({
    required this.surahNumber,
    this.initialVerseNumber,
    super.key,
  });

  final int surahNumber;
  final int? initialVerseNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(quranAudioStatusProvider, (previous, next) {
      final status = next.asData?.value;
      final router = GoRouter.of(context);
      if (status == null ||
          !status.playing ||
          status.surahNumber == null ||
          status.surahNumber == surahNumber ||
          router.state.uri.path != '/quran/surah/$surahNumber') {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted &&
            router.state.uri.path == '/quran/surah/$surahNumber') {
          router.goNamed(
            'surah-reader',
            pathParameters: {'surahNumber': '${status.surahNumber}'},
          );
        }
      });
    });
    final l10n = AppLocalizations.of(context);
    final surahState = ref.watch(surahByNumberProvider(surahNumber));
    final versesState = ref.watch(quranVersesForSurahProvider(surahNumber));
    final fontSize = ref.watch(quranFontSizeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.quranReaderTitle),
        actions: [
          IconButton(
            key: const ValueKey('decrease-quran-font-size'),
            tooltip: l10n.decreaseQuranFontSize,
            onPressed: fontSize <= 24
                ? null
                : () => _changeFontSize(context, ref, fontSize - 1),
            icon: const Icon(Icons.text_decrease_rounded),
          ),
          IconButton(
            key: const ValueKey('increase-quran-font-size'),
            tooltip: l10n.increaseQuranFontSize,
            onPressed: fontSize >= 44
                ? null
                : () => _changeFontSize(context, ref, fontSize + 1),
            icon: const Icon(Icons.text_increase_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: surahState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(key: ValueKey('reader-loading')),
          ),
          error: (error, stackTrace) => _ReaderError(
            message: l10n.surahLoadError,
            onRetry: () => ref.invalidate(surahsProvider),
          ),
          data: (surah) {
            if (surah == null) {
              return Center(child: Text(l10n.surahNotFound));
            }
            return versesState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  key: ValueKey('reader-loading'),
                ),
              ),
              error: (error, stackTrace) => _ReaderError(
                message: l10n.quranReaderLoadError,
                onRetry: () => ref.invalidate(quranVersesProvider),
              ),
              data: (verses) => _QuranReadingView(
                surah: surah,
                verses: verses,
                arabicFontSize: fontSize,
                initialVerseNumber: initialVerseNumber,
              ),
            );
          },
        ),
      ),
    );
  }

  void _changeFontSize(BuildContext context, WidgetRef ref, double size) {
    unawaited(
      runPreferenceUpdate(context, () async {
        final controller = ref.read(quranFontSizeControllerProvider.notifier);
        controller.previewFontSize(size);
        await controller.saveFontSize();
      }),
    );
  }
}

class _QuranReadingView extends ConsumerStatefulWidget {
  const _QuranReadingView({
    required this.surah,
    required this.verses,
    required this.arabicFontSize,
    required this.initialVerseNumber,
  });

  final Surah surah;
  final List<QuranVerse> verses;
  final double arabicFontSize;
  final int? initialVerseNumber;

  @override
  ConsumerState<_QuranReadingView> createState() => _QuranReadingViewState();
}

class _QuranReadingViewState extends ConsumerState<_QuranReadingView> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  Timer? _widgetUpdateDebounce;
  int? _lastScrolledGlobalVerse;
  int? _lastPositionGlobalVerse;
  int? _lastWidgetGlobalVerse;
  Duration? _lastPosition;
  bool _initialVerseScrollPending = false;
  bool _initialVerseScrollScheduled = false;
  bool _wasPlaying = false;

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(
      _scheduleWidgetLastReadUpdate,
    );
  }

  @override
  void dispose() {
    _widgetUpdateDebounce?.cancel();
    _itemPositionsListener.itemPositions.removeListener(
      _scheduleWidgetLastReadUpdate,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(quranAudioControllerProvider);
    final reciters = ref.watch(quranRecitersProvider).asData?.value;
    final selectedReciter = reciters == null || reciters.isEmpty
        ? null
        : reciters.firstWhere(
            (reciter) =>
                reciter.identifier == controller.status.selectedReciterId,
            orElse: () => reciters.first,
          );

    return StreamBuilder<QuranAudioStatus>(
      stream: controller.statusStream,
      initialData: controller.status,
      builder: (context, snapshot) {
        final audioStatus = snapshot.data ?? controller.status;
        final hasBismillah =
            widget.verses.isNotEmpty &&
            widget.verses.first.surahOpeningBismillah != null;
        final verseStartIndex = 3 + (hasBismillah ? 1 : 0);
        _scheduleInitialVerseScroll(verseStartIndex);
        _syncVerseScroll(audioStatus, controller, verseStartIndex);
        return SelectionArea(
          child: ScrollablePositionedList.builder(
            key: PageStorageKey<String>(
              'quran-reading-scroll-${widget.surah.number}',
            ),
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            itemCount: verseStartIndex + widget.verses.length,
            itemBuilder: (context, itemIndex) {
              if (itemIndex == 0) {
                return _ReaderHeader(surah: widget.surah);
              }
              if (itemIndex == 1) {
                return QuranAudioPlayer(
                  surah: widget.surah,
                  verses: widget.verses,
                );
              }
              if (hasBismillah && itemIndex == 2) {
                return _SurahOpeningBismillah(
                  text: widget.verses.first.surahOpeningBismillah!,
                  fontSize: widget.arabicFontSize,
                );
              }
              if (itemIndex == verseStartIndex - 1) {
                return Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 10, 24, 0),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      AppLocalizations.of(context).verseMeaningLabel,
                      key: const ValueKey('verse-meaning-label'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }

              final verseIndex = itemIndex - verseStartIndex;
              final verse = widget.verses[verseIndex];
              return Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  20,
                  verseIndex == 0 ? 10 : 0,
                  20,
                  verseIndex == widget.verses.length - 1 ? 32 : 0,
                ),
                child: _VerseParagraph(
                  verse: verse,
                  arabicFontSize: widget.arabicFontSize,
                  isLast: verseIndex == widget.verses.length - 1,
                  isCurrent:
                      audioStatus.surahNumber == widget.surah.number &&
                          audioStatus.globalVerseNumber != null
                      ? audioStatus.globalVerseNumber == verse.globalVerseNumber
                      : widget.initialVerseNumber == verse.verseNumber,
                  onPlayVerse: selectedReciter == null
                      ? null
                      : () => unawaited(
                          requestAudioPermissionAndRun(
                            context,
                            ref,
                            () => controller.playVerse(
                              surah: widget.surah,
                              verses: widget.verses,
                              reciter: selectedReciter,
                              verseNumber: verse.verseNumber,
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _scheduleWidgetLastReadUpdate() {
    final visibleVerses =
        _itemPositionsListener.itemPositions.value
            .where(
              (position) =>
                  position.index >= _verseStartIndex &&
                  position.itemLeadingEdge < 1 &&
                  position.itemTrailingEdge > 0,
            )
            .toList()
          ..sort(
            (left, right) =>
                left.itemLeadingEdge.compareTo(right.itemLeadingEdge),
          );
    if (visibleVerses.isEmpty) return;

    final verseIndex = visibleVerses.first.index - _verseStartIndex;
    if (verseIndex < 0 || verseIndex >= widget.verses.length) return;
    final verse = widget.verses[verseIndex];
    if (verse.globalVerseNumber == _lastWidgetGlobalVerse) return;

    _widgetUpdateDebounce?.cancel();
    _widgetUpdateDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted || verse.globalVerseNumber == _lastWidgetGlobalVerse) return;
      _lastWidgetGlobalVerse = verse.globalVerseNumber;
      const QuranHomeWidgetSync().updateLastRead(
        QuranHomeWidgetData.fromVerse(surah: widget.surah, verse: verse),
      );
    });
  }

  int get _verseStartIndex =>
      3 +
      (widget.verses.isNotEmpty &&
              widget.verses.first.surahOpeningBismillah != null
          ? 1
          : 0);

  void _syncVerseScroll(
    QuranAudioStatus status,
    QuranAudioController controller,
    int verseStartIndex,
  ) {
    final wasPlaying = _wasPlaying;
    final previousPosition = _lastPosition;
    final previousPositionGlobalVerse = _lastPositionGlobalVerse;
    _wasPlaying = status.playing;
    _lastPosition = status.position;
    _lastPositionGlobalVerse = status.globalVerseNumber;
    if (status.surahNumber != widget.surah.number ||
        status.globalVerseNumber == null) {
      return;
    }

    final verseIndex = widget.verses.indexWhere(
      (verse) => verse.globalVerseNumber == status.globalVerseNumber,
    );
    if (verseIndex < 0) return;
    if (_initialVerseScrollPending) return;

    final shouldScroll =
        status.globalVerseNumber != _lastScrolledGlobalVerse ||
        (status.playing && !wasPlaying) ||
        (status.playing &&
            previousPositionGlobalVerse == status.globalVerseNumber &&
            previousPosition != null &&
            status.position < previousPosition);
    if (!shouldScroll) return;
    _lastScrolledGlobalVerse = status.globalVerseNumber;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_itemScrollController.isAttached ||
          controller.status.surahNumber != widget.surah.number ||
          controller.status.globalVerseNumber != status.globalVerseNumber) {
        return;
      }
      unawaited(
        _itemScrollController.scrollTo(
          index: verseStartIndex + verseIndex,
          alignment: 0.1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        ),
      );
    });
  }

  void _scheduleInitialVerseScroll(int verseStartIndex) {
    final verseNumber = widget.initialVerseNumber;
    if (_initialVerseScrollScheduled ||
        verseNumber == null ||
        verseNumber < 1 ||
        verseNumber > widget.verses.length) {
      return;
    }

    _initialVerseScrollScheduled = true;
    _initialVerseScrollPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_itemScrollController.isAttached) {
        _initialVerseScrollPending = false;
        return;
      }
      unawaited(
        _itemScrollController
            .scrollTo(
              index: verseStartIndex + verseNumber - 1,
              alignment: 0.1,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            )
            .whenComplete(() => _initialVerseScrollPending = false),
      );
    });
  }
}

class _SurahOpeningBismillah extends StatelessWidget {
  const _SurahOpeningBismillah({required this.text, required this.fontSize});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 18, 24, 4),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Text(
          text,
          key: const ValueKey('surah-opening-bismillah'),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'AmiriQuran',
            fontSize: fontSize,
            height: 2,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _ReaderHeader extends StatelessWidget {
  const _ReaderHeader({required this.surah});

  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: IslamicPatternPainter()),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [AppColors.emeraldLight, AppColors.emeraldDeep],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${l10n.surahNumber(surah.number)} · '
                    '${l10n.verseCount(surah.verseCount)}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    surah.arabicName,
                    key: const ValueKey('reader-surah-arabic-name'),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'AmiriQuran',
                      fontSize: 32,
                      height: 1.8,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    surah.transliteration,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_revelationLabel(l10n, surah.revelationType)}'
                    '  ·  ${l10n.revelationOrderLabel} ${surah.revelationOrder}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.78)),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 16,
                    color: colors.secondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerseParagraph extends StatelessWidget {
  const _VerseParagraph({
    required this.verse,
    required this.arabicFontSize,
    required this.isLast,
    required this.isCurrent,
    required this.onPlayVerse,
  });

  final QuranVerse verse;
  final double arabicFontSize;
  final bool isLast;
  final bool isCurrent;
  final VoidCallback? onPlayVerse;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      key: ValueKey('verse-row-${verse.surahNumber}-${verse.verseNumber}'),
      container: true,
      child: Container(
        key: isCurrent ? const ValueKey('audio-current-verse') : null,
        padding: const EdgeInsetsDirectional.fromSTEB(8, 18, 8, 14),
        decoration: isCurrent
            ? BoxDecoration(
                color: colors.primary.withValues(alpha: 0.06),
                border: Border.all(
                  color: colors.secondary.withValues(alpha: 0.42),
                ),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                verse.arabicText,
                key: ValueKey('verse-arabic-${verse.globalVerseNumber}'),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: arabicFontSize,
                  height: 2,
                  color: colors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                verse.soraniTranslation,
                key: ValueKey('verse-translation-${verse.globalVerseNumber}'),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.85,
                  color: colors.onSurface.withValues(alpha: 0.86),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  key: ValueKey('play-verse-${verse.globalVerseNumber}'),
                  tooltip: AppLocalizations.of(context)
                      .playFromVerse(verse.verseNumber),
                  onPressed: onPlayVerse,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.play_circle_outline_rounded),
                ),
                _VerseNumberOrnament(number: verse.verseNumber),
              ],
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 14),
                child: Divider(
                  height: 1,
                  color: colors.outline.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VerseNumberOrnament extends StatelessWidget {
  const _VerseNumberOrnament({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: AppLocalizations.of(context).verseNumber(number),
      child: SizedBox.square(
        dimension: 34,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 23,
                height: 23,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colors.secondary.withValues(alpha: 0.78),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              number.toString(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderError extends StatelessWidget {
  const _ReaderError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            TextButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}

String _revelationLabel(AppLocalizations l10n, RevelationType type) {
  return switch (type) {
    RevelationType.makki => l10n.makki,
    RevelationType.madani => l10n.madani,
  };
}
