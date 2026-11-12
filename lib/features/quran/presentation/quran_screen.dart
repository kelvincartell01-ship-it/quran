import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/surah.dart';
import '../downloads/surah_download_button.dart';
import 'surah_providers.dart';

class QuranScreen extends ConsumerWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final surahs = ref.watch(surahsProvider);
    final searchQuery = ref.watch(surahSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.applicationTitle, key: const ValueKey('screen-title')),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 20),
            child: Icon(Icons.auto_awesome_outlined, color: AppColors.gold),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 20, 12),
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      l10n.surahsHeading,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _SurahSearchField(),
                ],
              ),
            ),
            Expanded(
              child: surahs.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    key: ValueKey('surah-list-loading'),
                  ),
                ),
                error: (error, stackTrace) => _SurahLoadError(
                  onRetry: () => ref.invalidate(surahsProvider),
                ),
                data: (items) {
                  final filteredItems = filterSurahs(items, searchQuery);
                  if (filteredItems.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          l10n.noSurahsFound,
                          key: const ValueKey('surah-empty-state'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    key: const PageStorageKey<String>('surah-list'),
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      0,
                      16,
                      24,
                    ),
                    itemCount: filteredItems.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: 58,
                      color: Theme.of(context).colorScheme.outline
                          .withValues(alpha: 0.45),
                    ),
                    itemBuilder: (context, index) =>
                        _SurahListTile(surah: filteredItems[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahSearchField extends ConsumerStatefulWidget {
  const _SurahSearchField();

  @override
  ConsumerState<_SurahSearchField> createState() => _SurahSearchFieldState();
}

class _SurahSearchFieldState extends ConsumerState<_SurahSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(surahSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return TextField(
      key: const ValueKey('surah-search-field'),
      controller: _controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: l10n.searchSurahs,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _controller.text.trim().isEmpty
            ? null
            : IconButton(
                key: const ValueKey('clear-surah-search'),
                tooltip: l10n.clearSearch,
                onPressed: () {
                  _controller.clear();
                  ref.read(surahSearchQueryProvider.notifier).clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.62),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.55)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 1.4),
        ),
      ),
      onChanged: (value) {
        ref.read(surahSearchQueryProvider.notifier).update(value);
        setState(() {});
      },
    );
  }
}

class _SurahListTile extends StatelessWidget {
  const _SurahListTile({required this.surah});

  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final direction = Directionality.of(context);
    final route = '/quran/surah/${surah.number}';

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              key: ValueKey('surah-row-${surah.number}'),
              button: true,
              label:
                  '${l10n.surahNumber(surah.number)}, ${surah.arabicName}, '
                  '${surah.transliteration}, '
                  '${l10n.verseCount(surah.verseCount)}, '
                  '${_revelationLabel(l10n, surah.revelationType)}',
              onTap: () => context.push(route),
              child: ExcludeSemantics(
                child: InkWell(
                  key: ValueKey('surah-tap-${surah.number}'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.push(route),
                  child: Row(
                    children: [
                      _SurahNumberOrnament(number: surah.number),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              surah.arabicName,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontSize: 19,
                                    color: colors.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              surah.transliteration,
                              textDirection: TextDirection.ltr,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colors.onSurface.withValues(
                                      alpha: 0.68,
                                    ),
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${l10n.verseCount(surah.verseCount)}'
                              '  ·  '
                              '${_revelationLabel(l10n, surah.revelationType)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colors.onSurface.withValues(
                                      alpha: 0.64,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        direction == TextDirection.rtl
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        color: colors.onSurface.withValues(alpha: 0.42),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SurahDownloadButton(surah: surah),
        ],
      ),
    );
  }
}

class _SurahNumberOrnament extends StatelessWidget {
  const _SurahNumberOrnament({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox.square(
      dimension: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                border: Border.all(
                  color: colors.secondary.withValues(alpha: 0.82),
                ),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          Text(
            number.toString().padLeft(3, '0'),
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: colors.primary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SurahLoadError extends StatelessWidget {
  const _SurahLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, color: colors.secondary, size: 32),
            const SizedBox(height: 12),
            Text(
              l10n.surahLoadError,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
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
