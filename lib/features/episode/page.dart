import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/app_logger.dart';
import '../../core/display_formatters.dart';
import '../../core/plain_text.dart';
import '../../core/app_layout.dart';
import '../../shared/wigets/app_bar.dart';
import '../../shared/wigets/app_detail.dart';
import '../downloads/repository.dart';
import '../downloads/model.dart';
import '../player/services/playback_queue.dart';
import '../player/services/controller.dart';
import '../series/model.dart';
import 'model.dart';

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
  bool _checkingDownload = true;
  bool _caching = false;
  DownloadedEpisode? _downloadedEpisode;

  @override
  void initState() {
    super.initState();
    _loadDownloadsState();
  }

  Future<void> _loadDownloadsState() async {
    try {
      final downloaded = await ref
          .read(episodeDownloadRepositoryProvider)
          .downloadedEpisode(widget.episode.id);
      if (mounted) {
        setState(() {
          _downloadedEpisode = downloaded;
          _checkingDownload = false;
        });
      }
    } catch (error, stackTrace) {
      AppLogger.failure(
        'load_download_state',
        error,
        area: 'download',
        stackTrace: stackTrace,
        data: {'episodeId': widget.episode.id},
      );
      if (mounted) {
        setState(() => _checkingDownload = false);
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

  Future<void> _pause() async {
    AppLogger.userAction(
      'pause_from_episode',
      area: 'player',
      data: {'episodeId': widget.episode.id, 'title': widget.episode.title},
    );
    await ref.read(appPlayerProvider).pause();
  }

  Future<void> _downloadEpisode() async {
    setState(() => _caching = true);
    try {
      final downloaded = await ref
          .read(episodeDownloadRepositoryProvider)
          .download(widget.episode);
      if (mounted) {
        setState(() => _downloadedEpisode = downloaded);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已下载到本地')));
      }
    } catch (error, stackTrace) {
      AppLogger.failure(
        'download_episode',
        error,
        area: 'download',
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
      appBar: AppPageBar(title: episode.sourceType.label),
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
                      AppDetail(
                        title: episode.title,
                        coverUrl: episode.imageUrl,
                        coverIcon: Icons.music_note,
                        metadata: metaParts.join(' · '),
                        subtitle: relatedSeries.isNotEmpty
                            ? _RelatedSeriesLinks(
                                episode: episode,
                                series: relatedSeries,
                              )
                            : Text(
                                episode.author ?? episode.sourceType.label,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                        actions: Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                icon: Icon(
                                  isQueued
                                      ? Icons.playlist_add_check_rounded
                                      : Icons.playlist_add,
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
                                            .read(
                                              playbackQueueProvider.notifier,
                                            )
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
                              tooltip: _downloadTooltip(),
                              icon: _downloadIcon(),
                              onPressed:
                                  _checkingDownload ||
                                      _caching ||
                                      _downloadedEpisode != null
                                  ? null
                                  : _downloadEpisode,
                            ),
                            const SizedBox(width: 8),
                            _EpisodePlayButton(
                              loading: _loading,
                              isCurrent: isCurrent,
                              onPlay: _play,
                              onPause: _pause,
                            ),
                          ],
                        ),
                        actionStatus: _downloadedEpisode == null
                            ? null
                            : Text(
                                '已下载 ${_formatBytes(_downloadedEpisode!.bytes)}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                        description: description,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _downloadIcon() {
    if (_checkingDownload || _caching) {
      return const SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Icon(
      _downloadedEpisode == null
          ? Icons.download
          : Icons.file_download_done_rounded,
    );
  }

  String _downloadTooltip() {
    if (_checkingDownload) return '检查下载';
    if (_caching) {
      return _downloadedEpisode == null ? '下载中' : '读取下载';
    }
    if (_downloadedEpisode == null) return '下载到本地';
    return '已下载 (${_formatBytes(_downloadedEpisode!.bytes)})';
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

class _EpisodePlayButton extends ConsumerWidget {
  const _EpisodePlayButton({
    required this.loading,
    required this.isCurrent,
    required this.onPlay,
    required this.onPause,
  });

  final bool loading;
  final bool isCurrent;
  final VoidCallback onPlay;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(appPlayerProvider);
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final processingState =
            state?.processingState ?? player.processingState;
        final buffering =
            processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering;
        final playing = isCurrent && (state?.playing ?? player.playing);
        final busy = loading || (isCurrent && buffering && !playing);
        return IconButton.filled(
          tooltip: busy ? '准备播放' : (playing ? '暂停' : '播放'),
          icon: busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(playing ? Icons.pause_rounded : Icons.play_arrow),
          onPressed: busy ? null : (playing ? onPause : onPlay),
        );
      },
    );
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
