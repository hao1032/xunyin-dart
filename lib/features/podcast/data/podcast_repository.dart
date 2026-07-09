import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/network/http_client.dart';
import '../../search/domain/search_result.dart';
import '../domain/podcast_show.dart';
import 'apple_podcast_client.dart';
import 'rss_parser.dart';

final podcastRepositoryProvider = Provider<PodcastRepository>((ref) {
  return PodcastRepository(
    ref.watch(applePodcastClientProvider),
    ref.watch(dioProvider),
    RssParser(),
  );
});

class PodcastRepository {
  const PodcastRepository(this._appleClient, this._dio, this._rssParser);

  final ApplePodcastClient _appleClient;
  final Dio _dio;
  final RssParser _rssParser;

  Future<List<SearchResult>> searchApple(String keyword) {
    return _appleClient.search(keyword);
  }

  Future<PodcastShow> loadRssShow(SearchResult result) async {
    final feedUrl = result.feedUrl;
    if (feedUrl == null || feedUrl.isEmpty) {
      throw ArgumentError('搜索结果缺少 RSS feedUrl');
    }
    return loadRssFeed(feedUrl, title: result.title);
  }

  Future<PodcastShow> loadRssFeed(String feedUrl, {String? title}) async {
    AppLogger.result(
      'load_rss_show',
      area: 'podcast',
      message: 'request',
      data: {'feedUrl': feedUrl, 'title': ?title},
    );
    final response = await _dio.get<Object?>(
      feedUrl,
      options: Options(responseType: ResponseType.plain),
    );
    final xml = response.data?.toString() ?? '';
    final show = _rssParser.parse(xml, feedUrl: feedUrl);
    AppLogger.result(
      'load_rss_show',
      area: 'podcast',
      data: {
        'showId': show.id,
        'title': show.title,
        'episodeCount': show.episodes.length,
      },
    );
    return show;
  }
}
