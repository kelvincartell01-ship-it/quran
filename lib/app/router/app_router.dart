import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/channels/presentation/channels_screen.dart';
import '../../features/quran/presentation/quran_screen.dart';
import '../../features/quran/presentation/surah_reader_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../shared/widgets/app_navigation_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/quran',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppNavigationShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/quran',
                builder: (context, state) => const QuranScreen(),
                routes: [
                  GoRoute(
                    path: 'surah/:surahNumber',
                    name: 'surah-reader',
                    builder: (context, state) => SurahReaderScreen(
                      surahNumber:
                          int.tryParse(
                            state.pathParameters['surahNumber'] ?? '',
                          ) ??
                          0,
                      initialVerseNumber: int.tryParse(
                        state.uri.queryParameters['ayah'] ?? '',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/channels',
                builder: (context, state) => const ChannelsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
