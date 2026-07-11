import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/formatters/audio_formatters.dart';
import '../../../core/text/plain_text.dart';
import '../../../core/widgets/app_layout.dart';
import '../../cache/repository.dart';
import '../../cache/model.dart';
import '../../player/services/playback_queue.dart';
import '../../player/services/controller.dart';
import '../../player/pages/mini.dart';
import '../model.dart';
import '../../series/model.dart';

class EpisodePage extends ConsumerStatefulWidget {
  const EpisodePage({
    super.key,
    required this.episode,
    this.relatedSeries = const [],
  });

  final Episode episode;
  final List<Series> relatedSeries;

  @override
  ConsumerState<EpisodePage> createState() => _EpisodePageState();
}

class _EpisodePageState extends ConsumerState<EpisodePage> {
  bool _loading = false;
  bool _checkingCache = true;
  bool _caching = false;
  CachedEpisode? _cachedEpisode;

  @override
  void initState() {
    super.initState();
    _loadCacheState();
  }

  Future<void> _loadCacheState() async {
    try {
      final cached = await ref
          .read(audioCacheRepositoryProvider)
          .cachedEpisode(widget.episode.id);
      if (mounted) {
        setState(() {
          _cachedEpisode = cached;
          _checkingCache = false;
        });
      }
    } catch (error, stackTrace) {
      AppLogger.failure(
        'load_cache_state',
        error,
        area: 'cache',
        stackTrace: stackTrace,
        data: {'episodeId': widget.episode.id},
      );
      if (mounted) {
        setState(() => _checkingCache = false);
      }
    }
  }

  Future<void> _play() async {
    setState(() => _loading = true);
    try {
      await ref.read(playbackControllerProvider).play(widget.episode);
    } catch (error, stackTrace) {
      AppLogger.failure(
        'play_episode',
        error,
        area: 'player',
        stackTrace: stackTrace,
        data: {'episodeId': widget.episode.id, 'title': widget.episode.title},
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cacheEpisode() async {
    setState(() => _caching = true);
    try {
      final cached = await ref
          .read(audioCacheRepositoryProvider)
          .cache(widget.episode);
      if (mounted) {
        setState(() => _cachedEpisode = cached);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已缓存到本地')));
      }
    } catch (error, stackTrace) {
      AppLogger.failure(
        'cache_episode',
        error,
        area: 'cache',
        stackTrace: stackTrace,
        data: {'episodeId': widget.episode.id, 'title': widget.episode.title},
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _caching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final episode = widget.episode;
    final relatedSeries = _dedupeSeries(widget.relatedSeries);
    final queue = ref.watch(playbackQueueProvider);
    final isQueued = queue.items.any(
      (item) => item.containsEpisode(episode.id),
    );
    final isCurrent = queue.current?.id == episode.id;
    final description = plainTextOrNull(episode.description);
    final metaParts = [
      if (episode.publishedAt != null) formatRelativeDate(episode.publishedAt!),
      if (episode.duration != null) formatDuration(episode.duration!),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(episode.sourceType.label)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                AppContent(
                  maxWidth: 620,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
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
                      const SizedBox(height: 24),
                      Text(
                        episode.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (metaParts.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          metaParts.join(' · '),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                      if (relatedSeries.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _RelatedSeriesLinks(
                          episode: episode,
                          series: relatedSeries,
                        ),
                      ] else ...[
                        const SizedBox(height: 10),
                        Text(
                          episode.author ?? episode.sourceType.label,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              icon: Icon(
                                isQueued ? Icons.check : Icons.playlist_add,
                              ),
                              label: Text(isQueued ? '已加入' : '加入列表'),
                              onPressed: isQueued
                                  ? null
                                  : () {
                                      AppLogger.userAction(
                                        'add_episode_to_queue',
                                        area: 'player',
                                        data: {
                                          'episodeId': episode.id,
                                          'title': episode.title,
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
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: _cacheTooltip(),
                            icon: _cacheIcon(),
                            onPressed:
                                _checkingCache ||
                                    _caching ||
                                    _cachedEpisode != null
                                ? null
                                : _cacheEpisode,
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip: _loading
                                ? '准备播放'
                                : (isCurrent ? '正在播放' : '播放'),
                            icon: _loading
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    isCurrent
                                        ? Icons.graphic_eq
                                        : Icons.play_arrow,
                                  ),
                            onPressed: _loading ? null : _play,
                            style: IconButton.styleFrom(
                              minimumSize: const Size.square(48),
                            ),
                          ),
                        ],
                      ),
                      if (_cachedEpisode != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          '已缓存 ${_formatBytes(_cachedEpisode!.bytes)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                      if (description != null) ...[
                        const SizedBox(height: AppSpacing.section),
                        const AppSectionTitle(title: '简介'),
                        const SizedBox(height: 10),
                        Text(description, style: const TextStyle(height: 1.6)),
                      ],
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

  Widget _cacheIcon() {
    if (_checkingCache || _caching) {
      return const SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Icon(_cachedEpisode == null ? Icons.download : Icons.offline_pin);
  }

  String _cacheTooltip() {
    if (_checkingCache) return '检查缓存';
    if (_caching) {
      return _cachedEpisode == null ? '缓存中' : '读取缓存';
    }
    if (_cachedEpisode == null) return '缓存到本地';
    return '已缓存 (${_formatBytes(_cachedEpisode!.bytes)})';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    return '${(mb / 1024).toStringAsFixed(1)} GB';
  }

  List<Series> _dedupeSeries(List<Series> series) {
    final seen = <String>{};
    return [
      for (final item in series)
        if (seen.add(item.id)) item,
    ];
  }
}

class _RelatedSeriesLinks extends StatelessWidget {
  const _RelatedSeriesLinks({required this.episode, required this.series});

  final Episode episode;
  final List<Series> series;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: series.map((item) {
        return InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () {
            AppLogger.userAction(
              'open_related_series',
              area: 'podcast',
              data: {
                'episodeId': episode.id,
                'seriesId': item.id,
                'seriesTitle': item.title,
              },
            );
            context.push('/series', extra: item);
          },
          child: Text(
            '${item.shortLabel}：${item.title}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class EpisodePageArgs {
  const EpisodePageArgs({required this.episode, this.relatedSeries = const []});

  final Episode episode;
  final List<Series> relatedSeries;
}
