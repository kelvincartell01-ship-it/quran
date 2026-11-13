import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../features/quran/widget/quran_home_widget.dart';
import '../l10n/app_localizations.dart';
import 'localization/locale_controller.dart';
import 'localization/sorani_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

class QuranApp extends ConsumerStatefulWidget {
  const QuranApp({super.key});

  @override
  ConsumerState<QuranApp> createState() => _QuranAppState();
}

class _QuranAppState extends ConsumerState<QuranApp> {
  StreamSubscription<Uri?>? _widgetClickSubscription;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      _widgetClickSubscription = HomeWidget.widgetClicked.listen(
        _handleWidgetUri,
        onError: (Object error, StackTrace stackTrace) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'Quran home widget',
              context: ErrorDescription('while handling a widget tap'),
            ),
          );
        },
      );
      unawaited(_handleInitialWidgetUri());
    }
  }

  Future<void> _handleInitialWidgetUri() async {
    try {
      _handleWidgetUri(await HomeWidget.initiallyLaunchedFromHomeWidget());
    } on PlatformException catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Quran home widget',
          context: ErrorDescription('while reading the initial widget link'),
        ),
      );
    }
  }

  void _handleWidgetUri(Uri? uri) {
    final location = QuranHomeWidgetData.routeLocation(uri);
    if (location == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(appRouterProvider).go(location);
    });
  }

  @override
  void dispose() {
    unawaited(_widgetClickSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeControllerProvider);
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) =>
          AppLocalizations.of(context).applicationTitle,
      debugShowCheckedModeBanner: false,
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
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
