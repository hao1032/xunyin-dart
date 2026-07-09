import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logging/app_logger.dart';
import '../../player/presentation/mini_player.dart';
import '../../podcast/domain/episode.dart';
import '../data/library_repository.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late Future<List<Episode>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<List<Episode>> _loadHistory() async {
    final history = await ref.read(libraryRepositoryProvider).history();
    AppLogger.result(
      'load_history',
      area: 'library',
      data: {'historyCount': history.length},
    );
    return history;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('历史记录')),
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
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(
                          episode.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          episode.author ?? episode.sourceType.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  },
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
