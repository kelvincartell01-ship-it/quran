import '../domain/live_channel.dart';

abstract interface class LiveChannelRepository {
  List<LiveChannel> loadChannels();
}

class OfficialLiveChannelRepository implements LiveChannelRepository {
  const OfficialLiveChannelRepository();

  static const _channels = [
    LiveChannel(
      id: LiveChannelId.makkah,
      arabicTitle: 'مكة المكرمة',
      officialBroadcaster: 'Saudi Broadcasting Authority (SBA)',
      officialLivePageUrl: 'https://aloula.sba.sa/live/quran',
      availabilityStatus: LiveChannelAvailabilityStatus.unverified,
    ),
    LiveChannel(
      id: LiveChannelId.madinah,
      arabicTitle: 'المدينة المنورة',
      officialBroadcaster: 'Saudi Broadcasting Authority (SBA)',
      officialLivePageUrl: 'https://aloula.sba.sa/live/sunna',
      availabilityStatus: LiveChannelAvailabilityStatus.unverified,
    ),
  ];

  @override
  List<LiveChannel> loadChannels() => _channels;
}
