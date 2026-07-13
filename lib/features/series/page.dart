import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_logger.dart';
import '../../core/display_formatters.dart';
import '../../core/plain_text.dart';
import '../../core/app_layout.dart';
import '../../shared/wigets/app_bar.dart';
import '../../shared/wigets/app_detail.dart';
import '../../shared/wigets/app_episode_item.dart';
import '../downloads/repository.dart';
import '../settings/repository.dart';
import '../player/services/playback_queue.dart';
import '../player/services/controller.dart';
import '../episode/model.dart';
import 'model.dart';
import 'service.dart';

class SeriesDetailPage extends ConsumerStatefulWidget {
  const SeriesDetailPage({super.key, required this.series});

  final Series series;

  @override
  ConsumerState<SeriesDetailPage> createState() => _SeriesDetailPageState();
}

class _SeriesDetailPageState extends ConsumerState<SeriesDetailPage> {
  static const _episodesPageSize = 10;

  bool _subscribing = false;
  bool _checkingSubscription = true;
  bool _subscribed = false;
  bool _loadingEpisodes = false;
  bool _loadingMoreEpisodes = false;
  bool _hasMoreEpisodes = false;
  int _loadedEpisodePages = 0;
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
    } else {
      _loadedEpisodePages = widget.series.episodes.isEmpty ? 0 : 1;
      _hasMoreEpisodes = widget.series.episodes.length > _episodesPageSize;
    }
  }

  Future<void> _loadSubscriptionState() async {
    try {
      final subscribed = await ref
          .read(settingsRepositoryProvider)
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
        area: 'settings',
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
      final series = await ref
          .read(seriesServiceProvider)
          .load(widget.series, pageSize: _episodesPageSize);
      if (mounted) {
        setState(() {
          _series = series;
          _loadedEpisodePages = series.episodes.isEmpty ? 0 : 1;
          _hasMoreEpisodes = _hasNextEpisodePage(series);
          _loadingEpisodes = false;
        });
      }
      if (await ref.read(settingsRepositoryProvider).isSubscribed(series.id)) {
        await ref.read(settingsRepositoryProvider).subscribe(series);
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

  Future<void> _loadMoreEpisodes() async {
    if (_loadingEpisodes || _loadingMoreEpisodes || !_hasMoreEpisodes) return;
    final series = _series;
    if (!_usesRemoteEpisodePages(series)) {
      setState(() {
        _loadedEpisodePages += 1;
        _hasMoreEpisodes =
            series.episodes.length > _loadedEpisodePages * _episodesPageSize;
      });
      return;
    }

    final nextPage = _loadedEpisodePages + 1;
    setState(() {
      _loadingMoreEpisodes = true;
      _episodesError = null;
    });
    try {
      final nextSeries = await ref
          .read(seriesServiceProvider)
          .load(series, page: nextPage, pageSize: _episodesPageSize);
      final loaded = series.copyWith(
        episodes: _mergeEpisodes(series.episodes, nextSeries.episodes),
      );
      if (mounted) {
        setState(() {
          _series = loaded;
          _loadedEpisodePages = nextPage;
          _hasMoreEpisodes = nextSeries.episodes.length == _episodesPageSize;
          _loadingMoreEpisodes = false;
        });
      }
      if (await ref.read(settingsRepositoryProvider).isSubscribed(loaded.id)) {
        await ref.read(settingsRepositoryProvider).subscribe(loaded);
      }
    } catch (error, stackTrace) {
      AppLogger.failure(
        'load_more_series_episodes',
        error,
        area: 'series',
        stackTrace: stackTrace,
        data: {
          'seriesId': series.id,
          'title': series.title,
          'page': nextPage,
          'pageSize': _episodesPageSize,
        },
      );
      if (mounted) {
        setState(() {
          _loadingMoreEpisodes = false;
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
        area: 'settings',
        data: {
          'seriesId': series.id,
          'title': series.title,
          'episodeCount': series.episodes.length,
        },
      );
      await ref.read(settingsRepositoryProvider).subscribe(series);
      AppLogger.result(
        'subscribe_series',
        area: 'settings',
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

  void _openCreatorSeries(BilibiliCreatorSeries creator) {
    AppLogger.userAction(
      'open_creator_from_collection',
      area: 'series',
      data: {'seriesId': _series.id, 'creatorId': creator.id},
    );
    context.push('/series', extra: creator);
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

  Future<void> _pauseEpisode(Episode episode) async {
    AppLogger.userAction(
      'pause_episode_from_series',
      area: 'player',
      data: {
        'episodeId': episode.id,
        'title': episode.title,
        'seriesId': widget.series.id,
      },
    );
    await ref.read(appPlayerProvider).pause();
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
        ).showSnackBar(const SnackBar(content: Text(AppText.downloadedLocal)));
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
    final episodes = _loadingEpisodes
        ? const <Episode>[]
        : _visibleEpisodes(series);
    final queue = ref.watch(playbackQueueProvider);
    final isQueued = queue.items.any((item) => item.id == series.id);
    final isCreatorSeries = series is BilibiliCreatorSeries;
    final description = plainTextOrNull(series.description);
    return Scaffold(
      appBar: const AppPageBar(title: AppText.detailTitle),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: AppInsets.zero,
              children: [
                AppContent(
                  maxWidth: AppSizes.seriesPageMaxWidth,
                  padding: AppInsets.detailPage,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppDetail(
                        title: series.title,
                        coverUrl: series.imageUrl,
                        coverIcon: isCreatorSeries
                            ? AppIcons.user
                            : AppIcons.podcast,
                        subtitle: _SeriesAuthor(
                          series: series,
                          onOpenCreator: _openCreatorSeries,
                        ),
                        metadata: _seriesMetadata(series, episodes),
                        actions: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Tooltip(
                              message: isQueued
                                  ? AppText.addedToQueueFull
                                  : AppText.addToQueueFull,
                              child: FilledButton.tonalIcon(
                                icon: Icon(
                                  isQueued
                                      ? AppIcons.addedToQueue
                                      : AppIcons.addToQueue,
                                ),
                                label: Text(
                                  isQueued
                                      ? AppText.addedToQueue
                                      : AppText.addToQueue,
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
                                            .read(
                                              playbackQueueProvider.notifier,
                                            )
                                            .addSeries(
                                              series.copyWith(
                                                episodes: episodes,
                                              ),
                                            );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              AppText.addedToQueueFull,
                                            ),
                                          ),
                                        );
                                      },
                              ),
                            ),
                            FilledButton.tonalIcon(
                              icon: _checkingSubscription || _subscribing
                                  ? const SizedBox.square(
                                      dimension: AppSizes.indicator,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      _subscribed
                                          ? AppIcons.notificationsActive
                                          : AppIcons.notifications,
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
                        description: description,
                        children: [
                          AppDetailEpisodeList(
                            title: AppText.episodesTitle,
                            subtitle: _episodeSectionSubtitle(series, episodes),
                            loading: _loadingEpisodes,
                            error: _episodesError,
                            errorTitle: '${series.shortLabel}内容加载失败',
                            onRetry: _loadEpisodes,
                            footer: !_loadingEpisodes && _hasMoreEpisodes
                                ? _LoadMoreEpisodesButton(
                                    loading: _loadingMoreEpisodes,
                                    onPressed: _loadMoreEpisodes,
                                  )
                                : null,
                            children: episodes.map((episode) {
                              final episodeQueued = queue.items.any(
                                (item) => item.containsEpisode(episode.id),
                              );
                              final downloaded = _downloadedEpisodeIds.contains(
                                episode.id,
                              );
                              final busy = _busyEpisodeIds.contains(episode.id);
                              return AppEpisodeItem(
                                episode: episode,
                                subtitle: _episodeSubtitle(episode),
                                metadata: AppEpisodeItem.metadataOf(episode),
                                onOpen: () => AppLogger.userAction(
                                  'open_episode',
                                  area: 'podcast',
                                  data: {
                                    'episodeId': episode.id,
                                    'title': episode.title,
                                    'seriesId': series.id,
                                  },
                                ),
                                isQueued: episodeQueued,
                                isDownloaded: downloaded,
                                isDownloadBusy: busy,
                                isBusy: _loadingEpisodes,
                                onAddToQueue: () {
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(AppText.addedToQueueFull),
                                    ),
                                  );
                                },
                                onDownload: busy || downloaded
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
                                onPlay: () => _playEpisode(episode),
                                onPause: () => _pauseEpisode(episode),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _episodeSubtitle(Episode episode) {
    return episode.author ?? episode.sourceType.label;
  }

  String _seriesMetadata(Series series, List<Episode> episodes) {
    final latestPublishedAt = _latestPublishedAt(episodes);
    final parts = <String>[
      if (latestPublishedAt != null)
        '更新日期：${formatRelativeDate(latestPublishedAt)}',
      series.sourceType.label,
      if (episodes.isNotEmpty) '共 ${series.episodes.length} 集',
    ];
    return parts.join(' · ');
  }

  DateTime? _latestPublishedAt(List<Episode> episodes) {
    DateTime? latest;
    for (final episode in episodes) {
      final publishedAt = episode.publishedAt;
      if (publishedAt == null) continue;
      if (latest == null || publishedAt.isAfter(latest)) {
        latest = publishedAt;
      }
    }
    return latest;
  }

  List<Episode> _visibleEpisodes(Series series) {
    if (_usesRemoteEpisodePages(series)) return series.episodes;
    final count = _loadedEpisodePages * _episodesPageSize;
    if (count <= 0 || series.episodes.length <= count) return series.episodes;
    return series.episodes.take(count).toList();
  }

  bool _hasNextEpisodePage(Series series) {
    if (_usesRemoteEpisodePages(series)) {
      return series.episodes.length == _episodesPageSize;
    }
    return series.episodes.length > _episodesPageSize;
  }

  bool _usesRemoteEpisodePages(Series series) {
    return series is BilibiliCreatorSeries;
  }

  List<Episode> _mergeEpisodes(List<Episode> current, List<Episode> incoming) {
    final seen = current.map((episode) => episode.id).toSet();
    return [...current, ...incoming.where((episode) => seen.add(episode.id))];
  }

  String _episodeSectionSubtitle(Series series, List<Episode> episodes) {
    if (_usesRemoteEpisodePages(series)) return '已加载 ${episodes.length} 集';
    return '已显示 ${episodes.length} / ${series.episodes.length} 集';
  }

  String _subscriptionTooltip() {
    if (_checkingSubscription) return '检查中';
    if (_subscribing) return '订阅中';
    if (_subscribed) return '已订阅';
    return '订阅';
  }
}

class _SeriesAuthor extends StatelessWidget {
  const _SeriesAuthor({required this.series, required this.onOpenCreator});

  final Series series;
  final ValueChanged<BilibiliCreatorSeries> onOpenCreator;

  @override
  Widget build(BuildContext context) {
    final creator = switch (series) {
      BilibiliCollectionSeries(:final creator) => creator,
      _ => null,
    };
    if (creator == null) {
      return Text(series.author ?? series.sourceType.label);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: AppInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          alignment: Alignment.centerLeft,
        ),
        onPressed: () => onOpenCreator(creator),
        child: Text(creator.title),
      ),
    );
  }
}

class _LoadMoreEpisodesButton extends StatelessWidget {
  const _LoadMoreEpisodesButton({
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        icon: loading
            ? const SizedBox.square(
                dimension: AppSizes.indicator,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(AppIcons.expandMore),
        label: Text(loading ? AppText.loading : AppText.loadingMore),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
        onPressed: loading ? null : onPressed,
      ),
    );
  }
}
