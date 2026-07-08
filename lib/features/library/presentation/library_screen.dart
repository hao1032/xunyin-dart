import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logging/app_logger.dart';
import '../../library/data/library_repository.dart';
import '../../player/presentation/mini_player.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  late Future<void> _loadFuture;
  Object? _data;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<void> _load() async {
    final repo = ref.read(libraryRepositoryProvider);
    final subscriptions = await repo.subscriptions();
    final history = await repo.history();
    AppLogger.result(
      'load_library',
      area: 'library',
      data: {
        'subscriptionCount': subscriptions.length,
        'historyCount': history.length,
      },
    );
    _data = (subscriptions: subscriptions, history: history);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('订阅记录')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _loadFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = _data as ({List subscriptions, List history});
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('订阅', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (data.subscriptions.isEmpty) const Text('还没有订阅'),
                    ...data.subscriptions.map((show) {
                      return Card(
                        child: ListTile(
                          title: Text(show.title),
                          subtitle: Text('${show.episodes.length} 集'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            AppLogger.userAction(
                              'open_subscription',
                              area: 'library',
                              data: {
                                'showId': show.id,
                                'title': show.title,
                                'episodeCount': show.episodes.length,
                              },
                            );
                            context.push('/show', extra: show);
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    Text('历史', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (data.history.isEmpty) const Text('还没有播放记录'),
                    ...data.history.map((episode) {
                      return Card(
                        child: ListTile(
                          title: Text(episode.title),
                          subtitle: Text(
                            episode.author ?? episode.sourceType.label,
                          ),
                          trailing: const Icon(Icons.play_arrow),
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
                        ),
                      );
                    }),
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
}
