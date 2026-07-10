import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../audio/presentation/audio_list_item.dart';
import '../../cache/data/audio_cache_repository.dart';
import '../../podcast/domain/episode.dart';
import '../data/playback_queue.dart';
import '../data/player_controller.dart';
import 'mini_player.dart';

class QueueScreen extends ConsumerStatefulWidget {
  const QueueScreen({super.key, this.showMiniPlayer = true});

  final bool showMiniPlayer;

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  final Set<String> _cachedEpisodeIds = {};
  final Set<String> _busyEpisodeIds = {};

  @override
  void initState() {
    super.initState();
    _loadCachedEpisodes();
  }

  Future<void> _loadCachedEpisodes() async {
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
        'load_queue_cache_state',
        error,
        area: 'cache',
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(playbackQueueProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('播放列表'),
        actions: [
          IconButton(
            tooltip: '清空',
            icon: const Icon(Icons.clear_all),
            onPressed: queue.items.isEmpty
                ? null
                : () {
                    AppLogger.userAction(
                      'clear_queue',
                      area: 'player',
                      data: {'queueCount': queue.items.length},
                    );
                    ref.read(playbackQueueProvider.notifier).clear();
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: queue.items.isEmpty
                ? const Center(child: Text('播放列表为空'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: queue.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = queue.items[index];
                      final selected =
                          queue.current != null &&
                          entry.containsEpisode(queue.current!.id);
                      if (entry.type == PlaybackQueueEntryType.show) {
                        return _ShowQueueCard(
                          entry: entry,
                          selected: selected,
                          currentEpisodeId: queue.current?.id,
                          cachedEpisodeIds: _cachedEpisodeIds,
                          busyEpisodeIds: _busyEpisodeIds,
                          onPlayEpisode: (episode, childIndex) => _playEpisode(
                            context,
                            episode,
                            index: index,
                            childIndex: childIndex,
                          ),
                          onToggleCache: _toggleCache,
                        );
                      }
                      final episode = entry.episodes.first;
                      return AudioListItem(
                        coverUrl: episode.imageUrl,
                        title: entry.title,
                        metadata: _queueSubtitle(
                          episode,
                          cached: _cachedEpisodeIds.contains(episode.id),
                          fallback: entry.subtitle,
                        ),
                        onTap: () =>
                            _playEpisode(context, episode, index: index),
                        actions: [
                          _CacheIconButton(
                            cached: _cachedEpisodeIds.contains(episode.id),
                            busy: _busyEpisodeIds.contains(episode.id),
                            onPressed: () => _toggleCache(episode),
                          ),
                          IconButton(
                            tooltip: selected ? '正在播放' : '播放',
                            icon: selected
                                ? const _PlayingBars()
                                : const Icon(Icons.play_arrow),
                            onPressed: () =>
                                _playEpisode(context, episode, index: index),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          if (widget.showMiniPlayer) const MiniPlayer(),
        ],
      ),
    );
  }

  String _queueSubtitle(
    Episode episode, {
    required bool cached,
    String? fallback,
  }) {
    final parts = <String>[
      if (cached) '已缓存',
      if (episode.duration != null) formatAudioDuration(episode.duration!),
      fallback ?? episode.author ?? episode.sourceType.label,
    ];
    return parts.join(' · ');
  }

  Future<void> _playEpisode(
    BuildContext context,
    Episode episode, {
    required int index,
    int? childIndex,
  }) async {
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
        'toggle_queue_cache',
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
}

class _ShowQueueCard extends StatelessWidget {
  const _ShowQueueCard({
    required this.entry,
    required this.selected,
    required this.currentEpisodeId,
    required this.cachedEpisodeIds,
    required this.busyEpisodeIds,
    required this.onPlayEpisode,
    required this.onToggleCache,
  });

  final PlaybackQueueEntry entry;
  final bool selected;
  final String? currentEpisodeId;
  final Set<String> cachedEpisodeIds;
  final Set<String> busyEpisodeIds;
  final void Function(Episode episode, int childIndex) onPlayEpisode;
  final ValueChanged<Episode> onToggleCache;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        leading: _QueueCover(url: entry.episodes.first.imageUrl),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.subtitle ?? '合集',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: selected ? '正在播放' : '播放',
                  icon: selected
                      ? const _PlayingBars()
                      : const Icon(Icons.play_arrow),
                  onPressed: () => onPlayEpisode(entry.episodes.first, 0),
                ),
              ],
            ),
          ],
        ),
        children: [
          for (
            var episodeIndex = 0;
            episodeIndex < entry.episodes.length;
            episodeIndex++
          )
            _ShowEpisodeTile(
              episode: entry.episodes[episodeIndex],
              episodeIndex: episodeIndex,
              current: entry.episodes[episodeIndex].id == currentEpisodeId,
              cached: cachedEpisodeIds.contains(
                entry.episodes[episodeIndex].id,
              ),
              busy: busyEpisodeIds.contains(entry.episodes[episodeIndex].id),
              onPlay: () =>
                  onPlayEpisode(entry.episodes[episodeIndex], episodeIndex),
              onToggleCache: () => onToggleCache(entry.episodes[episodeIndex]),
            ),
        ],
      ),
    );
  }
}

class _ShowEpisodeTile extends StatelessWidget {
  const _ShowEpisodeTile({
    required this.episode,
    required this.episodeIndex,
    required this.current,
    required this.cached,
    required this.busy,
    required this.onPlay,
    required this.onToggleCache,
  });

  final Episode episode;
  final int episodeIndex;
  final bool current;
  final bool cached;
  final bool busy;
  final VoidCallback onPlay;
  final VoidCallback onToggleCache;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: AudioListItem(
        coverUrl: episode.imageUrl,
        coverSize: 44,
        title: episode.title,
        metadata: [
          if (cached) '已缓存',
          if (episode.duration != null) formatAudioDuration(episode.duration!),
          episode.author ?? episode.sourceType.label,
        ].join(' · '),
        onTap: onPlay,
        actions: [
          _CacheIconButton(
            cached: cached,
            busy: busy,
            onPressed: onToggleCache,
          ),
          IconButton(
            tooltip: current ? '正在播放' : '播放',
            icon: current ? const _PlayingBars() : const Icon(Icons.play_arrow),
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}

class _CacheIconButton extends StatelessWidget {
  const _CacheIconButton({
    required this.cached,
    required this.busy,
    required this.onPressed,
  });

  final bool cached;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return IconButton(
        tooltip: cached ? '已缓存' : '缓存中',
        onPressed: null,
        icon: const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return IconButton(
      tooltip: cached ? '已缓存' : '缓存到本地',
      icon: Icon(cached ? Icons.offline_pin : Icons.download_outlined),
      onPressed: cached ? null : onPressed,
    );
  }
}

class _QueueCover extends StatelessWidget {
  const _QueueCover({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox.square(
        dimension: 56,
        child: url == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.podcasts),
              )
            : Image.network(url!, fit: BoxFit.cover),
      ),
    );
  }
}

class _PlayingBars extends StatefulWidget {
  const _PlayingBars();

  @override
  State<_PlayingBars> createState() => _PlayingBarsState();
}

class _PlayingBarsState extends State<_PlayingBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 24,
          height: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bar(color, 8 + 8 * _controller.value),
              const SizedBox(width: 3),
              _bar(color, 16 - 6 * _controller.value),
              const SizedBox(width: 3),
              _bar(color, 10 + 10 * _controller.value),
            ],
          ),
        );
      },
    );
  }

  Widget _bar(Color color, double height) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
