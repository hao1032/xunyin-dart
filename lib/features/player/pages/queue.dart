import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_logger.dart';
import '../../../core/display_formatters.dart';
import '../../../core/app_layout.dart';
import '../../app_list_item.dart';
import '../../downloads/repository.dart';
import '../../episode/model.dart';
import '../services/playback_queue.dart';
import '../services/controller.dart';
import 'mini.dart';

class QueuePage extends ConsumerStatefulWidget {
  const QueuePage({super.key, this.showMiniPlayer = true});

  final bool showMiniPlayer;

  @override
  ConsumerState<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends ConsumerState<QueuePage> {
  final Set<String> _downloadedEpisodeIds = {};
  final Set<String> _busyEpisodeIds = {};

  @override
  void initState() {
    super.initState();
    _loadDownloadedEpisodes();
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
        'load_queue_download_state',
        error,
        area: 'download',
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
                ? const _EmptyQueue()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: queue.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = queue.items[index];
                      final selected =
                          queue.current != null &&
                          entry.containsEpisode(queue.current!.id);
                      if (entry.type == PlaybackQueueEntryType.series) {
                        return _SeriesQueueCard(
                          entry: entry,
                          selected: selected,
                          currentEpisodeId: queue.current?.id,
                          downloadedEpisodeIds: _downloadedEpisodeIds,
                          busyEpisodeIds: _busyEpisodeIds,
                          onPlayEpisode: (episode, childIndex) => _playEpisode(
                            context,
                            episode,
                            index: index,
                            childIndex: childIndex,
                          ),
                          onToggleDownload: _toggleDownload,
                        );
                      }
                      final episode = entry.episodes.first;
                      return AppListItem(
                        coverUrl: episode.imageUrl,
                        title: entry.title,
                        metadata: _queueSubtitle(
                          episode,
                          downloaded: _downloadedEpisodeIds.contains(
                            episode.id,
                          ),
                          fallback: entry.subtitle,
                        ),
                        onTap: () =>
                            _playEpisode(context, episode, index: index),
                        actions: [
                          _DownloadIconButton(
                            downloaded: _downloadedEpisodeIds.contains(
                              episode.id,
                            ),
                            busy: _busyEpisodeIds.contains(episode.id),
                            onPressed: () => _toggleDownload(episode),
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
    required bool downloaded,
    String? fallback,
  }) {
    final parts = <String>[
      if (downloaded) '已下载',
      if (episode.duration != null) formatDuration(episode.duration!),
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
        ).showSnackBar(const SnackBar(content: Text('已下载到本地')));
      }
    } catch (error, stackTrace) {
      AppLogger.failure(
        'toggle_queue_download',
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

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.queue_music_rounded,
      title: '播放列表还是空的',
      message: '去发现页找一段想听的内容，单集和整个系列都可以加入这里。',
    );
  }
}

class _SeriesQueueCard extends StatelessWidget {
  const _SeriesQueueCard({
    required this.entry,
    required this.selected,
    required this.currentEpisodeId,
    required this.downloadedEpisodeIds,
    required this.busyEpisodeIds,
    required this.onPlayEpisode,
    required this.onToggleDownload,
  });

  final PlaybackQueueEntry entry;
  final bool selected;
  final String? currentEpisodeId;
  final Set<String> downloadedEpisodeIds;
  final Set<String> busyEpisodeIds;
  final void Function(Episode episode, int childIndex) onPlayEpisode;
  final ValueChanged<Episode> onToggleDownload;

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
            _SeriesEpisodeTile(
              episode: entry.episodes[episodeIndex],
              episodeIndex: episodeIndex,
              current: entry.episodes[episodeIndex].id == currentEpisodeId,
              downloaded: downloadedEpisodeIds.contains(
                entry.episodes[episodeIndex].id,
              ),
              busy: busyEpisodeIds.contains(entry.episodes[episodeIndex].id),
              onPlay: () =>
                  onPlayEpisode(entry.episodes[episodeIndex], episodeIndex),
              onToggleDownload: () =>
                  onToggleDownload(entry.episodes[episodeIndex]),
            ),
        ],
      ),
    );
  }
}

class _SeriesEpisodeTile extends StatelessWidget {
  const _SeriesEpisodeTile({
    required this.episode,
    required this.episodeIndex,
    required this.current,
    required this.downloaded,
    required this.busy,
    required this.onPlay,
    required this.onToggleDownload,
  });

  final Episode episode;
  final int episodeIndex;
  final bool current;
  final bool downloaded;
  final bool busy;
  final VoidCallback onPlay;
  final VoidCallback onToggleDownload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: AppListItem(
        coverUrl: episode.imageUrl,
        coverSize: 44,
        title: episode.title,
        metadata: [
          if (downloaded) '已下载',
          if (episode.duration != null) formatDuration(episode.duration!),
          episode.author ?? episode.sourceType.label,
        ].join(' · '),
        onTap: onPlay,
        actions: [
          _DownloadIconButton(
            downloaded: downloaded,
            busy: busy,
            onPressed: onToggleDownload,
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

class _DownloadIconButton extends StatelessWidget {
  const _DownloadIconButton({
    required this.downloaded,
    required this.busy,
    required this.onPressed,
  });

  final bool downloaded;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return IconButton(
        tooltip: downloaded ? '已下载' : '下载中',
        onPressed: null,
        icon: const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return IconButton(
      tooltip: downloaded ? '已下载' : '下载到本地',
      icon: Icon(downloaded ? Icons.offline_pin : Icons.download_outlined),
      onPressed: downloaded ? null : onPressed,
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
