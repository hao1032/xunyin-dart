import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_logger.dart';
import '../../../core/http_client.dart';
import '../../discover/model.dart';
import '../../series/model.dart';
import 'apple_client.dart';
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

  Future<Series> loadRssSeries(SearchResult result) async {
    final feedUrl = result.feedUrl;
    if (feedUrl == null || feedUrl.isEmpty) {
      throw ArgumentError('搜索结果缺少 RSS feedUrl');
    }
    return loadRssFeed(feedUrl, title: result.title);
  }

  Future<Series> loadRssFeed(String feedUrl, {String? title}) async {
    final resolvedFeedUrl = await _resolveFeedUrl(feedUrl);
    AppLogger.result(
      'load_rss_series',
      area: 'podcast',
      message: 'request',
      data: {
        'feedUrl': resolvedFeedUrl,
        if (resolvedFeedUrl != feedUrl) 'originalFeedUrl': feedUrl,
        'title': ?title,
      },
    );
    final response = await _dio.get<Object?>(
      resolvedFeedUrl,
      options: Options(responseType: ResponseType.plain),
    );
    final xml = response.data?.toString() ?? '';
    if (_looksLikeHtml(xml)) {
      throw FormatException('地址返回的是网页，不是 RSS Feed: $resolvedFeedUrl');
    }
    final series = _rssParser.parse(xml, feedUrl: resolvedFeedUrl);
    AppLogger.result(
      'load_rss_series',
      area: 'podcast',
      data: {
        'seriesId': series.id,
        'title': series.title,
        'episodeCount': series.episodes.length,
      },
    );
    return series;
  }

  Future<String> _resolveFeedUrl(String feedUrl) async {
    final resolved = await _appleClient.lookupFeedUrl(feedUrl);
    return resolved ?? feedUrl;
  }

  bool _looksLikeHtml(String body) {
    final text = body.trimLeft().toLowerCase();
    return text.startsWith('<!doctype html') ||
        text.startsWith('<html') ||
        text.contains('<head>');
  }
}
