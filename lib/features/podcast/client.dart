import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/exceptions.dart';
import '../../core/logging/app_logger.dart';
import 'models.dart';
import 'rss.dart';

class ApplePodcastClient {
  ApplePodcastClient(this._dio, this._logger);

  final Dio _dio;
  final AppLogger _logger;

  Future<List<ApplePodcastResult>> search(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return const [];
    try {
      final response = await _dio.get<dynamic>(
        'https://itunes.apple.com/search',
        queryParameters: {
          'term': trimmed,
          'media': 'podcast',
          // 搜索单集，而不是节目（series）。
          'entity': 'podcastEpisode',
          'limit': 50,
        },
      );
      final rawBody = response.data;
      final body = rawBody is String ? jsonDecode(rawBody) : rawBody;
      final rows = body is Map ? body['results'] : null;
      if (rows is! List) return const [];
      final results = rows
          .whereType<Map>()
          .map(
            (row) => ApplePodcastResult(
              name: '${row['trackName'] ?? row['collectionName'] ?? ''}',
              artist: '${row['artistName'] ?? ''}',
              artworkUrl:
                  '${row['artworkUrl600'] ?? row['artworkUrl100'] ?? ''}',
              detailUrl:
                  '${row['trackViewUrl'] ?? row['collectionViewUrl'] ?? ''}',
              feedUrl: '${row['feedUrl'] ?? ''}',
              collectionId: (row['collectionId'] as num?)?.toInt(),
              episodeId: (row['trackId'] as num?)?.toInt(),
              collectionName: row['collectionName'] as String?,
              publishedAt: _parseDate(row['releaseDate']),
              durationSeconds: _parseDuration(row['trackTimeMillis']),
            ),
          )
          .where((item) => item.name.isNotEmpty && item.feedUrl.isNotEmpty)
          .toList();
      _logger.info(
        'podcast',
        'search_succeeded',
        data: {'count': results.length},
      );
      return results;
    } on DioException catch (error) {
      _logger.warning(
        'podcast',
        'search_failed',
        data: {
          'status_code': error.response?.statusCode,
          'error_type': error.type.name,
        },
      );
      throw DataFetchException('播客搜索失败，请稍后重试', cause: error);
    } on Object catch (error, stackTrace) {
      _logger.error(
        'podcast',
        'parse_failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw DataFetchException('播客搜索数据无法解析', cause: error);
    }
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static int? _parseDuration(Object? value) {
    if (value is num) return (value / 1000).round();
    return null;
  }
}

class RssClient {
  RssClient(this._dio, this._logger);

  final Dio _dio;
  final AppLogger _logger;

  Future<RssFeed> loadFeed(String feedUrl) async {
    try {
      final response = await _dio.get<String>(feedUrl);
      final feed = RssParser.parse(response.data ?? '');
      _logger.info('rss', 'feed_loaded', data: {'count': feed.episodes.length});
      return feed;
    } on DioException catch (error) {
      _logger.warning(
        'rss',
        'load_failed',
        data: {'status_code': error.response?.statusCode},
      );
      throw DataFetchException('RSS 获取失败，请稍后重试', cause: error);
    } on DataFetchException catch (error, stackTrace) {
      _logger.warning(
        'rss',
        'parse_failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } on Object catch (error, stackTrace) {
      _logger.error(
        'rss',
        'parse_failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const DataFetchException('RSS 内容无法解析');
    }
  }
}
