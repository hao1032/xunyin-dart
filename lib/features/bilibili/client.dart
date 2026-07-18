import 'package:dio/dio.dart';

import '../../core/exceptions.dart';
import '../../core/logging/app_logger.dart';
import '../../core/utils.dart';
import 'models.dart';

export 'models.dart';

class BilibiliClient {
  BilibiliClient(this._dio, this._logger);

  final Dio _dio;
  final AppLogger _logger;

  Future<List<BilibiliSearchResult>> searchVideos(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return const [];
    try {
      final options = Options(
        headers: {
          // B站会将没有网页来源的公开 API 请求判定为反爬请求（412）。
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
              'AppleWebKit/537.36 (KHTML, like Gecko) '
              'Chrome/126.0 Safari/537.36',
          'Referer': 'https://www.bilibili.com/',
          'Origin': 'https://www.bilibili.com',
          'Accept': 'application/json, text/plain, */*',
          'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
          'Sec-Fetch-Site': 'same-site',
          'Sec-Fetch-Mode': 'cors',
          'Sec-Fetch-Dest': 'empty',
        },
      );
      Response<Map<String, dynamic>>? response;
      DioException? last412;
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          response = await _dio.get<Map<String, dynamic>>(
            'https://api.bilibili.com/x/web-interface/search/type',
            queryParameters: {
              'search_type': 'video',
              'keyword': trimmed,
              'page': 1,
            },
            options: options,
          );
          last412 = null;
          break;
        } on DioException catch (error) {
          if (error.response?.statusCode != 412 || attempt == 2) rethrow;
          last412 = error;
          await Future<void>.delayed(
            Duration(milliseconds: 300 * (attempt + 1)),
          );
        }
      }
      if (response == null) throw last412!;
      final body = response.data;
      final rows = body?['data']?['result'];
      if (rows is! List) return const [];
      final results = rows
          .whereType<Map>()
          .map((row) {
            final bvid = '${row['bvid'] ?? ''}';
            final cover = '${row['pic'] ?? ''}'.replaceFirst('//', 'https://');
            return BilibiliSearchResult(
              title: stripHtmlTags('${row['title'] ?? ''}'),
              author: '${row['author'] ?? ''}',
              bvid: bvid,
              coverUrl: cover,
              detailUrl: 'https://www.bilibili.com/video/$bvid',
              description: stripHtmlTags('${row['description'] ?? ''}'),
              durationSeconds: _parseDuration(row['duration']),
              publishedAt: _parsePublishedAt(row['pubdate']),
            );
          })
          .where((item) => item.bvid.isNotEmpty)
          .toList();
      _logger.info(
        'bilibili',
        'search_succeeded',
        data: {'count': results.length},
      );
      return results;
    } on DioException catch (error) {
      _logger.warning(
        'bilibili',
        'search_failed',
        data: {'status_code': error.response?.statusCode},
      );
      final message = error.response?.statusCode == 412
          ? 'B站暂时拒绝了搜索请求，请稍后重试'
          : 'B站搜索失败，请稍后重试';
      throw DataFetchException(message, cause: error);
    } on Object catch (error, stackTrace) {
      _logger.error(
        'bilibili',
        'parse_failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw DataFetchException('B站返回数据无法解析', cause: error);
    }
  }

  static int? _parseDuration(Object? value) {
    if (value is num) return value.toInt();
    if (value is! String || value.trim().isEmpty) return null;
    final parts = value.trim().split(':').map(int.tryParse).toList();
    if (parts.any((part) => part == null)) return null;
    if (parts.length == 3) {
      return parts[0]! * 3600 + parts[1]! * 60 + parts[2]!;
    }
    if (parts.length == 2) return parts[0]! * 60 + parts[1]!;
    return parts.length == 1 ? parts.first : null;
  }

  static DateTime? _parsePublishedAt(Object? value) {
    final seconds = value is num ? value.toInt() : int.tryParse('$value');
    if (seconds == null || seconds <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      seconds * 1000,
      isUtc: true,
    ).toLocal();
  }
}
