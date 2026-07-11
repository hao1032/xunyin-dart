import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_logger.dart';
import '../../core/display_formatters.dart';
import '../../core/plain_text.dart';
import '../../core/app_layout.dart';
import '../app_list_item.dart';
import '../downloads/repository.dart';
import '../library/repository.dart';
import '../player/pages/mini.dart';
import '../player/services/playback_queue.dart';
import '../player/services/controller.dart';
import '../episode/model.dart';
import '../episode/page.dart';
import 'model.dart';
import 'service.dart';

class SeriesDetailPage extends ConsumerStatefulWidget {
  const SeriesDetailPage({super.key, required this.series});

  final Series series;

  @override
  ConsumerState<SeriesDetailPage> createState() => _SeriesDetailPageState();
}

class _SeriesDetailPageState extends ConsumerState<SeriesDetailPage> {
  bool _subscribing = false;
  bool _checkingSubscription = true;
  bool _subscribed = false;
  bool _loadingEpisodes = false;
  Object? _episodesError;
  late Series _series;
  final Set<String> _downloadedEpisodeIds = {};
  final Set<String> _busyEpisodeIds = {};

  @override
  void initState() {
    super.initState();
    _series = widget.series;
    _loadSubscriptionState();
    _loadDownloadsState();
    if (widget.series is! BilibiliCollectionSeries) {
      _loadEpisodes();
    }
  }

  Future<void> _loadSubscriptionState() async {
    try {
      final subscribed = await ref
          .read(libraryRepositoryProvider)
          .isSubscribed(widget.series.id);
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
        data: {'seriesId': widget.series.id},
      );
      if (mounted) {
        setState(() => _checkingSubscription = false);
      }
    }
  }

  Future<void> _loadDownloadsState() async {
    try {
      final downloaded = await ref
          .read(episodeDownloadRepositoryProvider)
          .downloadedEpisodes();
      if (mounted) {
        setState(() {
          _downloadedEpisodeIds
            ..clear()
            ..addAll(downloaded.map((item) => item.episode.id));
        });
      }
    } catch (error, stackTrace) {
      AppLogger.failure(
        'load_series_download_state',
        error,
        area: 'download',
        stackTrace: stackTrace,
        data: {'seriesId': widget.series.id},
      );
    }
  }

  Future<void> _loadEpisodes() async {
    setState(() {
      _loadingEpisodes = true;
      _episodesError = null;
    });
    try {
      final series = await ref.read(seriesServiceProvider).load(widget.series);
      if (mounted) {
        setState(() {
          _series = series;
          _loadingEpisodes = false;
        });
      }
      if (await ref.read(libraryRepositoryProvider).isSubscribed(series.id)) {
        await ref.read(libraryRepositoryProvider).subscribe(series);
      }
    } catch (error, stackTrace) {
      AppLogger.failure(
        'load_series_episodes',
        error,
        area: 'series',
        stackTrace: stackTrace,
        data: {
          'seriesId': widget.series.id,
          'title': widget.series.title,
          'type': widget.series.runtimeType.toString(),
        },
      );
      if (mounted) {
        setState(() {
          _loadingEpisodes = false;
          _episodesError = error;
        });
      }
    }
  }

  Future<void> _subscribe() async {
    if (_subscribing || _subscribed) return;
    final series = _series;
    setState(() => _subscribing = true);
    try {
      AppLogger.userAction(
        'subscribe_series',
        area: 'library',
        data: {
          'seriesId': series.id,
          'title': series.title,
          'episodeCount': series.episodes.length,
        },
      );
      await ref.read(libraryRepositoryProvider).subscribe(series);
      AppLogger.result(
        'subscribe_series',
        area: 'library',
        data: {'seriesId': series.id, 'title': series.title},
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
      'play_episode_from_series',
      area: 'player',
      data: {
        'episodeId': episode.id,
        'title': episode.title,
        'seriesId': widget.series.id,
      },
    );
    try {
      await ref.read(playbackControllerProvider).play(episode);
    } catch (error, stackTrace) {
      AppLogger.failure(
        'play_episode_from_series',
        error,
        area: 'player',
        stackTrace: stackTrace,
        data: {'episodeId': episode.id, 'seriesId': widget.series.id},
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _toggleDownload(Episode episode) async {
    if (_busyEpisodeIds.contains(episode.id)) return;
    if (_downloadedEpisodeIds.contains(episode.id)) return;
    setState(() => _busyEpisodeIds.add(episode.id));
    try {
      await ref.read(episodeDownloadRepositoryProvider).download(episode);
      if (mounted) {
        setState(() => _downloadedEpisodeIds.add(episode.id));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已下载到本地')));
      }
    } catch (error, stackTrace) {
      AppLogger.failure(
        'toggle_series_episode_download',
        error,
        area: 'download',
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
    final series = _series;
    final episodes = _loadingEpisodes ? const <Episode>[] : series.episodes;
    final queue = ref.watch(playbackQueueProvider);
    final isQueued = queue.items.any((item) => item.id == series.id);
    final isCreatorSeries = series is BilibiliCreatorSeries;
    final description = plainTextOrNull(series.description);
    return Scaffold(
      appBar: AppBar(title: Text(series.label)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                AppContent(
                  maxWidth: 760,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SeriesCover(
                            url: series.imageUrl,
                            circular: isCreatorSeries,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  series.title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 6),
                                Text(series.author ?? series.sourceType.label),
                                const SizedBox(height: 10),
                                Text(
                                  _loadingEpisodes
                                      ? '加载中'
                                      : '${episodes.length} 集',
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
                            icon: Icon(
                              isQueued ? Icons.check : Icons.playlist_add,
                            ),
                            onPressed: episodes.isEmpty || isQueued
                                ? null
                                : () {
                                    AppLogger.userAction(
                                      'add_series_to_queue',
                                      area: 'player',
                                      data: {
                                        'seriesId': series.id,
                                        'title': series.title,
                                        'episodeCount': episodes.length,
                                      },
                                    );
                                    ref
                                        .read(playbackQueueProvider.notifier)
                                        .addSeries(series);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('已加入播放列表')),
                                    );
                                  },
                          ),
                          FilledButton.tonalIcon(
                            icon: _checkingSubscription || _subscribing
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    _subscribed
                                        ? Icons.notifications_active_outlined
                                        : Icons.notifications_none,
                                  ),
                            label: Text(_subscriptionTooltip()),
                            onPressed:
                                _checkingSubscription ||
                                    _subscribing ||
                                    _subscribed
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
                      AppSectionTitle(
                        title: '单集',
                        subtitle: _loadingEpisodes
                            ? '正在加载'
                            : '共 ${episodes.length} 集',
                      ),
                      const SizedBox(height: 10),
                      if (_loadingEpisodes)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (_episodesError != null)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.error_outline),
                            title: Text('${series.shortLabel}内容加载失败'),
                            subtitle: Text(_episodesError.toString()),
                            trailing: TextButton(
                              onPressed: _loadEpisodes,
                              child: const Text('重试'),
                            ),
                          ),
                        ),
                      ...episodes.map((episode) {
                        final episodeQueued = queue.items.any(
                          (item) => item.containsEpisode(episode.id),
                        );
                        final downloaded = _downloadedEpisodeIds.contains(
                          episode.id,
                        );
                        final busy = _busyEpisodeIds.contains(episode.id);
                        return AppListItem(
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
                                'seriesId': series.id,
                              },
                            );
                            context.push(
                              '/episode',
                              extra: EpisodePageArgs(
                                episode: episode,
                                relatedSeries: [series],
                              ),
                            );
                          },
                          actions: [
                            IconButton(
                              tooltip: episodeQueued ? '已加入播放列表' : '加入播放列表',
                              icon: Icon(
                                episodeQueued
                                    ? Icons.check
                                    : Icons.playlist_add,
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
                                          'seriesId': series.id,
                                        },
                                      );
                                      ref
                                          .read(playbackQueueProvider.notifier)
                                          .add(episode);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('已加入播放列表'),
                                        ),
                                      );
                                    },
                            ),
                            IconButton(
                              tooltip: downloaded ? '已下载' : '下载到本地',
                              icon: busy
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      downloaded
                                          ? Icons.offline_pin
                                          : Icons.download_outlined,
                                    ),
                              onPressed: busy || downloaded
                                  ? null
                                  : () {
                                      AppLogger.userAction(
                                        'toggle_episode_download',
                                        area: 'download',
                                        data: {
                                          'episodeId': episode.id,
                                          'title': episode.title,
                                          'downloaded': downloaded,
                                        },
                                      );
                                      _toggleDownload(episode);
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
      if (episode.publishedAt != null) formatRelativeDate(episode.publishedAt!),
      if (episode.duration != null) formatDuration(episode.duration!),
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
}

class _SeriesCover extends StatelessWidget {
  const _SeriesCover({this.url, this.circular = false});

  final String? url;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final radius = circular ? 54.0 : 16.0;
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
