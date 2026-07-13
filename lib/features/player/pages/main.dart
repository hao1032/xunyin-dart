import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/app_logger.dart';
import '../../../core/display_formatters.dart';
import '../../../core/app_layout.dart';
import '../../../shared/wigets/app_bar.dart';
import '../../../shared/wigets/cached_cover_image.dart';
import '../../episode/model.dart';
import '../../episode/series_resolver.dart';
import '../../series/model.dart';
import '../services/playback_queue.dart';
import '../services/controller.dart';

class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(appPlayerProvider);
    final queue = ref.watch(playbackQueueProvider);
    final episode = queue.current;
    return Scaffold(
      appBar: const AppPageBar(title: '正在播放'),
      body: episode == null
          ? const Center(child: Text('还没有正在播放的内容'))
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                AppContent(
                  maxWidth: 520,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: CachedCoverImage(
                            url: episode.imageUrl,
                            placeholderBuilder: (context) => ColoredBox(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.podcasts, size: 72),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        episode.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      _PodcastLink(
                        episode: episode,
                        queue: queue,
                        onTap: () => _openSeries(context, ref, episode, queue),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
                          child: _PlayerProgress(player: player),
                        ),
                      ),
                      const SizedBox(height: 20),
                      StreamBuilder<PlayerState>(
                        stream: player.playerStateStream,
                        builder: (context, snapshot) {
                          final playing = snapshot.data?.playing ?? false;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton.filledTonal(
                                tooltip: '后退 15 秒',
                                iconSize: 26,
                                icon: const Icon(Icons.replay_10),
                                onPressed: () => _seekRelative(player, -15),
                              ),
                              const SizedBox(width: 24),
                              IconButton.filled(
                                tooltip: playing ? '暂停' : '播放',
                                iconSize: 38,
                                icon: Icon(
                                  playing ? Icons.pause : Icons.play_arrow,
                                ),
                                onPressed: () {
                                  AppLogger.userAction(
                                    playing
                                        ? 'pause_from_player'
                                        : 'play_from_player',
                                    area: 'player',
                                  );
                                  playing ? player.pause() : player.play();
                                },
                              ),
                              const SizedBox(width: 24),
                              IconButton.filledTonal(
                                tooltip: '前进 15 秒',
                                iconSize: 26,
                                icon: const Icon(Icons.forward_10),
                                onPressed: () => _seekRelative(player, 15),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _seekRelative(AudioPlayer player, int seconds) async {
    final duration = player.duration;
    final target = player.position + Duration(seconds: seconds);
    final lowerBounded = target < Duration.zero ? Duration.zero : target;
    final bounded = duration != null && lowerBounded > duration
        ? duration
        : lowerBounded;
    await player.seek(bounded);
    AppLogger.userAction(
      'seek_from_player',
      area: 'player',
      data: {'seconds': seconds, 'positionMs': bounded.inMilliseconds},
    );
  }

  Future<void> _openSeries(
    BuildContext context,
    WidgetRef ref,
    Episode episode,
    PlaybackQueueState queue,
  ) async {
    AppLogger.userAction(
      'open_series_from_player',
      area: 'player',
      data: {'episodeId': episode.id, 'seriesId': episode.seriesId},
    );
    final series = await _seriesForEpisode(ref, episode, queue);
    if (!context.mounted) return;
    context.push('/series', extra: series);
  }

  Future<Series> _seriesForEpisode(
    WidgetRef ref,
    Episode episode,
    PlaybackQueueState queue,
  ) async {
    return ref
        .read(episodeSeriesResolverProvider)
        .resolve(
          episode,
          queuedSeries: queue.items
              .where((entry) => entry.type == PlaybackQueueEntryType.series)
              .map(
                (entry) => EpisodeSeriesCandidate(
                  id: entry.id,
                  title: entry.title,
                  episodes: entry.episodes,
                ),
              ),
        );
  }
}

class _PodcastLink extends StatelessWidget {
  const _PodcastLink({
    required this.episode,
    required this.queue,
    required this.onTap,
  });

  final Episode episode;
  final PlaybackQueueState queue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = _podcastName();
    return Center(
      child: TextButton.icon(
        icon: const Icon(Icons.podcasts, size: 18),
        label: Text('播客：$name'),
        onPressed: onTap,
      ),
    );
  }

  String _podcastName() {
    final queuedSeries = queue.items.where((entry) {
      return entry.type == PlaybackQueueEntryType.series &&
          entry.containsEpisode(episode.id);
    }).firstOrNull;
    return queuedSeries?.title ?? episode.author ?? episode.sourceType.label;
  }
}

class _PlayerProgress extends StatelessWidget {
  const _PlayerProgress({required this.player});

  final AudioPlayer player;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration?>(
          stream: player.durationStream,
          builder: (context, durationSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final duration = durationSnapshot.data;
            final maxMs = duration?.inMilliseconds ?? 0;
            final positionMs = position.inMilliseconds.clamp(0, maxMs);
            return Column(
              children: [
                Slider(
                  min: 0,
                  max: maxMs <= 0 ? 1 : maxMs.toDouble(),
                  value: maxMs <= 0 ? 0 : positionMs.toDouble(),
                  onChanged: maxMs <= 0
                      ? null
                      : (value) {
                          player.seek(Duration(milliseconds: value.round()));
                        },
                  onChangeEnd: maxMs <= 0
                      ? null
                      : (value) {
                          AppLogger.userAction(
                            'seek_from_player',
                            area: 'player',
                            data: {
                              'positionMs': value.round(),
                              'durationMs': maxMs,
                            },
                          );
                        },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatDuration(position),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      duration == null ? '--:--' : formatDuration(duration),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
