import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logging/app_logger.dart';
import '../../player/presentation/mini_player.dart';
import '../../podcast/domain/podcast_show.dart';
import '../data/library_repository.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  late Future<List<PodcastShow>> _subscriptionsFuture;

  @override
  void initState() {
    super.initState();
    _subscriptionsFuture = _loadSubscriptions();
  }

  Future<List<PodcastShow>> _loadSubscriptions() async {
    final subscriptions = await ref
        .read(libraryRepositoryProvider)
        .subscriptions();
    AppLogger.result(
      'load_subscriptions',
      area: 'library',
      data: {'subscriptionCount': subscriptions.length},
    );
    return subscriptions;
  }

  void _reload() {
    setState(() => _subscriptionsFuture = _loadSubscriptions());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('订阅')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<PodcastShow>>(
              future: _subscriptionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final subscriptions = snapshot.data ?? const [];
                if (subscriptions.isEmpty) {
                  return const Center(child: Text('还没有订阅'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: subscriptions.length,
                  itemBuilder: (context, index) {
                    final show = subscriptions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.subscriptions_outlined),
                        title: Text(
                          show.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('${show.episodes.length} 集'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: '取消订阅',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _unsubscribe(show),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
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

  Future<void> _unsubscribe(PodcastShow show) async {
    await ref.read(libraryRepositoryProvider).unsubscribe(show.id);
    if (!mounted) return;
    _reload();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已取消订阅')));
  }
}
