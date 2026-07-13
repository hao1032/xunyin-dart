import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/app_logger.dart';
import '../../../core/display_formatters.dart';
import '../../../core/app_layout.dart';
import '../../../shared/wigets/app_bar.dart';
import '../../../shared/wigets/app_list_item.dart';
import '../../episode/model.dart';
import '../../series/model.dart';
import '../../series/service.dart';
import '../services/playback_queue.dart';
import '../services/controller.dart';

class QueuePage extends ConsumerStatefulWidget {
  const QueuePage({super.key});

  @override
  ConsumerState<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends ConsumerState<QueuePage> {
  static const _seriesPageSize = 10;

  String? _playingRequestEpisodeId;
  final Set<String> _loadingMoreSeriesIds = {};
  final Map<String, bool> _seriesHasMore = {};

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(playbackQueueProvider);
    final player = ref.watch(appPlayerProvider);
    return Scaffold(
      appBar: const AppPageBar(title: AppText.playlistTitle),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<PlayerState>(
              stream: player.playerStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                final playing = state?.playing ?? player.playing;
                final processingState =
                    state?.processingState ?? player.processingState;
                final loading =
                    processingState == ProcessingState.loading ||
                    processingState == ProcessingState.buffering;
                return queue.items.isEmpty
                    ? const _EmptyQueue()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.page,
                          AppSpacing.xs,
                          AppSpacing.page,
                          AppSpacing.xl,
                        ),
                        itemCount: queue.items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, index) {
                          final entry = queue.items[index];
                          final selected =
                              queue.current != null &&
                              entry.containsEpisode(queue.current!.id);
                          final active = selected && playing;
                          final itemLoading = selected && !playing && loading;
                          if (entry.type == PlaybackQueueEntryType.series) {
                            return _SeriesQueueCard(
                              entry: entry,
                              playing: active,
                              loading: itemLoading,
                              busyEpisodeId: _playingRequestEpisodeId,
                              currentEpisodeId: queue.current?.id,
                              canLoadMore: _canLoadMoreSeries(entry),
                              loadingMore: _loadingMoreSeriesIds.contains(
                                entry.id,
                              ),
                              onPlayEpisode: (episode, childIndex) =>
                                  _playEpisode(
                                    context,
                                    episode,
                                    index: index,
                                    childIndex: childIndex,
                                  ),
                              onPause: () =>
                                  _pauseFromQueue(queue.current, index: index),
                              onLoadMore: () => _loadMoreSeries(entry),
                            );
                          }
                          final episode = entry.episodes.first;
                          return AppListItem(
                            coverUrl: episode.imageUrl,
                            title: entry.title,
                            subtitle: _queueSubtitle(
                              episode,
                              fallback: entry.subtitle,
                            ),
                            compact: true,
                            onTap: () =>
                                _playEpisode(context, episode, index: index),
                            actions: [
                              _QueuePlayButton(
                                playing: active,
                                loading:
                                    _playingRequestEpisodeId == episode.id ||
                                    itemLoading,
                                tooltip: active
                                    ? AppText.pause
                                    : (itemLoading
                                          ? AppText.loading
                                          : AppText.play),
                                onPressed: active
                                    ? () =>
                                          _pauseFromQueue(episode, index: index)
                                    : () => _playEpisode(
                                        context,
                                        episode,
                                        index: index,
                                      ),
                              ),
                            ],
                          );
                        },
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _queueSubtitle(Episode episode, {String? fallback}) {
    return fallback ?? episode.author ?? episode.sourceType.label;
  }

  Future<void> _playEpisode(
    BuildContext context,
    Episode episode, {
    required int index,
    int? childIndex,
  }) async {
    setState(() => _playingRequestEpisodeId = episode.id);
    AppLogger.userAction(
      'play_from_queue',
      area: 'player',
      data: {
        'episodeId': episode.id,
        'title': episode.title,
        'index': index,
        'childIndex': childIndex,
      },
    );
    try {
      await ref.read(playbackControllerProvider).play(episode);
    } catch (error, stackTrace) {
      AppLogger.failure(
        'play_from_queue',
        error,
        area: 'player',
        stackTrace: stackTrace,
        data: {'episodeId': episode.id},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          if (_playingRequestEpisodeId == episode.id) {
            _playingRequestEpisodeId = null;
          }
        });
      }
    }
  }

  Future<void> _pauseFromQueue(Episode? episode, {required int index}) async {
    AppLogger.userAction(
      'pause_from_queue',
      area: 'player',
      data: {'episodeId': episode?.id, 'title': episode?.title, 'index': index},
    );
    await ref.read(appPlayerProvider).pause();
  }

  bool _canLoadMoreSeries(PlaybackQueueEntry entry) {
    final series = _seriesForLoading(entry);
    if (series == null || entry.episodes.isEmpty) return false;
    final known = _seriesHasMore[entry.id];
    if (known != null) return known;
    return entry.episodes.length % _seriesPageSize == 0;
  }

  Series? _seriesForLoading(PlaybackQueueEntry entry) {
    final series = entry.series;
    if (series is BilibiliCreatorSeries) return series;
    if (series != null) return null;
    if (!entry.id.startsWith('bili-up-')) return null;
    return BilibiliCreatorSeries(
      id: entry.id,
      title: entry.title,
      originalUrl: '',
      episodes: entry.episodes,
    );
  }

  Future<void> _loadMoreSeries(PlaybackQueueEntry entry) async {
    final series = _seriesForLoading(entry);
    if (series == null || _loadingMoreSeriesIds.contains(entry.id)) return;
    final nextPage = (entry.episodes.length ~/ _seriesPageSize) + 1;
    setState(() => _loadingMoreSeriesIds.add(entry.id));
    AppLogger.userAction(
      'load_more_queue_series',
      area: 'player',
      data: {
        'seriesId': entry.id,
        'title': entry.title,
        'page': nextPage,
        'pageSize': _seriesPageSize,
      },
    );
    try {
      final nextSeries = await ref
          .read(seriesServiceProvider)
          .load(series, page: nextPage, pageSize: _seriesPageSize);
      final loaded = series.copyWith(
        episodes: _mergeEpisodes(entry.episodes, nextSeries.episodes),
      );
      ref.read(playbackQueueProvider.notifier).updateSeries(loaded);
      if (mounted) {
        setState(() {
          _seriesHasMore[entry.id] =
              nextSeries.episodes.length == _seriesPageSize;
        });
      }
      AppLogger.result(
        'load_more_queue_series',
        area: 'player',
        data: {
          'seriesId': entry.id,
          'title': entry.title,
          'page': nextPage,
          'episodeCount': loaded.episodes.length,
        },
      );
    } catch (error, stackTrace) {
      AppLogger.failure(
        'load_more_queue_series',
        error,
        area: 'player',
        stackTrace: stackTrace,
        data: {'seriesId': entry.id, 'title': entry.title, 'page': nextPage},
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _loadingMoreSeriesIds.remove(entry.id));
      }
    }
  }

  List<Episode> _mergeEpisodes(List<Episode> current, List<Episode> incoming) {
    final seen = current.map((episode) => episode.id).toSet();
    return [...current, ...incoming.where((episode) => seen.add(episode.id))];
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: AppIcons.queue,
      title: '播放列表还是空的',
      message: '去发现页找一段想听的内容，单集和整个系列都可以加入这里。',
    );
  }
}

class _SeriesQueueCard extends StatefulWidget {
  const _SeriesQueueCard({
    required this.entry,
    required this.playing,
    required this.loading,
    required this.busyEpisodeId,
    required this.currentEpisodeId,
    required this.canLoadMore,
    required this.loadingMore,
    required this.onPlayEpisode,
    required this.onPause,
    required this.onLoadMore,
  });

  final PlaybackQueueEntry entry;
  final bool playing;
  final bool loading;
  final String? busyEpisodeId;
  final String? currentEpisodeId;
  final bool canLoadMore;
  final bool loadingMore;
  final void Function(Episode episode, int childIndex) onPlayEpisode;
  final VoidCallback onPause;
  final VoidCallback onLoadMore;

  @override
  State<_SeriesQueueCard> createState() => _SeriesQueueCardState();
}

class _SeriesQueueCardState extends State<_SeriesQueueCard> {
  static const _episodeTileEstimatedHeight = 64.0;
  static const _loadMoreEstimatedHeight = 52.0;

  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final firstEpisode = widget.entry.episodes.first;
    final playableEpisode = widget.entry.playableEpisode;
    final playableEpisodeIndex = widget.entry.episodes.indexWhere(
      (episode) => episode.id == playableEpisode.id,
    );
    final currentIndex = widget.currentEpisodeId == null
        ? -1
        : widget.entry.episodes.indexWhere(
            (episode) => episode.id == widget.currentEpisodeId,
          );
    final subtitle = [
      _seriesSubtitle(widget.entry),
      if (widget.entry.lastPlayedEpisodeId != null && currentIndex < 0)
        '继续第 ${playableEpisodeIndex + 1} 集',
    ].join(' · ');
    final maxEpisodeListHeight = (MediaQuery.sizeOf(context).height * 0.52)
        .clamp(260.0, 520.0)
        .toDouble();
    final estimatedEpisodeListHeight =
        widget.entry.episodes.length * _episodeTileEstimatedHeight +
        (widget.canLoadMore ? _loadMoreEstimatedHeight : 0);
    final episodeListHeight = estimatedEpisodeListHeight
        .clamp(0.0, maxEpisodeListHeight)
        .toDouble();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs - 1),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.item,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AppCover(
                        url: firstEpisode.imageUrl,
                        size: 52,
                        icon: AppIcons.podcast,
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadii.xs),
                            border: Border.all(
                              color: colors.surfaceContainerLowest,
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Text(
                              '${widget.entry.episodes.length}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colors.onPrimaryContainer,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.item + 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.entry.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs + 1),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        if (currentIndex >= 0) ...[
                          const SizedBox(height: AppSpacing.sm - 2),
                          Text(
                            '正在播放第 ${currentIndex + 1} 集',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _QueuePlayButton(
                    playing: widget.playing,
                    loading:
                        widget.busyEpisodeId == playableEpisode.id ||
                        widget.loading,
                    tooltip: widget.playing
                        ? AppText.pause
                        : (widget.loading ? AppText.loading : '播放系列'),
                    onPressed: widget.playing
                        ? widget.onPause
                        : () => widget.onPlayEpisode(
                            playableEpisode,
                            playableEpisodeIndex < 0 ? 0 : playableEpisodeIndex,
                          ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    children: [
                      Divider(
                        height: 1,
                        color: colors.outlineVariant.withValues(alpha: .55),
                      ),
                      ColoredBox(
                        color: colors.surfaceContainer.withValues(alpha: .42),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.sm,
                            AppSpacing.xs,
                            AppSpacing.sm,
                            AppSpacing.sm - 2,
                          ),
                          child: SizedBox(
                            height: episodeListHeight,
                            child: ListView.builder(
                              primary: false,
                              padding: AppInsets.zero,
                              itemCount:
                                  widget.entry.episodes.length +
                                  (widget.canLoadMore ? 1 : 0),
                              itemBuilder: (context, episodeIndex) {
                                if (episodeIndex >=
                                    widget.entry.episodes.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppSpacing.xs,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        icon: widget.loadingMore
                                            ? const SizedBox.square(
                                                dimension: AppSpacing.lg,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(AppIcons.expandMore),
                                        label: Text(
                                          widget.loadingMore
                                              ? AppText.loading
                                              : AppText.loadingMore,
                                        ),
                                        onPressed: widget.loadingMore
                                            ? null
                                            : widget.onLoadMore,
                                      ),
                                    ),
                                  );
                                }

                                final episode =
                                    widget.entry.episodes[episodeIndex];
                                final current =
                                    episode.id == widget.currentEpisodeId;
                                return _SeriesEpisodeTile(
                                  episode: episode,
                                  episodeIndex: episodeIndex,
                                  current: current,
                                  playing: widget.playing && current,
                                  loading:
                                      episode.id == widget.busyEpisodeId ||
                                      (widget.loading && current),
                                  onPlay: () => widget.onPlayEpisode(
                                    episode,
                                    episodeIndex,
                                  ),
                                  onPause: widget.onPause,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  String _seriesSubtitle(PlaybackQueueEntry entry) {
    final subtitle = entry.subtitle;
    if (subtitle == null || subtitle.isEmpty) {
      return '${entry.episodes.length} 集';
    }
    final countPrefix = '${entry.episodes.length} 集 · ';
    if (subtitle.startsWith(countPrefix)) {
      return subtitle;
    }
    return '$subtitle · ${entry.episodes.length} 集';
  }
}

class _SeriesEpisodeTile extends StatelessWidget {
  const _SeriesEpisodeTile({
    required this.episode,
    required this.episodeIndex,
    required this.current,
    required this.playing,
    required this.loading,
    required this.onPlay,
    required this.onPause,
  });

  final Episode episode;
  final int episodeIndex;
  final bool current;
  final bool playing;
  final bool loading;
  final VoidCallback onPlay;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final metadata = [
      if (episode.publishedAt != null) formatRelativeDate(episode.publishedAt!),
      if (episode.duration != null) formatDuration(episode.duration!),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Material(
        color: current
            ? colors.primaryContainer.withValues(alpha: .58)
            : AppColors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          onTap: onPlay,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs + 1,
              AppSpacing.xs,
              AppSpacing.xs + 1,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '${episodeIndex + 1}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: current ? colors.primary : colors.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppCover(url: episode.imageUrl, size: 38, icon: AppIcons.music),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        episode.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: current ? colors.primary : null,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          metadata,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                _QueuePlayButton(
                  playing: playing,
                  loading: loading,
                  tooltip: playing
                      ? (loading ? AppText.loading : AppText.pause)
                      : AppText.play,
                  onPressed: playing ? onPause : onPlay,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QueuePlayButton extends StatelessWidget {
  const _QueuePlayButton({
    required this.playing,
    required this.loading,
    required this.tooltip,
    required this.onPressed,
  });

  final bool playing;
  final bool loading;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: loading ? AppText.loading : tooltip,
      icon: loading
          ? const SizedBox.square(
              dimension: AppSizes.indicator,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : playing
          ? const Icon(AppIcons.pause)
          : const Icon(AppIcons.playRounded),
      onPressed: loading ? null : onPressed,
    );
  }
}
