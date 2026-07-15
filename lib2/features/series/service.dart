import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bilibili/services/repository.dart';
import '../podcast/services/repository.dart';
import 'model.dart';

final seriesServiceProvider = Provider<SeriesService>((ref) {
  return SeriesService(
    ref.watch(bilibiliRepositoryProvider),
    ref.watch(podcastRepositoryProvider),
  );
});

/// Loads any supported series through one platform-independent entry point.
class SeriesService {
  const SeriesService(this._bilibili, this._podcast);

  final BilibiliRepository _bilibili;
  final PodcastRepository _podcast;

  Future<Series> load(Series series, {int page = 1, int pageSize = 10}) {
    return switch (series) {
      BilibiliCreatorSeries() => _bilibili.loadCreatorSeries(
        series,
        page: page,
        pageSize: pageSize,
      ),
      RssPodcastSeries() => _loadRss(series),
      BilibiliCollectionSeries() => Future.value(series),
    };
  }

  Future<Series> _loadRss(RssPodcastSeries series) {
    final feedUrl = series.feedUrl;
    if (feedUrl.isEmpty) return Future.value(series);
    return _podcast.loadRssFeed(feedUrl, title: series.title);
  }
}
