import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_logger.dart';
import '../../../core/app_constants.dart';
import '../../../shared/wigets/app_bar.dart';
import '../../../shared/wigets/app_episode_item.dart';
import '../../downloads/repository.dart';
import '../../episode/model.dart';
import '../../player/services/controller.dart';
import '../../player/services/playback_queue.dart';
import '../repository.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  late Future<List<Episode>> _historyFuture;
  final Set<String> _downloadedEpisodeIds = {};
  final Set<String> _busyEpisodeIds = {};

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
    _loadDownloadedEpisodes();
  }

  Future<List<Episode>> _loadHistory() async {
    final history = await ref.read(settingsRepositoryProvider).history();
    AppLogger.result(
      'load_history',
      area: 'settings',
      data: {'historyCount': history.length},
    );
    return history;
  }

  Future<void> _loadDownloadedEpisodes() async {
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
        'load_history_download_state',
        error,
        area: 'download',
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppPageBar(title: '历史记录'),
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
                    final downloaded = _downloadedEpisodeIds.contains(
                      episode.id,
                    );
                    final busy = _busyEpisodeIds.contains(episode.id);
                    return AppEpisodeItem(
                      episode: episode,
                      subtitle: AppEpisodeItem.subtitleOf(episode),
                      metadata: AppEpisodeItem.metadataOf(episode),
                      isDownloaded: downloaded,
                      isDownloadBusy: busy,
                      onOpen: () => AppLogger.userAction(
                        'open_history_episode',
                        area: 'settings',
                        data: {'episodeId': episode.id, 'title': episode.title},
                      ),
                      onAddToQueue: () {
                        ref.read(playbackQueueProvider.notifier).add(episode);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(AppText.addedToQueueFull),
                          ),
                        );
                      },
                      onDownload: busy || downloaded
                          ? null
                          : () => _toggleDownload(episode),
                      onPlay: () => _playEpisode(episode),
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
        'toggle_history_download',
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
}
