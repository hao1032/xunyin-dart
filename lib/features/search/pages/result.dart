import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../channel/model.dart';
import '../../bilibili/services/repository.dart';
import '../../podcast/services/repository.dart';
import '../../podcast/model.dart';
import '../../podcast/pages/episode.dart';
import '../model.dart';

class SearchResultPage extends ConsumerStatefulWidget {
  const SearchResultPage({super.key, required this.result});

  final SearchResult result;

  @override
  ConsumerState<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends ConsumerState<SearchResultPage> {
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
        relatedShows: [
          if (episodeContext.collectionShow != null)
            episodeContext.collectionShow!,
          if (episodeContext.creatorShow != null) episodeContext.creatorShow!,
        ],
      );
    }

    if (result.audioUrl != null && result.audioUrl!.isNotEmpty) {
      final episode = Episode(
        id: result.id,
        showId: _showId(result),
        title: result.title,
        sourceType: result.sourceType,
        originalUrl: result.originalUrl,
        description: result.description,
        author: result.showTitle ?? result.subtitle,
        imageUrl: result.imageUrl,
        audioUrl: result.audioUrl,
        duration: result.duration,
        publishedAt: result.publishedAt,
      );
      final feedUrl = result.feedUrl ?? result.originalUrl;
      final show = RssPodcastShow(
        id: _showId(result),
        title: result.showTitle ?? result.subtitle ?? '播客',
        originalUrl: feedUrl,
        author: result.subtitle,
        imageUrl: result.imageUrl,
        feedUrl: feedUrl,
        episodes: [episode],
      );
      return EpisodePageArgs(episode: episode, relatedShows: [show]);
    }

    final show = await ref.read(podcastRepositoryProvider).loadRssShow(result);
    if (show.episodes.isEmpty) {
      throw StateError('这个播客暂时没有可播放音频');
    }
    return EpisodePageArgs(episode: show.episodes.first, relatedShows: [show]);
  }

  String _showId(SearchResult result) {
    final feedUrl = result.feedUrl;
    if (feedUrl != null && feedUrl.isNotEmpty) return 'rss-$feedUrl';
    return '${result.sourceType.name}-${result.showTitle ?? result.subtitle ?? result.id}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EpisodePageArgs>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return EpisodePage(
            episode: snapshot.data!.episode,
            relatedShows: snapshot.data!.relatedShows,
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
            appBar: AppBar(title: Text(widget.result.sourceType.label)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('重试'),
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
          appBar: AppBar(title: Text(widget.result.sourceType.label)),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
