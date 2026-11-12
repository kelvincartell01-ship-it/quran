import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../quran/audio/quran_audio_providers.dart';
import '../domain/live_channel.dart';
import '../live_channel_providers.dart';

class ChannelsScreen extends ConsumerStatefulWidget {
  const ChannelsScreen({super.key});

  @override
  ConsumerState<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends ConsumerState<ChannelsScreen> {
  LiveChannelId? _openingChannel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final channels = ref.watch(liveChannelsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.channelsTitle)),
      body: ListView(
        key: const ValueKey('channels-list'),
        padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 28),
        children: [
          Text(
            l10n.channelsDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          _PlaybackNotice(message: l10n.channelInAppPlaybackUnverified),
          const SizedBox(height: 20),
          for (final channel in channels) ...[
            _ChannelCard(
              channel: channel,
              title: _channelTitle(l10n, channel.id),
              description: _channelDescription(l10n, channel.id),
              broadcasterLabel: l10n.officialBroadcasterLabel,
              pageActionLabel: l10n.openOfficialLivePage,
              openingLabel: l10n.openingOfficialLivePage,
              isOpening: _openingChannel == channel.id,
              onOpen: () => _openOfficialPage(channel),
            ),
            if (channel != channels.last) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Future<void> _openOfficialPage(LiveChannel channel) async {
    if (_openingChannel != null) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _openingChannel = channel.id);

    try {
      final audioController = ref.read(quranAudioControllerProvider);
      if (audioController.status.playing) {
        await audioController.pause();
      }
    } catch (error, stackTrace) {
      _showActionError(error, stackTrace, l10n.channelAudioPauseError);
      if (mounted) setState(() => _openingChannel = null);
      return;
    }

    try {
      final opened = await ref
          .read(officialLivePageLauncherProvider)
          .open(channel.officialLivePageUri);
      if (!opened && mounted) {
        _showMessage(l10n.officialLivePageOpenError);
      }
    } catch (error, stackTrace) {
      _showActionError(error, stackTrace, l10n.officialLivePageOpenError);
    } finally {
      if (mounted) setState(() => _openingChannel = null);
    }
  }

  void _showActionError(Object error, StackTrace stackTrace, String message) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'Quran live channels',
      ),
    );
    _showMessage(message);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PlaybackNotice extends StatelessWidget {
  const _PlaybackNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: colors.secondary),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.channel,
    required this.title,
    required this.description,
    required this.broadcasterLabel,
    required this.pageActionLabel,
    required this.openingLabel,
    required this.isOpening,
    required this.onOpen,
  });

  final LiveChannel channel;
  final String title;
  final String description;
  final String broadcasterLabel;
  final String pageActionLabel;
  final String openingLabel;
  final bool isOpening;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Card(
      key: ValueKey('channel-card-${channel.id.name}'),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChannelArtwork(channel: channel),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  key: ValueKey('channel-title-${channel.id.name}'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  channel.arabicTitle,
                  textDirection: TextDirection.rtl,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: colors.secondary),
                ),
                const SizedBox(height: 8),
                Text(description),
                const SizedBox(height: 12),
                Text(
                  '$broadcasterLabel · ${channel.officialBroadcaster}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.68),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: ValueKey('channel-open-${channel.id.name}'),
                    onPressed: isOpening ? null : onOpen,
                    icon: isOpening
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.open_in_new_rounded),
                    label: Text(isOpening ? openingLabel : pageActionLabel),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.officialLivePageLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.58),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelArtwork extends StatelessWidget {
  const _ChannelArtwork({required this.channel});

  final LiveChannel channel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = switch (channel.id) {
      LiveChannelId.makkah => Icons.mosque_outlined,
      LiveChannelId.madinah => Icons.location_city_outlined,
    };

    return AspectRatio(
      aspectRatio: 2.45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.emerald,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            PositionedDirectional(
              start: -24,
              top: -38,
              child: _ArtworkRing(size: 150, opacity: 0.12),
            ),
            PositionedDirectional(
              end: -34,
              bottom: -72,
              child: _ArtworkRing(size: 190, opacity: 0.1),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 44, color: AppColors.gold),
                const SizedBox(height: 8),
                Text(
                  channel.arabicTitle,
                  textDirection: TextDirection.rtl,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: Colors.white, fontSize: 22),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtworkRing extends StatelessWidget {
  const _ArtworkRing({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold.withValues(alpha: opacity)),
      ),
    ),
  );
}

String _channelTitle(AppLocalizations l10n, LiveChannelId id) => switch (id) {
  LiveChannelId.makkah => l10n.makkahLiveName,
  LiveChannelId.madinah => l10n.madinahLiveName,
};

String _channelDescription(AppLocalizations l10n, LiveChannelId id) =>
    switch (id) {
      LiveChannelId.makkah => l10n.makkahLiveDescription,
      LiveChannelId.madinah => l10n.madinahLiveDescription,
    };
