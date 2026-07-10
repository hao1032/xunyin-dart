import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/text/plain_text.dart';
import '../../audio/presentation/audio_list_item.dart';
import '../../bilibili/data/bilibili_repository.dart';
import '../../cache/data/audio_cache_repository.dart';
import '../../library/data/library_repository.dart';
import '../../player/data/playback_queue.dart';
import '../../player/data/player_controller.dart';
import '../../player/presentation/mini_player.dart';
import '../data/podcast_repository.dart';
import '../domain/episode.dart';
import '../domain/podcast_show.dart';
import '../domain/source_type.dart';
import 'episode_screen.dart';

class ShowDetailScreen extends ConsumerStatefulWidget {
  const ShowDetailScreen({super.key, required this.show});

  final PodcastShow show;

  @override
  ConsumerState<ShowDetailScreen> createState() => _ShowDetailScreenState();
}

class _ShowDetailScreenState extends ConsumerState<ShowDetailScreen> {
  bool _subscribing = false;
  bool _checkingSubscription = true;
  bool _subscribed = false;
  bool _loadingCreatorVideos = false;
  bool _loadingRssEpisodes = false;
  Object? _creatorVideosError;
  Object? _rssEpisodesError;
  late PodcastShow _show;
  final Set<String> _cachedEpisodeIds = {};
  final Set<String> _busyEpisodeIds = {};

  @override
  void initState() {
    super.initState();
    _show = widget.show;
    _loadSubscriptionState();
    _loadCacheState();
    if (_isBilibiliCreatorShow(widget.show)) {
      _loadCreatorVideos();
    }
    if (_isRssShow(widget.show)) {
      _loadRssEpisodes();
    }
  }

  Future<void> _loadSubscriptionState() async {
    try {
      final subscribed = await ref
          .read(libraryRepositoryProvider)
          .isSubscribed(widget.show.id);
      if (mounted) {
        setState(() {
          _checkingSubscription = false;
          _subscribed = subscribed;
        });
      }
    } catch (error, stackTrace) {
      AppLogger.failure(
        'load_subscription_state',
        error,
        area: 'library',
        stackTrace: stackTrace,
        data: {'showId': widget.show.id},
      );
      if (mounted) {
        setState(() => _checkingSubscription = false);
      }
    }
  }

  Future<void> _loadCacheState() async {
    try {
      final cached = await ref
          .read(audioCacheRepositoryProvider)
          .cachedEpisodes();
      if (mounted) {
        setState(() {
          _cachedEpisodeIds
            ..clear()
            ..addAll(cached.map((item) => item.episode.id));
        });
      }
    } catch (error, stackTrace) {
      AppLogger.failure(
        'load_show_cache_state',
        error,
        area: 'cache',
        stackTrace: stackTrace,
        data: {'showId': widget.show.id},
      );
    }
  }

  Future<void> _loadCreatorVideos() async {
    setState(() {
      _loadingCreatorVideos = true;
      _creatorVideosError = null;
    });
    try {
      final show = await ref
          .read(bilibiliRepositoryProvider)
          .loadCreatorShow(widget.show);
      if (mounted) {
        setState(() {
          _show = show;
          _loadingCreatorVideos = false;
        });
      }
    } catch (error, stackTrace) {
      AppLogger.failure(
        'load_creator_videos',
        error,
        area: 'bilibili',
        stackTrace: stackTrace,
        data: {'showId': widget.show.id, 'title': widget.show.title},
      );
      if (mounted) {
        setState(() {
          _loadingCreatorVideos = false;
          _creatorVideosError = error;
        });
      }
    }
  }

  Future<void> _loadRssEpisodes() async {
    final feedUrl = widget.show.feedUrl;
    if (feedUrl == null || feedUrl.isEmpty) return;
    setState(() {
      _loadingRssEpisodes = true;
      _rssEpisodesError = null;
    });
    try {
      final show = await ref
          .read(podcastRepositoryProvider)
          .loadRssFeed(feedUrl, title: widget.show.title);
      if (!mounted) return;
      setState(() {
        _show = show;
        _loadingRssEpisodes = false;
      });
      if (await ref.read(libraryRepositoryProvider).isSubscribed(show.id)) {
        await ref.read(libraryRepositoryProvider).subscribe(show);
      }
    } catch (error, stackTrace) {
      AppLogger.failure(
        'load_rss_episodes',
        error,
        area: 'podcast',
        stackTrace: stackTrace,
        data: {
          'showId': widget.show.id,
          'title': widget.show.title,
          'feedUrl': feedUrl,
        },
      );
      if (mounted) {
        setState(() {
          _loadingRssEpisodes = false;
          _rssEpisodesError = error;
        });
      }
    }
  }

  Future<void> _subscribe() async {
    if (_subscribing || _subscribed) return;
    final show = _show;
    setState(() => _subscribing = true);
    try {
      AppLogger.userAction(
        'subscribe_show',
        area: 'library',
        data: {
          'showId': show.id,
          'title': show.title,
          'episodeCount': show.episodes.length,
        },
      );
      await ref.read(libraryRepositoryProvider).subscribe(show);
      AppLogger.result(
        'subscribe_show',
        area: 'library',
        data: {'showId': show.id, 'title': show.title},
      );
      if (mounted) {
        setState(() => _subscribed = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已加入订阅')));
      }
    } finally {
      if (mounted) setState(() => _subscribing = false);
    }
  }

  Future<void> _playEpisode(Episode episode) async {
    AppLogger.userAction(
      'play_episode_from_show',
      area: 'player',
      data: {
        'episodeId': episode.id,
        'title': episode.title,
        'showId': widget.show.id,
      },
    );
    try {
      await ref.read(playbackControllerProvider).play(episode);
    } catch (error, stackTrace) {
      AppLogger.failure(
        'play_episode_from_show',
        error,
        area: 'player',
        stackTrace: stackTrace,
        data: {'episodeId': episode.id, 'showId': widget.show.id},
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _toggleCache(Episode episode) async {
    if (_busyEpisodeIds.contains(episode.id)) return;
    if (_cachedEpisodeIds.contains(episode.id)) return;
    setState(() => _busyEpisodeIds.add(episode.id));
    try {
      await ref.read(audioCacheRepositoryProvider).cache(episode);
      if (mounted) {
        setState(() => _cachedEpisodeIds.add(episode.id));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已缓存到本地')));
      }
    } catch (error, stackTrace) {
      AppLogger.failure(
        'toggle_show_episode_cache',
        error,
        area: 'cache',
        stackTrace: stackTrace,
        data: {'episodeId': episode.id, 'title': episode.title},
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _busyEpisodeIds.remove(episode.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final show = _show;
    final loadingEpisodes =
        (_loadingCreatorVideos && _isBilibiliCreatorShow(widget.show)) ||
        (_loadingRssEpisodes && _isRssShow(widget.show));
    final episodes = loadingEpisodes ? const <Episode>[] : show.episodes;
    final queue = ref.watch(playbackQueueProvider);
    final isQueued = queue.items.any((item) => item.id == show.id);
    final isCreatorShow = _isBilibiliCreatorShow(show);
    final description = plainTextOrNull(show.description);
    return Scaffold(
      appBar: AppBar(title: Text(show.sourceType.label)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShowCover(url: show.imageUrl, circular: isCreatorShow),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            show.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(show.author ?? show.sourceType.label),
                          const SizedBox(height: 10),
                          Text(
                            loadingEpisodes ? '加载中' : '${episodes.length} 集',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    IconButton(
                      tooltip: isQueued ? '已加入播放列表' : '加入播放列表',
                      icon: Icon(isQueued ? Icons.check : Icons.playlist_add),
                      onPressed: episodes.isEmpty || isQueued
                          ? null
                          : () {
                              AppLogger.userAction(
                                'add_show_to_queue',
                                area: 'player',
                                data: {
                                  'showId': show.id,
                                  'title': show.title,
                                  'episodeCount': episodes.length,
                                },
                              );
                              ref
                                  .read(playbackQueueProvider.notifier)
                                  .addShow(show);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('已加入播放列表')),
                              );
                            },
                    ),
                    FilledButton.tonalIcon(
                      icon: _checkingSubscription || _subscribing
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _subscribed
                                  ? Icons.notifications_active_outlined
                                  : Icons.notifications_none,
                            ),
                      label: Text(_subscriptionTooltip()),
                      onPressed:
                          _checkingSubscription || _subscribing || _subscribed
                          ? null
                          : _subscribe,
                    ),
                  ],
                ),
                if (description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 20),
                Text('单集', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_loadingCreatorVideos || _loadingRssEpisodes)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_rssEpisodesError != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.error_outline),
                      title: const Text('RSS 单集列表加载失败'),
                      subtitle: Text(_rssEpisodesError.toString()),
                      trailing: TextButton(
                        onPressed: _loadRssEpisodes,
                        child: const Text('重试'),
                      ),
                    ),
                  ),
                if (_creatorVideosError != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.error_outline),
                      title: const Text('UP主视频列表加载失败'),
                      subtitle: Text(_creatorVideosError.toString()),
                      trailing: TextButton(
                        onPressed: _loadCreatorVideos,
                        child: const Text('重试'),
                      ),
                    ),
                  ),
                ...episodes.map((episode) {
                  final episodeQueued = queue.items.any(
                    (item) => item.containsEpisode(episode.id),
                  );
                  final cached = _cachedEpisodeIds.contains(episode.id);
                  final busy = _busyEpisodeIds.contains(episode.id);
                  return AudioListItem(
                    coverUrl: episode.imageUrl,
                    coverSize: 64,
                    placeholderIcon: Icons.music_note,
                    title: episode.title,
                    metadata: _episodeSubtitle(episode) ?? '',
                    onTap: () {
                      AppLogger.userAction(
                        'open_episode',
                        area: 'podcast',
                        data: {
                          'episodeId': episode.id,
                          'title': episode.title,
                          'showId': show.id,
                        },
                      );
                      context.push(
                        '/episode',
                        extra: EpisodeScreenArgs(
                          episode: episode,
                          relatedShows: [show],
                        ),
                      );
                    },
                    actions: [
                      IconButton(
                        tooltip: episodeQueued ? '已加入播放列表' : '加入播放列表',
                        icon: Icon(
                          episodeQueued ? Icons.check : Icons.playlist_add,
                        ),
                        onPressed: episodeQueued
                            ? null
                            : () {
                                AppLogger.userAction(
                                  'add_episode_to_queue',
                                  area: 'player',
                                  data: {
                                    'episodeId': episode.id,
                                    'title': episode.title,
                                    'showId': show.id,
                                  },
                                );
                                ref
                                    .read(playbackQueueProvider.notifier)
                                    .add(episode);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('已加入播放列表')),
                                );
                              },
                      ),
                      IconButton(
                        tooltip: cached ? '已缓存' : '缓存到本地',
                        icon: busy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                cached
                                    ? Icons.offline_pin
                                    : Icons.download_outlined,
                              ),
                        onPressed: busy || cached
                            ? null
                            : () {
                                AppLogger.userAction(
                                  'toggle_episode_cache',
                                  area: 'cache',
                                  data: {
                                    'episodeId': episode.id,
                                    'title': episode.title,
                                    'cached': cached,
                                  },
                                );
                                _toggleCache(episode);
                              },
                      ),
                      IconButton(
                        tooltip: '播放',
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _playEpisode(episode),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }

  String? _episodeSubtitle(Episode episode) {
    final parts = <String>[
      if (episode.publishedAt != null)
        formatAudioRelativeDate(episode.publishedAt!),
      if (episode.duration != null) formatAudioDuration(episode.duration!),
      if (episode.author != null && episode.author!.isNotEmpty) episode.author!,
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  String _subscriptionTooltip() {
    if (_checkingSubscription) return '检查中';
    if (_subscribing) return '订阅中';
    if (_subscribed) return '已订阅';
    return '订阅';
  }

  bool _isBilibiliCreatorShow(PodcastShow show) {
    return show.sourceType == SourceType.bilibili &&
        show.id.startsWith('bili-up-');
  }

  bool _isRssShow(PodcastShow show) {
    return show.sourceType == SourceType.rss ||
        (show.feedUrl != null && show.feedUrl!.isNotEmpty);
  }
}

class _ShowCover extends StatelessWidget {
  const _ShowCover({this.url, this.circular = false});

  final String? url;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final radius = circular ? 54.0 : 8.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox.square(
        dimension: 108,
        child: url == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(circular ? Icons.person : Icons.podcasts, size: 40),
              )
            : Image.network(url!, fit: BoxFit.cover),
      ),
    );
  }
}
