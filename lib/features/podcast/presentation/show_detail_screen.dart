import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logging/app_logger.dart';
import '../../library/data/library_repository.dart';
import '../../player/data/playback_queue.dart';
import '../../player/presentation/mini_player.dart';
import '../domain/podcast_show.dart';

class ShowDetailScreen extends ConsumerWidget {
  const ShowDetailScreen({super.key, required this.show});

  final PodcastShow show;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(show.sourceType.label),
        actions: [
          IconButton(
            tooltip: '订阅',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              AppLogger.userAction(
                'subscribe_show',
                area: 'library',
                data: {
                  'showId': show.id,
                  'title': show.title,
                  'episodeCount': show.episodes.length,
                },
              );
              await ref.read(libraryRepositoryProvider).subscribe(show);
              AppLogger.result(
                'subscribe_show',
                area: 'library',
                data: {'showId': show.id, 'title': show.title},
              );
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('已加入订阅')));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShowCover(url: show.imageUrl),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            show.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(show.author ?? show.sourceType.label),
                          const SizedBox(height: 8),
                          Text('${show.episodes.length} 集'),
                        ],
                      ),
                    ),
                  ],
                ),
                if (show.description != null &&
                    show.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    show.description!,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('加入播放列表'),
                  onPressed: show.episodes.isEmpty
                      ? null
                      : () {
                          AppLogger.userAction(
                            'add_show_to_queue',
                            area: 'player',
                            data: {
                              'showId': show.id,
                              'title': show.title,
                              'episodeCount': show.episodes.length,
                            },
                          );
                          ref
                              .read(playbackQueueProvider.notifier)
                              .addShow(show);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已加入播放列表')),
                          );
                        },
                ),
                const SizedBox(height: 20),
                Text('单集', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...show.episodes.map((episode) {
                  return Card(
                    child: ListTile(
                      title: Text(episode.title),
                      subtitle: Text(episode.author ?? show.title),
                      trailing: IconButton(
                        tooltip: '加入播放列表',
                        icon: const Icon(Icons.playlist_add),
                        onPressed: () {
                          AppLogger.userAction(
                            'add_episode_to_queue',
                            area: 'player',
                            data: {
                              'episodeId': episode.id,
                              'title': episode.title,
                              'showId': show.id,
                            },
                          );
                          ref.read(playbackQueueProvider.notifier).add(episode);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已加入播放列表')),
                          );
                        },
                      ),
                      onTap: () {
                        AppLogger.userAction(
                          'open_episode',
                          area: 'podcast',
                          data: {
                            'episodeId': episode.id,
                            'title': episode.title,
                            'showId': show.id,
                          },
                        );
                        context.push('/episode', extra: episode);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}

class _ShowCover extends StatelessWidget {
  const _ShowCover({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(
        dimension: 108,
        child: url == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.podcasts, size: 40),
              )
            : Image.network(url!, fit: BoxFit.cover),
      ),
    );
  }
}
