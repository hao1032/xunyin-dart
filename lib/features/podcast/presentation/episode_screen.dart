import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logging/app_logger.dart';
import '../../cache/data/audio_cache_repository.dart';
import '../../cache/domain/cached_episode.dart';
import '../../player/data/playback_queue.dart';
import '../../player/data/player_controller.dart';
import '../../player/presentation/mini_player.dart';
import '../domain/episode.dart';
import '../domain/podcast_show.dart';
import '../domain/source_type.dart';

class EpisodeScreen extends ConsumerStatefulWidget {
  const EpisodeScreen({
    super.key,
    required this.episode,
    this.relatedShows = const [],
  });

  final Episode episode;
  final List<PodcastShow> relatedShows;

  @override
  ConsumerState<EpisodeScreen> createState() => _EpisodeScreenState();
}

class _EpisodeScreenState extends ConsumerState<EpisodeScreen> {
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

  Future<void> _removeCache() async {
    setState(() => _caching = true);
    try {
      await ref.read(audioCacheRepositoryProvider).remove(widget.episode.id);
      if (mounted) {
        setState(() => _cachedEpisode = null);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已删除缓存')));
      }
    } finally {
      if (mounted) setState(() => _caching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final episode = widget.episode;
    final relatedShows = _dedupeShows(widget.relatedShows);
    final queue = ref.watch(playbackQueueProvider);
    final isQueued = queue.items.any(
      (item) => item.containsEpisode(episode.id),
    );
    final isCurrent = queue.current?.id == episode.id;
    return Scaffold(
      appBar: AppBar(title: Text(episode.sourceType.label)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
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
                const SizedBox(height: 20),
                Text(
                  episode.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    episode.author ?? episode.sourceType.label,
                    if (episode.duration != null)
                      _formatDuration(episode.duration!),
                  ].join(' · '),
                ),
                if (relatedShows.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: relatedShows.map((show) {
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width - 40,
                        ),
                        child: OutlinedButton.icon(
                          icon: Icon(_showIcon(show)),
                          label: Text(
                            '${_showEntryLabel(show)}：${show.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () {
                            AppLogger.userAction(
                              'open_related_show',
                              area: 'podcast',
                              data: {
                                'episodeId': episode.id,
                                'showId': show.id,
                                'showTitle': show.title,
                              },
                            );
                            context.push('/show', extra: show);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (_cachedEpisode != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      avatar: const Icon(Icons.offline_pin, size: 18),
                      label: Text('已缓存 ${_formatBytes(_cachedEpisode!.bytes)}'),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  icon: _loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(isCurrent ? Icons.graphic_eq : Icons.play_arrow),
                  label: Text(
                    _loading ? '准备播放' : (isCurrent ? '正在播放' : '播放音频'),
                  ),
                  onPressed: _loading ? null : _play,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: _cacheIcon(),
                  label: Text(_cacheLabel()),
                  onPressed: _checkingCache || _caching
                      ? null
                      : (_cachedEpisode == null ? _cacheEpisode : _removeCache),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: Icon(isQueued ? Icons.check : Icons.playlist_add),
                  label: Text(isQueued ? '已加入播放列表' : '加入播放列表'),
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
                          ref.read(playbackQueueProvider.notifier).add(episode);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已加入播放列表')),
                          );
                        },
                ),
                if (episode.description != null) ...[
                  const SizedBox(height: 20),
                  Text(episode.description!),
                ],
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
    return Icon(_cachedEpisode == null ? Icons.download : Icons.delete_outline);
  }

  String _cacheLabel() {
    if (_checkingCache) return '检查缓存';
    if (_caching) {
      return _cachedEpisode == null ? '缓存中' : '删除中';
    }
    if (_cachedEpisode == null) return '缓存到本地';
    return '删除缓存 (${_formatBytes(_cachedEpisode!.bytes)})';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    return '${(mb / 1024).toStringAsFixed(1)} GB';
  }

  List<PodcastShow> _dedupeShows(List<PodcastShow> shows) {
    final seen = <String>{};
    return [
      for (final show in shows)
        if (seen.add(show.id)) show,
    ];
  }

  IconData _showIcon(PodcastShow show) {
    if (show.sourceType == SourceType.bilibili &&
        (show.id.startsWith('bili-season') || show.episodes.length > 1)) {
      return Icons.video_collection_outlined;
    }
    if (show.id.startsWith('bili-up')) {
      return Icons.person_outline;
    }
    return Icons.podcasts;
  }

  String _showEntryLabel(PodcastShow show) {
    if (show.sourceType == SourceType.bilibili &&
        (show.id.startsWith('bili-season') || show.episodes.length > 1)) {
      return '合集';
    }
    if (show.id.startsWith('bili-up')) {
      return 'UP主';
    }
    return '播客';
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class EpisodeScreenArgs {
  const EpisodeScreenArgs({
    required this.episode,
    this.relatedShows = const [],
  });

  final Episode episode;
  final List<PodcastShow> relatedShows;
}
