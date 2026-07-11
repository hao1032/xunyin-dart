import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/formatters/audio_formatters.dart';
import '../../../core/widgets/app_layout.dart';
import '../../series/model.dart';
import '../../bilibili/services/repository.dart';
import '../../library/repository.dart';
import '../../podcast/model.dart';
import '../../search/model.dart';
import '../services/playback_queue.dart';
import '../services/controller.dart';

class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(appAudioPlayerProvider);
    final queue = ref.watch(playbackQueueProvider);
    final episode = queue.current;
    return Scaffold(
      appBar: AppBar(
        title: const Text('正在播放'),
        actions: [
          IconButton(
            tooltip: '播放列表',
            icon: Badge.count(
              count: queue.items.length,
              isLabelVisible: queue.items.isNotEmpty,
              child: const Icon(Icons.queue_music),
            ),
            onPressed: () {
              AppLogger.userAction(
                'open_queue_from_player',
                area: 'player',
                data: {'queueCount': queue.items.length},
              );
              context.push('/queue');
            },
          ),
        ],
      ),
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
                        borderRadius: BorderRadius.circular(24),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: episode.imageUrl == null
                              ? ColoredBox(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.podcasts, size: 72),
                                )
                              : Image.network(
                                  episode.imageUrl!,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        episode.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
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
                                style: IconButton.styleFrom(
                                  minimumSize: const Size.square(68),
                                ),
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
    final subscriptions = await ref
        .read(libraryRepositoryProvider)
        .subscriptions();
    final subscribed = subscriptions.where((series) {
      return series.id == episode.seriesId ||
          series.episodes.any((item) => item.id == episode.id);
    }).firstOrNull;
    if (subscribed != null) return subscribed;

    if (episode.sourceType == SourceType.bilibili && episode.bvid != null) {
      final series = await _resolveBilibiliSeries(ref, episode);
      if (series != null) return series;
    }

    final queuedSeries = queue.items.where((entry) {
      return entry.type == PlaybackQueueEntryType.series &&
          entry.containsEpisode(episode.id);
    }).firstOrNull;
    if (queuedSeries != null) {
      return _seriesFromEpisode(
        id: queuedSeries.id,
        title: queuedSeries.title,
        originalUrl: episode.originalUrl,
        author: episode.author,
        imageUrl: queuedSeries.episodes.first.imageUrl ?? episode.imageUrl,
        episodes: queuedSeries.episodes,
        episode: episode,
      );
    }

    return _seriesFromEpisode(
      id: episode.seriesId,
      title: episode.author ?? episode.sourceType.label,
      originalUrl: episode.originalUrl,
      author: episode.author,
      imageUrl: episode.imageUrl,
      episodes: [episode],
      episode: episode,
    );
  }

  Series _seriesFromEpisode({
    required String id,
    required String title,
    required String originalUrl,
    required String? author,
    required String? imageUrl,
    required List<Episode> episodes,
    required Episode episode,
  }) {
    if (episode.sourceType != SourceType.bilibili) {
      return RssPodcastSeries(
        id: id,
        title: title,
        originalUrl: originalUrl,
        feedUrl: _rssFeedUrl(episode) ?? originalUrl,
        author: author,
        imageUrl: imageUrl,
        episodes: episodes,
      );
    }
    if (episode.seriesId.startsWith('bili-up-')) {
      return BilibiliCreatorSeries(
        id: id,
        title: title,
        originalUrl: originalUrl,
        author: author,
        imageUrl: imageUrl,
        episodes: episodes,
      );
    }
    return BilibiliCollectionSeries(
      id: id,
      title: title,
      originalUrl: originalUrl,
      author: author,
      imageUrl: imageUrl,
      episodes: episodes,
    );
  }

  Future<Series?> _resolveBilibiliSeries(WidgetRef ref, Episode episode) async {
    try {
      final context = await ref
          .read(bilibiliRepositoryProvider)
          .resolveEpisodeContext(
            SearchResult(
              id: episode.id,
              title: episode.title,
              sourceType: episode.sourceType,
              originalUrl: episode.originalUrl,
              imageUrl: episode.imageUrl,
              duration: episode.duration,
              publishedAt: episode.publishedAt,
              bvid: episode.bvid,
            ),
          );
      final collection = context.collectionSeries;
      if (collection != null && collection.id == episode.seriesId) {
        return collection;
      }
      if (episode.seriesId.startsWith('bili-season-') && collection != null) {
        return collection;
      }
      return context.creatorSeries;
    } catch (error, stackTrace) {
      AppLogger.failure(
        'resolve_series_from_player',
        error,
        area: 'player',
        stackTrace: stackTrace,
        data: {'episodeId': episode.id, 'bvid': episode.bvid},
      );
      return null;
    }
  }

  String? _rssFeedUrl(Episode episode) {
    if (episode.sourceType != SourceType.rss) return null;
    if (!episode.seriesId.startsWith('rss-')) return null;
    final feedUrl = episode.seriesId.substring('rss-'.length);
    return feedUrl.isEmpty ? null : feedUrl;
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
        label: Text('播客：$name', maxLines: 1, overflow: TextOverflow.ellipsis),
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
