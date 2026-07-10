import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logging/app_logger.dart';
import '../../audio/presentation/audio_list_item.dart';
import '../../cache/data/audio_cache_repository.dart';
import '../../player/data/playback_queue.dart';
import '../../player/data/player_controller.dart';
import '../../player/presentation/mini_player.dart';
import '../../podcast/domain/episode.dart';
import '../data/library_repository.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late Future<List<Episode>> _historyFuture;
  final Set<String> _cachedEpisodeIds = {};
  final Set<String> _busyEpisodeIds = {};

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
    _loadCachedEpisodes();
  }

  Future<List<Episode>> _loadHistory() async {
    final history = await ref.read(libraryRepositoryProvider).history();
    AppLogger.result(
      'load_history',
      area: 'library',
      data: {'historyCount': history.length},
    );
    return history;
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
        'load_history_cache_state',
        error,
        area: 'cache',
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('历史记录')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Episode>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final history = snapshot.data ?? const [];
                if (history.isEmpty) {
                  return const Center(child: Text('还没有播放记录'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final episode = history[index];
                    final cached = _cachedEpisodeIds.contains(episode.id);
                    final busy = _busyEpisodeIds.contains(episode.id);
                    return AudioListItem(
                      coverUrl: episode.imageUrl,
                      title: episode.title,
                      metadata: [
                        if (episode.publishedAt != null)
                          formatAudioRelativeDate(episode.publishedAt!),
                        if (episode.duration != null)
                          formatAudioDuration(episode.duration!),
                        episode.author ?? episode.sourceType.label,
                      ].join(' · '),
                      onTap: () {
                        AppLogger.userAction(
                          'open_history_episode',
                          area: 'library',
                          data: {
                            'episodeId': episode.id,
                            'title': episode.title,
                          },
                        );
                        context.push('/episode', extra: episode);
                      },
                      actions: [
                        IconButton(
                          tooltip: '加入播放列表',
                          icon: const Icon(Icons.playlist_add),
                          onPressed: () {
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
                              : () => _toggleCache(episode),
                        ),
                        IconButton(
                          tooltip: '播放',
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () => _playEpisode(episode),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }

  Future<void> _playEpisode(Episode episode) async {
    try {
      await ref.read(playbackControllerProvider).play(episode);
    } catch (error, stackTrace) {
      AppLogger.failure(
        'play_history_episode',
        error,
        area: 'player',
        stackTrace: stackTrace,
        data: {'episodeId': episode.id, 'title': episode.title},
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
        'toggle_history_cache',
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
