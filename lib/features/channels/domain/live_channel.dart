import 'package:flutter/foundation.dart';

enum LiveChannelId { makkah, madinah }

enum LiveChannelStreamType { hls, dash }

enum LiveChannelAvailabilityStatus { unverified }

@immutable
class LiveChannel {
  const LiveChannel({
    required this.id,
    required this.arabicTitle,
    required this.officialBroadcaster,
    required this.officialLivePageUrl,
    required this.availabilityStatus,
    this.supportedStreamType,
    this.streamUrl,
    this.verifiedYouTubeLiveUrl,
  });

  final LiveChannelId id;
  final String arabicTitle;
  final String officialBroadcaster;
  final String officialLivePageUrl;
  final LiveChannelAvailabilityStatus availabilityStatus;
  final LiveChannelStreamType? supportedStreamType;
  final String? streamUrl;
  final String? verifiedYouTubeLiveUrl;

  Uri get officialLivePageUri => Uri.parse(officialLivePageUrl);

  bool get supportsInAppPlayback =>
      streamUrl != null && supportedStreamType != null;
}
