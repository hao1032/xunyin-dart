import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/logging/app_logger.dart';
import '../../core/formatters/audio_formatters.dart';
import '../audio/list_item.dart';
import '../player/services/playback_queue.dart';
import '../player/services/controller.dart';
import '../player/pages/mini.dart';
import 'repository.dart';
import 'model.dart';

class CacheManagementPage extends ConsumerStatefulWidget {
  const CacheManagementPage({super.key});

  @override
  ConsumerState<CacheManagementPage> createState() =>
      _CacheManagementPageState();
}

class _CacheManagementPageState extends ConsumerState<CacheManagementPage> {
  late Future<List<CachedEpisode>> _cacheFuture;

  @override
  void initState() {
    super.initState();
    _cacheFuture = _loadCache();
  }

  Future<List<CachedEpisode>> _loadCache() {
    return ref.read(audioCacheRepositoryProvider).cachedEpisodes();
  }

  void _reloadCache() {
    setState(() => _cacheFuture = _loadCache());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('缓存管理')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<CachedEpisode>>(
              future: _cacheFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final cached = snapshot.data ?? const <CachedEpisode>[];
                if (cached.isEmpty) {
                  return const Center(child: Text('暂无缓存'));
                }
                final totalBytes = cached.fold<int>(
                  0,
                  (sum, item) => sum + item.bytes,
                );
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        '${cached.length} 个单集 · ${_formatBytes(totalBytes)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    ...cached.map(
                      (item) => AudioListItem(
                        coverUrl: item.episode.imageUrl,
                        title: item.episode.title,
                        metadata: [
                          if (item.episode.publishedAt != null)
                            formatRelativeDate(item.episode.publishedAt!),
                          if (item.episode.duration != null)
                            formatDuration(item.episode.duration!),
                          item.episode.author ?? item.episode.sourceType.label,
                          _formatBytes(item.bytes),
                        ].join(' · '),
                        onTap: () =>
                            context.push('/episode', extra: item.episode),
                        actions: [
                          IconButton(
                            tooltip: '加入播放列表',
                            icon: const Icon(Icons.playlist_add),
                            onPressed: () {
                              ref
                                  .read(playbackQueueProvider.notifier)
                                  .add(item.episode);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('已加入播放列表')),
                              );
                            },
                          ),
                          IconButton(
                            tooltip: '已缓存',
                            icon: const Icon(Icons.offline_pin),
                            onPressed: null,
                          ),
                          IconButton(
                            tooltip: '播放缓存',
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () => _playCached(item),
                          ),
                          IconButton(
                            tooltip: '删除缓存',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removeCached(item),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }

  Future<void> _playCached(CachedEpisode cached) async {
    try {
      await ref.read(playbackControllerProvider).play(cached.episode);
    } catch (error, stackTrace) {
      AppLogger.failure(
        'play_cached_from_cache_management',
        error,
        area: 'cache',
        stackTrace: stackTrace,
        data: {'episodeId': cached.episode.id},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _removeCached(CachedEpisode cached) async {
    await ref.read(audioCacheRepositoryProvider).remove(cached.episode.id);
    if (!mounted) return;
    _reloadCache();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已删除缓存')));
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    return '${(mb / 1024).toStringAsFixed(1)} GB';
  }
}
