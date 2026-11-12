import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/app/localization/sorani_localizations.dart';
import 'package:quran/app/theme/app_theme.dart';
import 'package:quran/features/channels/data/live_channel_repository.dart';
import 'package:quran/features/channels/domain/live_channel.dart';
import 'package:quran/features/channels/live_channel_providers.dart';
import 'package:quran/features/channels/presentation/channels_screen.dart';
import 'package:quran/features/quran/audio/quran_audio_controller.dart';
import 'package:quran/features/quran/audio/quran_audio_providers.dart';
import 'package:quran/l10n/app_localizations.dart';

void main() {
  const repository = OfficialLiveChannelRepository();

  test('official catalog contains exactly the two requested channels', () {
    final channels = repository.loadChannels();

    expect(channels, hasLength(2));
    expect(channels.map((channel) => channel.id), [
      LiveChannelId.makkah,
      LiveChannelId.madinah,
    ]);
    expect(channels.map((channel) => channel.arabicTitle), [
      'مكة المكرمة',
      'المدينة المنورة',
    ]);
    expect(
      channels.every(
        (channel) =>
            channel.officialBroadcaster ==
                'Saudi Broadcasting Authority (SBA)' &&
            channel.availabilityStatus ==
                LiveChannelAvailabilityStatus.unverified &&
            channel.supportedStreamType == null &&
            channel.streamUrl == null &&
            channel.verifiedYouTubeLiveUrl == null,
      ),
      isTrue,
    );
    expect(
      channels.map((channel) => channel.officialLivePageUri.host),
      everyElement('aloula.sba.sa'),
    );
    expect(channels.map((channel) => channel.officialLivePageUri.path), [
      '/live/quran',
      '/live/sunna',
    ]);
    expect(
      channels.every(
        (channel) =>
            channel.officialLivePageUri.scheme == 'https' &&
            !channel.supportsInAppPlayback,
      ),
      isTrue,
    );
  });

  testWidgets('renders two channels without claiming either is live', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Makkah Live'), findsOneWidget);
    expect(find.text('مكة المكرمة'), findsNWidgets(2));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('channel-title-madinah')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Madinah Live'), findsOneWidget);
    expect(find.text('المدينة المنورة'), findsNWidgets(2));
    expect(find.text('LIVE'), findsNothing);
    expect(find.byType(NavigationDestination), findsNothing);
  });

  testWidgets('pauses Quran audio before opening the official page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final audioController = _FakeQuranAudioController();
    final launcher = _RecordingOfficialPageLauncher(audioController);
    await tester.pumpWidget(
      _app(audioController: audioController, launcher: launcher),
    );
    await tester.pumpAndSettle();

    final openMakkah = find.byKey(const ValueKey('channel-open-makkah'));
    await tester.tap(openMakkah);
    await tester.pumpAndSettle();

    expect(audioController.pauseCalls, 1);
    expect(audioController.status.playing, isFalse);
    expect(audioController.status.surahNumber, 2);
    expect(audioController.status.verseNumber, 19);
    expect(launcher.openedUris, [
      Uri.parse('https://aloula.sba.sa/live/quran'),
    ]);
    expect(launcher.audioWasPlayingAtOpen, isFalse);
  });

  testWidgets('channel text follows Sorani, Arabic, and English direction', (
    tester,
  ) async {
    const cases = [
      (locale: Locale('ckb'), direction: TextDirection.rtl),
      (locale: Locale('ar'), direction: TextDirection.rtl),
      (locale: Locale('en'), direction: TextDirection.ltr),
    ];

    for (final testCase in cases) {
      await tester.pumpWidget(_app(locale: testCase.locale));
      await tester.pumpAndSettle();

      final makkahTitle = find.byKey(const ValueKey('channel-title-makkah'));
      await tester.scrollUntilVisible(
        makkahTitle,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        Directionality.of(tester.element(makkahTitle)),
        testCase.direction,
      );
      final madinahTitle = find.byKey(const ValueKey('channel-title-madinah'));
      await tester.scrollUntilVisible(
        madinahTitle,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(madinahTitle, findsOneWidget);
      expect(
        find.byKey(const ValueKey('channel-open-madinah')),
        findsOneWidget,
      );
    }
  });

  testWidgets('channel cards respect light and dark themes', (tester) async {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      await tester.pumpWidget(_app(theme: theme));
      await tester.pumpAndSettle();

      expect(
        Theme.of(
          tester.element(find.byKey(const ValueKey('channel-card-makkah'))),
        ).brightness,
        theme.brightness,
      );
    }
  });
}

Widget _app({
  Locale locale = const Locale('en'),
  ThemeData? theme,
  _FakeQuranAudioController? audioController,
  _RecordingOfficialPageLauncher? launcher,
}) => ProviderScope(
  overrides: [
    liveChannelRepositoryProvider.overrideWithValue(
      const OfficialLiveChannelRepository(),
    ),
    if (audioController != null)
      quranAudioControllerProvider.overrideWithValue(audioController),
    if (launcher != null)
      officialLivePageLauncherProvider.overrideWithValue(launcher),
  ],
  child: MaterialApp(
    key: ValueKey('channel-test-${locale.toLanguageTag()}'),
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      SoraniMaterialLocalizationsDelegate(),
      SoraniCupertinoLocalizationsDelegate(),
      SoraniWidgetsLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: theme ?? AppTheme.light,
    home: const ChannelsScreen(),
  ),
);

class _FakeQuranAudioController extends UnavailableQuranAudioController {
  _FakeQuranAudioController()
    : _status = const QuranAudioStatus(
        isSupported: true,
        selectedReciterId: 'ar.alafasy',
        playing: true,
        surahNumber: 2,
        verseNumber: 19,
        globalVerseNumber: 38,
      );

  QuranAudioStatus _status;
  int pauseCalls = 0;

  @override
  QuranAudioStatus get status => _status;

  @override
  Future<void> pause() async {
    pauseCalls++;
    _status = _status.copyWith(playing: false);
  }
}

class _RecordingOfficialPageLauncher implements OfficialLivePageLauncher {
  _RecordingOfficialPageLauncher(this.audioController);

  final _FakeQuranAudioController audioController;
  final List<Uri> openedUris = [];
  bool? audioWasPlayingAtOpen;

  @override
  Future<bool> open(Uri uri) async {
    openedUris.add(uri);
    audioWasPlayingAtOpen = audioController.status.playing;
    return true;
  }
}
