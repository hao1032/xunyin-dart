import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../player/data/playback_queue.dart';
import '../../player/data/player_controller.dart';
import '../../player/presentation/mini_player.dart';
import '../domain/episode.dart';

class EpisodeScreen extends ConsumerStatefulWidget {
  const EpisodeScreen({super.key, required this.episode});

  final Episode episode;

  @override
  ConsumerState<EpisodeScreen> createState() => _EpisodeScreenState();
}

class _EpisodeScreenState extends ConsumerState<EpisodeScreen> {
  bool _loading = false;

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

  @override
  Widget build(BuildContext context) {
    final episode = widget.episode;
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
                Text(episode.author ?? episode.sourceType.label),
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
}
