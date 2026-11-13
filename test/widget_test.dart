import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/app/app.dart';
import 'package:quran/app/localization/sorani_localizations.dart';
import 'package:quran/app/router/app_router.dart';
import 'package:quran/core/preferences/shared_preferences_repository.dart';
import 'package:quran/features/quran/data/surah_metadata_data_source.dart';
import 'package:quran/features/quran/data/quran_text_data_source.dart';
import 'package:quran/features/quran/data/quran_verse_repository.dart';
import 'package:quran/features/quran/data/sorani_translation_data_source.dart';
import 'package:quran/features/quran/data/surah_repository.dart';
import 'package:quran/features/quran/audio/quran_audio_controller.dart';
import 'package:quran/features/quran/audio/quran_audio_providers.dart';
import 'package:quran/features/quran/audio/quran_reciter.dart';
import 'package:quran/features/quran/domain/quran_verse.dart';
import 'package:quran/features/quran/domain/surah.dart';
import 'package:quran/features/quran/presentation/quran_verse_providers.dart';
import 'package:quran/features/quran/presentation/surah_providers.dart';
import 'package:quran/features/quran/widget/quran_home_widget.dart';
import 'package:quran/features/settings/presentation/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

late List<Surah> testSurahs;
late List<QuranVerse> testQuranVerses;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final surahRepository = LocalSurahRepository(
      const AssetSurahMetadataDataSource(),
    );
    testSurahs = await surahRepository.getAllSurahs();
    testQuranVerses = await LocalQuranVerseRepository(
      surahRepository: surahRepository,
      quranTextDataSource: const AssetQuranTextDataSource(),
      soraniTranslationDataSource: const AssetSoraniTranslationDataSource(),
    ).getAllVerses();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Sorani framework fallbacks are explicit and limited to ckb', () async {
    const sorani = Locale('ckb');
    const arabic = Locale('ar');
    const english = Locale('en');

    expect(GlobalMaterialLocalizations.delegate.isSupported(sorani), isFalse);
    expect(GlobalCupertinoLocalizations.delegate.isSupported(sorani), isFalse);
    expect(GlobalMaterialLocalizations.delegate.isSupported(arabic), isTrue);
    expect(GlobalCupertinoLocalizations.delegate.isSupported(english), isTrue);

    const materialFallback = SoraniMaterialLocalizationsDelegate();
    const cupertinoFallback = SoraniCupertinoLocalizationsDelegate();
    const widgetsFallback = SoraniWidgetsLocalizationsDelegate();
    expect(materialFallback.isSupported(sorani), isTrue);
    expect(materialFallback.isSupported(arabic), isFalse);
    expect(cupertinoFallback.isSupported(sorani), isTrue);
    expect(cupertinoFallback.isSupported(english), isFalse);
    expect(
      (await widgetsFallback.load(sorani)).textDirection,
      TextDirection.rtl,
    );
    expect(
      (await materialFallback.load(sorani)).okButtonLabel,
      (await GlobalMaterialLocalizations.delegate.load(arabic)).okButtonLabel,
    );
  });

  testWidgets('starts in Sorani on Quran and navigates to all three tabs', (
    tester,
  ) async {
    await tester.pumpWidget(await createTestApp());
    await pumpUi(tester);

    expect(find.byKey(const ValueKey('surah-row-1')), findsOneWidget);
    expect(find.text('قورئان'), findsWidgets);
    expect(
      Directionality.of(
        tester.element(find.byKey(const ValueKey('screen-title'))),
      ),
      TextDirection.rtl,
    );
    expect(find.byType(NavigationDestination), findsNWidgets(3));

    await tester.tap(find.byKey(const ValueKey('navigation-channels')));
    await pumpUi(tester);
    final makkahTitle = find.byKey(const ValueKey('channel-title-makkah'));
    await tester.scrollUntilVisible(
      makkahTitle,
      200,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('channels-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('پەخشی ڕاستەوخۆی مەککە'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('navigation-settings')));
    await pumpUi(tester);
    expect(find.byKey(const ValueKey('settings-title')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('sorani-framework-localization-note')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('navigation-quran')));
    await pumpUi(tester);
    expect(find.byKey(const ValueKey('surah-row-1')), findsOneWidget);
  });

  testWidgets(
    'search empty state clears and Surah rows open their detail route',
    (tester) async {
      await tester.pumpWidget(await createTestApp());
      await pumpUi(tester);

      final searchField = find.byKey(const ValueKey('surah-search-field'));
      await tester.enterText(searchField, 'no matching surah');
      await pumpUi(tester);
      expect(
        ProviderScope.containerOf(tester.element(searchField))
            .read(surahSearchQueryProvider),
        'no matching surah',
      );
      expect(find.byKey(const ValueKey('surah-empty-state')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('clear-surah-search')));
      await pumpUi(tester);
      expect(find.byKey(const ValueKey('surah-empty-state')), findsNothing);
      expect(find.byKey(const ValueKey('surah-row-2')), findsOneWidget);
      await tester.enterText(searchField, 'Al-Baqara');
      await pumpUi(tester);
      expect(find.byKey(const ValueKey('surah-row-2')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('surah-tap-2')));
      await pumpUi(tester);
      expect(find.text('البقرة'), findsOneWidget);
      expect(find.text('Al-Baqara'), findsOneWidget);
      final arabicVerse = find.byKey(const ValueKey('verse-arabic-8'));
      expect(tester.widget<Text>(arabicVerse).data, 'الٓمٓ');
      expect(find.text('واتای ئایەت'), findsOneWidget);
      final openingBismillah = find.byKey(
        const ValueKey('surah-opening-bismillah'),
      );
      expect(openingBismillah, findsOneWidget);
      expect(
        tester.widget<Text>(openingBismillah).data,
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
      );
      expect(tester.widget<Text>(arabicVerse).style?.fontFamily, 'AmiriQuran');
      expect(Directionality.of(tester.element(arabicVerse)), TextDirection.rtl);
      expect(
        renderedParagraph(tester, arabicVerse).textSize.height,
        greaterThan(0),
      );
      final soraniMeaning = find.byKey(const ValueKey('verse-translation-8'));
      expect(
        tester.widget<Text>(soraniMeaning).data,
        testQuranVerses
            .singleWhere(
              (verse) => verse.surahNumber == 2 && verse.verseNumber == 1,
            )
            .soraniTranslation,
      );
      expect(find.byKey(const ValueKey('verse-row-2-1')), findsOneWidget);
      expect(
        Directionality.of(tester.element(soraniMeaning)),
        TextDirection.rtl,
      );
      expect(
        tester.getRect(soraniMeaning).top,
        greaterThanOrEqualTo(tester.getRect(arabicVerse).bottom),
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('verse-row-2-1')),
          matching: find.byKey(const ValueKey('verse-arabic-8')),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('increase-quran-font-size')));
      await pumpUi(tester);
      await tester.scrollUntilVisible(
        arabicVerse,
        100,
        scrollable: find
            .byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            )
            .first,
      );
      expect(
        tester.widget<Text>(arabicVerse).style?.fontSize,
        closeTo(33, 0.1),
      );
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getDouble('settings.quran_font_size'), 33);

      expect(find.byType(NavigationDestination), findsNWidgets(3));
      await tester.tap(find.byType(BackButton));
      await pumpUi(tester);
      expect(
        tester.widget<TextField>(searchField).controller?.text,
        'Al-Baqara',
      );
      expect(find.byKey(const ValueKey('surah-row-2')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('clear-surah-search')));
      await pumpUi(tester);
      final surahSixty = find.byKey(const ValueKey('surah-row-60'));
      await tester.scrollUntilVisible(
        surahSixty,
        600,
        scrollable: find
            .byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            )
            .first,
      );
      await tester.tap(find.byKey(const ValueKey('surah-tap-60')));
      await pumpUi(tester);
      await tester.tap(find.byType(BackButton));
      await pumpUi(tester);
      expect(surahSixty, findsOneWidget);
    },
  );

  testWidgets('Al-Baqarah scrolls lazily through its final verse', (
    tester,
  ) async {
    await tester.pumpWidget(await createTestApp());
    await pumpUi(tester);
    await tester.tap(find.byKey(const ValueKey('surah-tap-2')));
    await pumpUi(tester);

    expect(find.byKey(const ValueKey('verse-row-2-1')), findsOneWidget);
    final verticalScrollable = find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        )
        .first;
    final markedVerse = find.byKey(const ValueKey('verse-arabic-9'));
    await tester.scrollUntilVisible(
      markedVerse,
      500,
      scrollable: verticalScrollable,
    );
    final markedText = tester.widget<Text>(markedVerse);
    expect(
      markedText.data,
      testQuranVerses
          .singleWhere(
            (verse) => verse.surahNumber == 2 && verse.verseNumber == 2,
          )
          .arabicText,
    );
    expect(markedText.style?.fontFamily, 'AmiriQuran');
    expect(markedText.data, contains('ۛ'));
    expect(markedText.data, contains('ۭ'));
    expect(
      renderedParagraph(tester, markedVerse).textSize.height,
      greaterThan(0),
    );

    final longVerse = find.byKey(const ValueKey('verse-arabic-289'));
    await tester.scrollUntilVisible(
      longVerse,
      1200,
      scrollable: verticalScrollable,
      maxScrolls: 500,
    );
    final longText = tester.widget<Text>(longVerse);
    expect(longText.style?.fontFamily, 'AmiriQuran');
    expect(
      longText.data,
      testQuranVerses
          .singleWhere(
            (verse) => verse.surahNumber == 2 && verse.verseNumber == 282,
          )
          .arabicText,
    );
    expect(
      renderedParagraph(tester, longVerse).textSize.height,
      greaterThan(100),
    );

    final lastVerse = find.byKey(const ValueKey('verse-row-2-286'));
    await tester.scrollUntilVisible(
      lastVerse,
      1200,
      scrollable: verticalScrollable,
      maxScrolls: 500,
    );
    expect(lastVerse, findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('verse-arabic-293'))).data,
      testQuranVerses
          .singleWhere(
            (verse) => verse.surahNumber == 2 && verse.verseNumber == 286,
          )
          .arabicText,
    );
  });

  testWidgets('widget deep link opens and scrolls to the saved Ayah', (
    tester,
  ) async {
    await tester.pumpWidget(await createTestApp());
    await pumpUi(tester);

    final surah = testSurahs.singleWhere((value) => value.number == 2);
    final verse = testQuranVerses.singleWhere(
      (value) => value.surahNumber == 2 && value.verseNumber == 255,
    );
    final widgetData = QuranHomeWidgetData.fromVerse(
      surah: surah,
      verse: verse,
    );
    final router = ProviderScope.containerOf(
      tester.element(find.byType(QuranApp)),
    ).read(appRouterProvider);
    router.go(QuranHomeWidgetData.routeLocation(widgetData.widgetUri)!);
    await tester.pumpAndSettle();

    final targetVerse = find.byKey(const ValueKey('verse-row-2-255'));
    expect(targetVerse, findsOneWidget);
    final targetRect = tester.getRect(targetVerse);
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(targetRect.top, greaterThan(0));
    expect(targetRect.top, lessThan(screenHeight));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('audio-current-verse')),
        matching: find.byKey(
          ValueKey('verse-arabic-${verse.globalVerseNumber}'),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Al-Fatihah keeps Bismillah as its numbered verse', (
    tester,
  ) async {
    await tester.pumpWidget(await createTestApp());
    await pumpUi(tester);
    await tester.tap(find.byKey(const ValueKey('surah-tap-1')));
    await pumpUi(tester);

    final firstVerse = find.byKey(const ValueKey('verse-arabic-1'));
    expect(
      tester.widget<Text>(firstVerse).data,
      testQuranVerses.first.arabicText,
    );
    expect(find.byKey(const ValueKey('surah-opening-bismillah')), findsNothing);
    expect(find.byKey(const ValueKey('verse-translation-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('verse-row-1-1')), findsOneWidget);
  });

  testWidgets('Quran text follows light and dark theme colors', (tester) async {
    await tester.pumpWidget(await createTestApp());
    await pumpUi(tester);
    await tester.tap(find.byKey(const ValueKey('navigation-settings')));
    await pumpUi(tester);
    await tester.tap(find.text('تاریک'));
    await pumpUi(tester);
    await tester.tap(find.byKey(const ValueKey('navigation-quran')));
    await pumpUi(tester);
    await tester.tap(find.byKey(const ValueKey('surah-tap-1')));
    await pumpUi(tester);

    final arabicVerse = find.byKey(const ValueKey('verse-arabic-1'));
    expect(Theme.of(tester.element(arabicVerse)).brightness, Brightness.dark);
    expect(
      tester.widget<Text>(arabicVerse).style?.color,
      Theme.of(tester.element(arabicVerse)).colorScheme.onSurface,
    );

    await tester.tap(find.byKey(const ValueKey('navigation-settings')));
    await pumpUi(tester);
    await tester.tap(find.text('ڕووناک'));
    await pumpUi(tester);
    await tester.tap(find.byKey(const ValueKey('navigation-quran')));
    await pumpUi(tester);

    expect(Theme.of(tester.element(arabicVerse)).brightness, Brightness.light);
    expect(
      tester.widget<Text>(arabicVerse).style?.color,
      Theme.of(tester.element(arabicVerse)).colorScheme.onSurface,
    );
  });

  testWidgets('At-Tawbah does not display an opening Bismillah', (
    tester,
  ) async {
    await tester.pumpWidget(await createTestApp());
    await pumpUi(tester);
    final surahNine = find.byKey(const ValueKey('surah-tap-9'));
    await tester.scrollUntilVisible(
      surahNine,
      300,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.tap(surahNine);
    await pumpUi(tester);

    final firstVerse = testQuranVerses.firstWhere(
      (verse) => verse.surahNumber == 9 && verse.verseNumber == 1,
    );
    final arabicText = find.byKey(
      ValueKey('verse-arabic-${firstVerse.globalVerseNumber}'),
    );
    expect(tester.widget<Text>(arabicText).data, firstVerse.arabicText);
    expect(find.byKey(const ValueKey('surah-opening-bismillah')), findsNothing);
    expect(
      find.byKey(ValueKey('verse-translation-${firstVerse.globalVerseNumber}')),
      findsOneWidget,
    );
  });

  testWidgets('audio status highlights and scrolls to the current verse', (
    tester,
  ) async {
    final audioController = _TestQuranAudioController();
    addTearDown(audioController.dispose);
    await tester.pumpWidget(
      await createTestApp(audioController: audioController),
    );
    await pumpUi(tester);
    await tester.tap(find.byKey(const ValueKey('surah-tap-2')));
    await pumpUi(tester);

    audioController.emit(
      const QuranAudioStatus(
        isSupported: true,
        selectedReciterId: 'ar.alafasy',
        playing: true,
        surahNumber: 2,
        verseNumber: 50,
        globalVerseNumber: 57,
        position: Duration(seconds: 5),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('audio-current-verse')), findsOneWidget);
    expect(find.byKey(const ValueKey('verse-arabic-57')), findsOneWidget);
    final currentVerse = tester.getRect(
      find.byKey(const ValueKey('audio-current-verse')),
    );
    expect(
      currentVerse.top,
      lessThan(tester.view.physicalSize.height / tester.view.devicePixelRatio),
    );
    expect(currentVerse.bottom, greaterThan(0));

    await tester.drag(
      find.byKey(const PageStorageKey<String>('quran-reading-scroll-2')),
      const Offset(0, -1800),
    );
    await tester.pumpAndSettle();
    audioController.emit(
      const QuranAudioStatus(
        isSupported: true,
        selectedReciterId: 'ar.alafasy',
        playing: true,
        surahNumber: 2,
        verseNumber: 50,
        globalVerseNumber: 57,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('audio-current-verse')), findsOneWidget);
    final repeatedVerse = tester.getRect(
      find.byKey(const ValueKey('audio-current-verse')),
    );
    expect(
      repeatedVerse.top,
      lessThan(tester.view.physicalSize.height / tester.view.devicePixelRatio),
    );
  });

  testWidgets('open reader follows automatic Surah playback transitions', (
    tester,
  ) async {
    final audioController = _TestQuranAudioController();
    addTearDown(audioController.dispose);
    await tester.pumpWidget(
      await createTestApp(audioController: audioController),
    );
    await pumpUi(tester);
    await tester.tap(find.byKey(const ValueKey('surah-tap-2')));
    await pumpUi(tester);

    audioController.emit(
      const QuranAudioStatus(
        isSupported: true,
        selectedReciterId: 'ar.alafasy',
        playing: true,
        surahNumber: 3,
        verseNumber: 1,
        globalVerseNumber: 294,
      ),
    );
    await pumpUi(tester);

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('reader-surah-arabic-name')))
          .data,
      testSurahs[2].arabicName,
    );
    expect(find.byKey(const ValueKey('verse-row-3-1')), findsWidgets);
  });

  testWidgets('Settings omits About and preserves other options', (
    tester,
  ) async {
    await tester.pumpWidget(await createTestApp());
    await pumpUi(tester);
    await tester.tap(find.byKey(const ValueKey('navigation-settings')));
    await pumpUi(tester);

    expect(find.text('دەربارە'), findsNothing);
    expect(find.byKey(const ValueKey('language-selector')), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-selector')), findsOneWidget);
    expect(find.byKey(const ValueKey('quran-font-size')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await pumpUi(tester);
  });

  testWidgets(
    'language, theme, and Quran font size update and persist across restart',
    (tester) async {
      await tester.pumpWidget(await createTestApp());
      await pumpUi(tester);

      await tester.tap(find.byKey(const ValueKey('navigation-settings')));
      await pumpUi(tester);

      final themeKey = find.byKey(const ValueKey('theme-selector'));
      expect(tester.widget<SegmentedButton<ThemeMode>>(themeKey).selected, {
        ThemeMode.system,
      });
      expect(
        Theme.of(tester.element(themeKey)).brightness,
        tester.platformDispatcher.platformBrightness,
      );

      await tester.tap(find.text('ڕووناک'));
      await pumpUi(tester);
      expect(tester.widget<SegmentedButton<ThemeMode>>(themeKey).selected, {
        ThemeMode.light,
      });
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.light,
      );
      expect(Theme.of(tester.element(themeKey)).brightness, Brightness.light);
      var preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('settings.theme_mode'), 'light');

      await tester.tap(find.text('سیستەم'));
      await pumpUi(tester);
      expect(tester.widget<SegmentedButton<ThemeMode>>(themeKey).selected, {
        ThemeMode.system,
      });
      expect(
        Theme.of(tester.element(themeKey)).brightness,
        tester.platformDispatcher.platformBrightness,
      );
      preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('settings.theme_mode'), 'system');

      await tester.tap(find.text('تاریک'));
      await pumpUi(tester);
      expect(tester.widget<SegmentedButton<ThemeMode>>(themeKey).selected, {
        ThemeMode.dark,
      });
      expect(Theme.of(tester.element(themeKey)).brightness, Brightness.dark);
      preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('settings.theme_mode'), 'dark');

      await tester.tap(find.byKey(const ValueKey('language-selector')));
      await pumpUi(tester);
      await tester.tap(find.text('ئینگلیزی'));
      await pumpUi(tester);
      var settingsTitle = find.byKey(const ValueKey('settings-title'));
      expect(tester.widget<Text>(settingsTitle).data, 'Settings');
      expect(
        Directionality.of(tester.element(settingsTitle)),
        TextDirection.ltr,
      );
      preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('settings.locale'), 'en');

      await tester.tap(find.byKey(const ValueKey('language-selector')));
      await pumpUi(tester);
      await tester.tap(find.text('Arabic'));
      await pumpUi(tester);
      settingsTitle = find.byKey(const ValueKey('settings-title'));
      expect(tester.widget<Text>(settingsTitle).data, 'الإعدادات');
      expect(
        Directionality.of(tester.element(settingsTitle)),
        TextDirection.rtl,
      );
      preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('settings.locale'), 'ar');

      final fontSizeSlider = find.byKey(const ValueKey('quran-font-size'));
      await tester.ensureVisible(fontSizeSlider);
      await tester.drag(
        fontSizeSlider,
        Offset(-tester.getRect(fontSizeSlider).width, 0),
      );
      await pumpUi(tester);
      expect(tester.widget<Slider>(fontSizeSlider).value, closeTo(44, 0.1));
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('quran-font-size-value')))
            .data,
        '44',
      );
      preferences = await SharedPreferences.getInstance();
      expect(preferences.getDouble('settings.quran_font_size'), 44);

      await tester.pumpWidget(const SizedBox.shrink());
      await pumpUi(tester);
      await tester.pumpWidget(await createTestApp());
      await pumpUi(tester);

      final quranTitle = find.byKey(const ValueKey('screen-title'));
      expect(tester.widget<Text>(quranTitle).data, 'القرآن');
      expect(Theme.of(tester.element(quranTitle)).brightness, Brightness.dark);

      await tester.tap(find.byKey(const ValueKey('navigation-settings')));
      await pumpUi(tester);
      final restoredSlider = find.byKey(const ValueKey('quran-font-size'));
      await tester.ensureVisible(restoredSlider);
      expect(tester.widget<Slider>(restoredSlider).value, closeTo(44, 0.1));
    },
  );
}

RenderParagraph renderedParagraph(WidgetTester tester, Finder textFinder) {
  final richText = find.descendant(
    of: textFinder,
    matching: find.byType(RichText),
  );
  return tester.renderObject<RenderParagraph>(richText);
}

Future<void> pumpUi(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

Future<Widget> createTestApp({QuranAudioController? audioController}) async {
  final preferences = await SharedPreferences.getInstance();
  final repository = SharedPreferencesRepository(preferences);

  return ProviderScope(
    overrides: [
      preferencesRepositoryProvider.overrideWithValue(repository),
      initialAppPreferencesProvider.overrideWithValue(await repository.load()),
      surahsProvider.overrideWithValue(AsyncData(testSurahs)),
      quranVersesProvider.overrideWithValue(AsyncData(testQuranVerses)),
      if (audioController != null)
        quranAudioControllerProvider.overrideWithValue(audioController),
    ],
    child: const QuranApp(),
  );
}

class _TestQuranAudioController implements QuranAudioController {
  final StreamController<QuranAudioStatus> _statusController =
      StreamController<QuranAudioStatus>.broadcast(sync: true);

  @override
  QuranAudioStatus status = const QuranAudioStatus(
    isSupported: true,
    selectedReciterId: 'ar.alafasy',
  );

  @override
  Stream<QuranAudioStatus> get statusStream => _statusController.stream;

  void emit(QuranAudioStatus nextStatus) {
    status = nextStatus;
    _statusController.add(nextStatus);
  }

  @override
  Future<void> cycleRepeatMode() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> playSurah({
    required Surah surah,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
  }) async {}

  @override
  Future<void> playVerse({
    required Surah surah,
    required List<QuranVerse> verses,
    required QuranReciter reciter,
    required int verseNumber,
  }) async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> selectReciter(QuranReciter reciter) async {}

  @override
  Future<void> skipToNext() async {}

  @override
  Future<void> skipToPrevious() async {}

  Future<void> dispose() => _statusController.close();
}
