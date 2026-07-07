import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../podcast/domain/episode.dart';
import '../data/playback_queue.dart';
import '../data/player_controller.dart';
import 'mini_player.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                        return Card(
                          child: ExpansionTile(
                            leading: Icon(
                              selected
                                  ? Icons.graphic_eq
                                  : Icons.featured_play_list_outlined,
                            ),
                            title: Text(
                              entry.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              entry.subtitle ?? '合集',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              tooltip: '移除',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                AppLogger.userAction(
                                  'remove_queue_entry',
                                  area: 'player',
                                  data: {
                                    'entryId': entry.id,
                                    'title': entry.title,
                                    'type': entry.type.name,
                                  },
                                );
                                ref
                                    .read(playbackQueueProvider.notifier)
                                    .remove(entry.id);
                              },
                            ),
                            children: [
                              for (
                                var episodeIndex = 0;
                                episodeIndex < entry.episodes.length;
                                episodeIndex++
                              )
                                ListTile(
                                  dense: true,
                                  leading: Text('${episodeIndex + 1}'),
                                  title: Text(
                                    entry.episodes[episodeIndex].title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing:
                                      entry.episodes[episodeIndex].id ==
                                          queue.current?.id
                                      ? const Icon(Icons.graphic_eq)
                                      : const Icon(Icons.play_arrow),
                                  onTap: () => _playEpisode(
                                    context,
                                    ref,
                                    entry.episodes[episodeIndex],
                                    index: index,
                                    childIndex: episodeIndex,
                                  ),
                                ),
                            ],
                          ),
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
                            entry.subtitle ?? episode.sourceType.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            tooltip: '移除',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              AppLogger.userAction(
                                'remove_queue_entry',
                                area: 'player',
                                data: {
                                  'entryId': entry.id,
                                  'title': entry.title,
                                  'type': entry.type.name,
                                },
                              );
                              ref
                                  .read(playbackQueueProvider.notifier)
                                  .remove(entry.id);
                            },
                          ),
                          onTap: () =>
                              _playEpisode(context, ref, episode, index: index),
                        ),
                      );
                    },
                  ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }

  Future<void> _playEpisode(
    BuildContext context,
    WidgetRef ref,
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
}
