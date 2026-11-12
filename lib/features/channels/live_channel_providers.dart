import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/live_channel_repository.dart';
import 'domain/live_channel.dart';

final liveChannelRepositoryProvider = Provider<LiveChannelRepository>(
  (ref) => const OfficialLiveChannelRepository(),
);

final liveChannelsProvider = Provider<List<LiveChannel>>(
  (ref) => ref.watch(liveChannelRepositoryProvider).loadChannels(),
);

abstract interface class OfficialLivePageLauncher {
  Future<bool> open(Uri uri);
}

class UrlLauncherOfficialLivePageLauncher implements OfficialLivePageLauncher {
  const UrlLauncherOfficialLivePageLauncher();

  @override
  Future<bool> open(Uri uri) {
    if (uri.scheme != 'https' || uri.host != 'aloula.sba.sa') {
      throw ArgumentError.value(uri, 'uri', 'Only official HTTPS pages open.');
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

final officialLivePageLauncherProvider = Provider<OfficialLivePageLauncher>(
  (ref) => const UrlLauncherOfficialLivePageLauncher(),
);
