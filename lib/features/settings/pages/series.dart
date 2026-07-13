import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_logger.dart';
import '../../../core/app_constants.dart';
import '../../../shared/wigets/app_bar.dart';
import '../../../shared/wigets/app_episode_item.dart';
import '../../episode/model.dart';
import '../../series/model.dart';
import '../repository.dart';

class SeriesPage extends ConsumerStatefulWidget {
  const SeriesPage({super.key});

  @override
  ConsumerState<SeriesPage> createState() => _SeriesPageState();
}

class _SeriesPageState extends ConsumerState<SeriesPage> {
  late Future<List<Series>> _subscriptionsFuture;

  @override
  void initState() {
    super.initState();
    _subscriptionsFuture = _loadSubscriptions();
  }

  Future<List<Series>> _loadSubscriptions() async {
    final subscriptions = await ref
        .read(settingsRepositoryProvider)
        .subscriptions();
    AppLogger.result(
      'load_subscriptions',
      area: 'settings',
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
      appBar: const AppPageBar(title: '订阅'),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Series>>(
              future: _subscriptionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final subscriptions = snapshot.data ?? const [];
                if (subscriptions.isEmpty) {
                  return const _EmptySeries();
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  itemCount: subscriptions.length,
                  itemBuilder: (context, index) {
                    final series = subscriptions[index];
                    return AppEpisodeItem(
                      episode: _seriesDisplayEpisode(series),
                      placeholderIcon: _seriesIcon(series),
                      subtitle: '${series.label} · ${series.episodes.length} 集',
                      onTap: () {
                        AppLogger.userAction(
                          'open_subscription',
                          area: 'settings',
                          data: {
                            'seriesId': series.id,
                            'title': series.title,
                            'episodeCount': series.episodes.length,
                          },
                        );
                        context.push('/series', extra: series);
                      },
                      onRemove: () => _unsubscribe(series),
                      removeTooltip: '取消订阅',
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

  Future<void> _unsubscribe(Series series) async {
    await ref.read(settingsRepositoryProvider).unsubscribe(series.id);
    if (!mounted) return;
    _reload();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已取消订阅')));
  }

  IconData _seriesIcon(Series series) => switch (series) {
    BilibiliCollectionSeries() => AppIcons.videoLibrary,
    BilibiliCreatorSeries() => AppIcons.userRounded,
    RssPodcastSeries() => AppIcons.podcasts,
  };

  Episode _seriesDisplayEpisode(Series series) {
    final firstEpisode = series.episodes.firstOrNull;
    return Episode(
      id: series.id,
      seriesId: series.id,
      title: series.title,
      sourceType: firstEpisode?.sourceType ?? _seriesSourceType(series),
      originalUrl: series.originalUrl,
      author: series.label,
      imageUrl: series.imageUrl,
    );
  }

  SourceType _seriesSourceType(Series series) => switch (series) {
    BilibiliCollectionSeries() => SourceType.bilibili,
    BilibiliCreatorSeries() => SourceType.bilibili,
    RssPodcastSeries() => SourceType.rss,
  };
}

class _EmptySeries extends StatelessWidget {
  const _EmptySeries();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppInsets.emptyState,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.rss,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppSizes.indicator),
            Text('还没有订阅', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
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
