import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_logger.dart';
import '../../core/display_formatters.dart';
import '../../shared/wigets/app_list_item.dart';
import '../player/services/playback_queue.dart';
import '../player/services/controller.dart';
import '../player/pages/mini.dart';
import 'repository.dart';
import 'model.dart';

class DownloadsPage extends ConsumerStatefulWidget {
  const DownloadsPage({super.key});

  @override
  ConsumerState<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends ConsumerState<DownloadsPage> {
  late Future<List<DownloadedEpisode>> _downloadsFuture;

  @override
  void initState() {
    super.initState();
    _downloadsFuture = _loadDownloads();
  }

  Future<List<DownloadedEpisode>> _loadDownloads() {
    return ref.read(episodeDownloadRepositoryProvider).downloadedEpisodes();
  }

  void _reloadDownloads() {
    setState(() => _downloadsFuture = _loadDownloads());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('下载管理')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<DownloadedEpisode>>(
              future: _downloadsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final downloaded = snapshot.data ?? const <DownloadedEpisode>[];
                if (downloaded.isEmpty) {
                  return const Center(child: Text('暂无下载'));
                }
                final totalBytes = downloaded.fold<int>(
                  0,
                  (sum, item) => sum + item.bytes,
                );
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        '${downloaded.length} 个单集 · ${_formatBytes(totalBytes)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    ...downloaded.map(
                      (item) => AppListItem(
                        coverUrl: item.episode.imageUrl,
                        title: item.episode.title,
                        subtitle: [
                          item.episode.author ?? item.episode.sourceType.label,
                          _formatBytes(item.bytes),
                        ].join(' · '),
                        metadata: [
                          if (item.episode.publishedAt != null)
                            formatRelativeDate(item.episode.publishedAt!),
                          if (item.episode.duration != null)
                            formatDuration(item.episode.duration!),
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
                            tooltip: '已下载',
                            icon: const Icon(Icons.offline_pin),
                            onPressed: null,
                          ),
                          IconButton(
                            tooltip: '播放下载',
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () => _playDownloaded(item),
                          ),
                          IconButton(
                            tooltip: '删除下载',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removeDownloaded(item),
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

  Future<void> _playDownloaded(DownloadedEpisode downloaded) async {
    try {
      await ref.read(playbackControllerProvider).play(downloaded.episode);
    } catch (error, stackTrace) {
      AppLogger.failure(
        'play_downloaded_from_download_management',
        error,
        area: 'download',
        stackTrace: stackTrace,
        data: {'episodeId': downloaded.episode.id},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _removeDownloaded(DownloadedEpisode downloaded) async {
    await ref
        .read(episodeDownloadRepositoryProvider)
        .remove(downloaded.episode.id);
    if (!mounted) return;
    _reloadDownloads();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已删除下载')));
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
