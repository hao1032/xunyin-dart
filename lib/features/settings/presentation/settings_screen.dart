import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logging/app_logger.dart';
import '../../cache/data/audio_cache_repository.dart';
import '../../cache/domain/cached_episode.dart';
import '../../player/data/player_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.subscriptions_outlined),
              title: const Text('订阅记录'),
              subtitle: const Text('查看已订阅内容和播放历史'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                AppLogger.userAction('open_library', area: 'library');
                context.push('/library');
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_none),
              title: const Text('播放通知'),
              subtitle: const Text('准备好后可在这里管理播放相关偏好'),
              value: true,
              onChanged: null,
            ),
          ),
          const SizedBox(height: 20),
          Text('缓存管理', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FutureBuilder<List<CachedEpisode>>(
            future: _cacheFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.downloading_outlined),
                    title: Text('正在读取缓存'),
                  ),
                );
              }
              final cached = snapshot.data ?? const <CachedEpisode>[];
              if (cached.isEmpty) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.download_done_outlined),
                    title: Text('暂无缓存'),
                    subtitle: Text('缓存后的单集会显示在这里'),
                  ),
                );
              }
              final totalBytes = cached.fold<int>(
                0,
                (sum, item) => sum + item.bytes,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      '${cached.length} 个单集 · ${_formatBytes(totalBytes)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  ...cached.map(
                    (item) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.offline_pin),
                        title: Text(
                          item.episode.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${item.episode.author ?? item.episode.sourceType.label} · ${_formatBytes(item.bytes)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                        onTap: () =>
                            context.push('/episode', extra: item.episode),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('关于寻音'),
              subtitle: const Text('搜索 B站视频与播客，并整理为播放列表'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _playCached(CachedEpisode cached) async {
    try {
      await ref.read(playbackControllerProvider).play(cached.episode);
    } catch (error, stackTrace) {
      AppLogger.failure(
        'play_cached_from_settings',
        error,
        area: 'cache',
        stackTrace: stackTrace,
        data: {'episodeId': cached.episode.id},
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _removeCached(CachedEpisode cached) async {
    await ref.read(audioCacheRepositoryProvider).remove(cached.episode.id);
    if (mounted) {
      _reloadCache();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已删除缓存')));
    }
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
