import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logging/app_logger.dart';
import '../../audio/list_item.dart';
import '../../channel/model.dart';
import '../../player/pages/mini.dart';
import '../repository.dart';

class ChannelsPage extends ConsumerStatefulWidget {
  const ChannelsPage({super.key});

  @override
  ConsumerState<ChannelsPage> createState() => _ChannelsPageState();
}

class _ChannelsPageState extends ConsumerState<ChannelsPage> {
  late Future<List<AudioShow>> _subscriptionsFuture;

  @override
  void initState() {
    super.initState();
    _subscriptionsFuture = _loadSubscriptions();
  }

  Future<List<AudioShow>> _loadSubscriptions() async {
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
      appBar: AppBar(title: const Text('我的频道')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<AudioShow>>(
              future: _subscriptionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final subscriptions = snapshot.data ?? const [];
                if (subscriptions.isEmpty) {
                  return const _EmptyChannels();
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: subscriptions.length,
                  itemBuilder: (context, index) {
                    final show = subscriptions[index];
                    return AudioListItem(
                      coverUrl: show.imageUrl,
                      placeholderIcon: _channelIcon(show),
                      title: show.title,
                      metadata: '${show.label} · ${show.episodes.length} 集',
                      actions: [
                        IconButton(
                          tooltip: '取消订阅',
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                          onPressed: () => _unsubscribe(show),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
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
                        context.push('/channel', extra: show);
                      },
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

  Future<void> _unsubscribe(AudioShow show) async {
    await ref.read(libraryRepositoryProvider).unsubscribe(show.id);
    if (!mounted) return;
    _reload();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已取消订阅')));
  }

  IconData _channelIcon(AudioShow show) => switch (show) {
    BilibiliCollectionShow() => Icons.video_library_rounded,
    BilibiliCreatorShow() => Icons.person_rounded,
    RssPodcastShow() => Icons.podcasts_rounded,
  };
}

class _EmptyChannels extends StatelessWidget {
  const _EmptyChannels();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rss_feed_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 18),
            Text('还没有频道', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              '搜索 B站内容或播客，然后订阅合集、UP主或 RSS 播客。',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
