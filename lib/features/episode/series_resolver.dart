import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_logger.dart';
import '../bilibili/services/repository.dart';
import '../settings/repository.dart';
import '../discover/model.dart';
import '../series/model.dart';
import 'model.dart';

final episodeSeriesResolverProvider = Provider<EpisodeSeriesResolver>((ref) {
  return EpisodeSeriesResolver(
    ref.watch(settingsRepositoryProvider),
    ref.watch(bilibiliRepositoryProvider),
  );
});

class EpisodeSeriesResolver {
  const EpisodeSeriesResolver(this._settings, this._bilibili);

  final SettingsRepository _settings;
  final BilibiliRepository _bilibili;

  Future<Series> resolve(
    Episode episode, {
    Iterable<EpisodeSeriesCandidate> queuedSeries = const [],
  }) async {
    final subscriptions = await _settings.subscriptions();
    final subscribed = subscriptions.where((series) {
      return series.id == episode.seriesId ||
          series.episodes.any((item) => item.id == episode.id);
    }).firstOrNull;
    if (subscribed != null) return subscribed;

    if (episode.sourceType == SourceType.bilibili && episode.bvid != null) {
      final series = await _resolveBilibiliSeries(episode);
      if (series != null) return series;
    }

    final queued = queuedSeries
        .where((series) => series.containsEpisode(episode.id))
        .firstOrNull;
    if (queued != null) {
      return _seriesFromEpisode(
        id: queued.id,
        title: queued.title,
        originalUrl: episode.originalUrl,
        author: episode.author,
        imageUrl: queued.episodes.first.imageUrl ?? episode.imageUrl,
        episodes: queued.episodes,
        episode: episode,
      );
    }

    return _seriesFromEpisode(
      id: episode.seriesId,
      title: episode.author ?? episode.sourceType.label,
      originalUrl: episode.originalUrl,
      author: episode.author,
      imageUrl: episode.imageUrl,
      episodes: [episode],
      episode: episode,
    );
  }

  Series _seriesFromEpisode({
    required String id,
    required String title,
    required String originalUrl,
    required String? author,
    required String? imageUrl,
    required List<Episode> episodes,
    required Episode episode,
  }) {
    if (episode.sourceType != SourceType.bilibili) {
      return RssPodcastSeries(
        id: id,
        title: title,
        originalUrl: originalUrl,
        feedUrl: _rssFeedUrl(episode) ?? originalUrl,
        author: author,
        imageUrl: imageUrl,
        episodes: episodes,
      );
    }
    if (episode.seriesId.startsWith('bili-up-')) {
      return BilibiliCreatorSeries(
        id: id,
        title: title,
        originalUrl: originalUrl,
        author: author,
        imageUrl: imageUrl,
        episodes: episodes,
      );
    }
    return BilibiliCollectionSeries(
      id: id,
      title: title,
      originalUrl: originalUrl,
      author: author,
      imageUrl: imageUrl,
      episodes: episodes,
    );
  }

  Future<Series?> _resolveBilibiliSeries(Episode episode) async {
    try {
      final context = await _bilibili.resolveEpisodeContext(
        SearchResult(
          id: episode.id,
          title: episode.title,
          sourceType: episode.sourceType,
          originalUrl: episode.originalUrl,
          imageUrl: episode.imageUrl,
          duration: episode.duration,
          publishedAt: episode.publishedAt,
          bvid: episode.bvid,
        ),
      );
      final collection = context.collectionSeries;
      if (collection != null && collection.id == episode.seriesId) {
        return collection;
      }
      if (episode.seriesId.startsWith('bili-season-') && collection != null) {
        return collection;
      }
      return context.creatorSeries;
    } catch (error, stackTrace) {
      AppLogger.failure(
        'resolve_episode_series',
        error,
        area: 'episode',
        stackTrace: stackTrace,
        data: {'episodeId': episode.id, 'bvid': episode.bvid},
      );
      return null;
    }
  }

  String? _rssFeedUrl(Episode episode) {
    if (episode.sourceType != SourceType.rss) return null;
    if (!episode.seriesId.startsWith('rss-')) return null;
    final feedUrl = episode.seriesId.substring('rss-'.length);
    return feedUrl.isEmpty ? null : feedUrl;
  }
}

class EpisodeSeriesCandidate {
  const EpisodeSeriesCandidate({
    required this.id,
    required this.title,
    required this.episodes,
  });

  final String id;
  final String title;
  final List<Episode> episodes;

  bool containsEpisode(String episodeId) {
    return episodes.any((episode) => episode.id == episodeId);
  }
}
