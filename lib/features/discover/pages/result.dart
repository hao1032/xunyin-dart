import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_constants.dart';
import '../../../core/app_logger.dart';
import '../../../shared/wigets/app_bar.dart';
import '../../series/model.dart';
import '../../bilibili/services/repository.dart';
import '../../podcast/services/repository.dart';
import '../../episode/model.dart';
import '../../episode/page.dart';
import '../model.dart';

class DiscoverResultPage extends ConsumerStatefulWidget {
  const DiscoverResultPage({super.key, required this.result});

  final SearchResult result;

  @override
  ConsumerState<DiscoverResultPage> createState() => _DiscoverResultPageState();
}

class _DiscoverResultPageState extends ConsumerState<DiscoverResultPage> {
  late Future<EpisodePageArgs> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<EpisodePageArgs> _load() async {
    final result = widget.result;
    if (result.sourceType == SourceType.bilibili) {
      final episodeContext = await ref
          .read(bilibiliRepositoryProvider)
          .resolveEpisodeContext(result);
      return EpisodePageArgs(
        episode: episodeContext.episode,
        relatedSeries: [
          if (episodeContext.collectionSeries != null)
            episodeContext.collectionSeries!,
          if (episodeContext.creatorSeries != null)
            episodeContext.creatorSeries!,
        ],
      );
    }

    if (result.mediaUrl != null && result.mediaUrl!.isNotEmpty) {
      final episode = Episode(
        id: result.id,
        seriesId: _seriesId(result),
        title: result.title,
        sourceType: result.sourceType,
        originalUrl: result.originalUrl,
        description: result.description,
        author: result.seriesTitle ?? result.subtitle,
        imageUrl: result.imageUrl,
        mediaUrl: result.mediaUrl,
        duration: result.duration,
        publishedAt: result.publishedAt,
      );
      final feedUrl = result.feedUrl ?? result.originalUrl;
      final series = RssPodcastSeries(
        id: _seriesId(result),
        title: result.seriesTitle ?? result.subtitle ?? '播客',
        originalUrl: feedUrl,
        author: result.subtitle,
        imageUrl: result.imageUrl,
        feedUrl: feedUrl,
        episodes: [episode],
      );
      return EpisodePageArgs(episode: episode, relatedSeries: [series]);
    }

    final series = await ref
        .read(podcastRepositoryProvider)
        .loadRssSeries(result);
    if (series.episodes.isEmpty) {
      throw StateError('这个播客暂时没有可播放音频');
    }
    return EpisodePageArgs(
      episode: series.episodes.first,
      relatedSeries: [series],
    );
  }

  String _seriesId(SearchResult result) {
    final feedUrl = result.feedUrl;
    if (feedUrl != null && feedUrl.isNotEmpty) return 'rss-$feedUrl';
    return '${result.sourceType.name}-${result.seriesTitle ?? result.subtitle ?? result.id}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EpisodePageArgs>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return EpisodePage(
            episode: snapshot.data!.episode,
            relatedSeries: snapshot.data!.relatedSeries,
          );
        }
        if (snapshot.hasError) {
          AppLogger.failure(
            'open_search_result',
            snapshot.error!,
            area: 'search',
            stackTrace: snapshot.stackTrace,
            data: {
              'id': widget.result.id,
              'source': widget.result.sourceType.name,
            },
          );
          return Scaffold(
            appBar: AppPageBar(title: widget.result.sourceType.label),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(AppIcons.error, size: 40),
                    const SizedBox(height: AppSpacing.item),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      icon: const Icon(AppIcons.refresh),
                      label: const Text(AppText.retry),
                      onPressed: () {
                        setState(() => _loadFuture = _load());
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppPageBar(title: widget.result.sourceType.label),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
