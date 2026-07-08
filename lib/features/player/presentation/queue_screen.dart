import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
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
                          onRemove: () => _removeEntry(entry),
                        );
                      }
                      final episode = entry.episodes.first;
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            selected ? Icons.graphic_eq : Icons.queue_music,
                          ),
                          title: Text(
                            entry.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            _cachedEpisodeIds.contains(episode.id)
                                ? '已缓存 · ${entry.subtitle ?? episode.sourceType.label}'
                                : entry.subtitle ?? episode.sourceType.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _CacheIconButton(
                                cached: _cachedEpisodeIds.contains(episode.id),
                                busy: _busyEpisodeIds.contains(episode.id),
                                onPressed: () => _toggleCache(episode),
                              ),
                              IconButton(
                                tooltip: '移除',
                                icon: const Icon(Icons.close),
                                onPressed: () => _removeEntry(entry),
                              ),
                            ],
                          ),
                          onTap: () =>
                              _playEpisode(context, episode, index: index),
                        ),
                      );
                    },
                  ),
          ),
          if (widget.showMiniPlayer) const MiniPlayer(),
        ],
      ),
    );
  }

  void _removeEntry(PlaybackQueueEntry entry) {
    AppLogger.userAction(
      'remove_queue_entry',
      area: 'player',
      data: {
        'entryId': entry.id,
        'title': entry.title,
        'type': entry.type.name,
      },
    );
    ref.read(playbackQueueProvider.notifier).remove(entry.id);
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
    setState(() => _busyEpisodeIds.add(episode.id));
    try {
      if (_cachedEpisodeIds.contains(episode.id)) {
        await ref.read(audioCacheRepositoryProvider).remove(episode.id);
        if (mounted) {
          setState(() => _cachedEpisodeIds.remove(episode.id));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('已删除缓存')));
        }
      } else {
        await ref.read(audioCacheRepositoryProvider).cache(episode);
        if (mounted) {
          setState(() => _cachedEpisodeIds.add(episode.id));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('已缓存到本地')));
        }
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
    required this.onRemove,
  });

  final PlaybackQueueEntry entry;
  final bool selected;
  final String? currentEpisodeId;
  final Set<String> cachedEpisodeIds;
  final Set<String> busyEpisodeIds;
  final void Function(Episode episode, int childIndex) onPlayEpisode;
  final ValueChanged<Episode> onToggleCache;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: Icon(
          selected ? Icons.graphic_eq : Icons.featured_play_list_outlined,
        ),
        title: Text(entry.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          entry.subtitle ?? '合集',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          tooltip: '移除',
          icon: const Icon(Icons.close),
          onPressed: onRemove,
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
    return ListTile(
      dense: true,
      leading: Text('${episodeIndex + 1}'),
      title: Text(episode.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: cached ? const Text('已缓存') : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CacheIconButton(
            cached: cached,
            busy: busy,
            onPressed: onToggleCache,
          ),
          Icon(current ? Icons.graphic_eq : Icons.play_arrow),
        ],
      ),
      onTap: onPlay,
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
        tooltip: cached ? '删除缓存中' : '缓存中',
        onPressed: null,
        icon: const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return IconButton(
      tooltip: cached ? '已缓存，点击删除' : '缓存到本地',
      icon: Icon(cached ? Icons.offline_pin : Icons.download_outlined),
      onPressed: onPressed,
    );
  }
}
