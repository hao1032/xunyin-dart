import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/logging/app_logger.dart';
import '../../bilibili/data/bilibili_repository.dart';
import '../../library/data/library_repository.dart';
import '../../podcast/domain/episode.dart';
import '../../podcast/domain/podcast_show.dart';
import '../../podcast/domain/source_type.dart';
import '../../search/domain/search_result.dart';
import '../data/playback_queue.dart';
import '../data/player_controller.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

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
              padding: const EdgeInsets.all(24),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: episode.imageUrl == null
                        ? ColoredBox(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.podcasts, size: 72),
                          )
                        : Image.network(episode.imageUrl!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  episode.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _PodcastLink(
                  episode: episode,
                  queue: queue,
                  onTap: () => _openPodcast(context, ref, episode, queue),
                ),
                const SizedBox(height: 28),
                _PlayerProgress(player: player),
                const SizedBox(height: 12),
                StreamBuilder<PlayerState>(
                  stream: player.playerStateStream,
                  builder: (context, snapshot) {
                    final playing = snapshot.data?.playing ?? false;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filledTonal(
                          tooltip: '后退 15 秒',
                          icon: const Icon(Icons.replay_10),
                          onPressed: () => _seekRelative(player, -15),
                        ),
                        const SizedBox(width: 20),
                        IconButton.filled(
                          tooltip: playing ? '暂停' : '播放',
                          iconSize: 36,
                          icon: Icon(playing ? Icons.pause : Icons.play_arrow),
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
                        const SizedBox(width: 20),
                        IconButton.filledTonal(
                          tooltip: '前进 15 秒',
                          icon: const Icon(Icons.forward_10),
                          onPressed: () => _seekRelative(player, 15),
                        ),
                      ],
                    );
                  },
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

  Future<void> _openPodcast(
    BuildContext context,
    WidgetRef ref,
    Episode episode,
    PlaybackQueueState queue,
  ) async {
    AppLogger.userAction(
      'open_show_from_player',
      area: 'player',
      data: {'episodeId': episode.id, 'showId': episode.showId},
    );
    final show = await _showForEpisode(ref, episode, queue);
    if (!context.mounted) return;
    context.push('/show', extra: show);
  }

  Future<PodcastShow> _showForEpisode(
    WidgetRef ref,
    Episode episode,
    PlaybackQueueState queue,
  ) async {
    final subscriptions = await ref
        .read(libraryRepositoryProvider)
        .subscriptions();
    final subscribed = subscriptions.where((show) {
      return show.id == episode.showId ||
          show.episodes.any((item) => item.id == episode.id);
    }).firstOrNull;
    if (subscribed != null) return subscribed;

    if (episode.sourceType == SourceType.bilibili && episode.bvid != null) {
      final show = await _resolveBilibiliShow(ref, episode);
      if (show != null) return show;
    }

    final queuedShow = queue.items.where((entry) {
      return entry.type == PlaybackQueueEntryType.show &&
          entry.containsEpisode(episode.id);
    }).firstOrNull;
    if (queuedShow != null) {
      return PodcastShow(
        id: queuedShow.id,
        title: queuedShow.title,
        sourceType: episode.sourceType,
        originalUrl: episode.originalUrl,
        author: episode.author,
        imageUrl: queuedShow.episodes.first.imageUrl ?? episode.imageUrl,
        feedUrl: _rssFeedUrl(episode),
        episodes: queuedShow.episodes,
      );
    }

    return PodcastShow(
      id: episode.showId,
      title: episode.author ?? episode.sourceType.label,
      sourceType: episode.sourceType,
      originalUrl: episode.originalUrl,
      author: episode.author,
      imageUrl: episode.imageUrl,
      feedUrl: _rssFeedUrl(episode),
      episodes: [episode],
    );
  }

  Future<PodcastShow?> _resolveBilibiliShow(
    WidgetRef ref,
    Episode episode,
  ) async {
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
      final collection = context.collectionShow;
      if (collection != null && collection.id == episode.showId) {
        return collection;
      }
      if (episode.showId.startsWith('bili-season-') && collection != null) {
        return collection;
      }
      return context.creatorShow;
    } catch (error, stackTrace) {
      AppLogger.failure(
        'resolve_show_from_player',
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
    if (!episode.showId.startsWith('rss-')) return null;
    final feedUrl = episode.showId.substring('rss-'.length);
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
    final queuedShow = queue.items.where((entry) {
      return entry.type == PlaybackQueueEntryType.show &&
          entry.containsEpisode(episode.id);
    }).firstOrNull;
    return queuedShow?.title ?? episode.author ?? episode.sourceType.label;
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
                      _formatDuration(position),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      duration == null ? '--:--' : _formatDuration(duration),
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

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final secondsText = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      final minutesText = minutes.toString().padLeft(2, '0');
      return '$hours:$minutesText:$secondsText';
    }
    return '$minutes:$secondsText';
  }
}
