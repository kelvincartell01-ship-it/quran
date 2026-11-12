import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'quran_audio_controller.dart';
import 'quran_audio_permission.dart';
import 'quran_reciter.dart';
import 'quran_reciter_data_source.dart';

final quranAudioControllerProvider = Provider<QuranAudioController>(
  (ref) => const UnavailableQuranAudioController(),
);

final quranAudioStatusProvider = StreamProvider<QuranAudioStatus>(
  (ref) => ref.watch(quranAudioControllerProvider).statusStream,
);

final quranReciterDataSourceProvider = Provider<AssetQuranReciterDataSource>(
  (ref) => const AssetQuranReciterDataSource(),
);

final audioNotificationPermissionRequesterProvider =
    Provider<AudioNotificationPermissionRequester>(
      (ref) => const PlatformAudioNotificationPermissionRequester(),
    );

final quranRecitersProvider = FutureProvider<List<QuranReciter>>(
  (ref) => ref.watch(quranReciterDataSourceProvider).loadReciters(),
);
