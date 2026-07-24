import 'package:dio/dio.dart';

import '../../core/exceptions.dart';
import '../../core/logging/app_logger.dart';
import '../../core/utils.dart';
import 'models.dart';
import 'session_store.dart';

export 'models.dart';

class BilibiliClient {
  BilibiliClient(this._dio, this._logger, {this.sessionStore});

  final Dio _dio;
  final AppLogger _logger;
  final BilibiliSessionStore? sessionStore;
  static const _baseUrl = 'https://api.bilibili.com';
  Future<Map<String, String>>? _anonymousCookiesFuture;

  Future<Options> get _options async => Options(
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
          'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36',
      'Referer': 'https://www.bilibili.com/',
      'Origin': 'https://www.bilibili.com',
      'Accept': 'application/json, text/plain, */*',
      'Cookie': BilibiliSessionStore.cookieHeader({
        ...await _anonymousCookies(),
        ...await _sessionCookies(),
      }),
    },
  );

  Future<List<BilibiliSearchResult>> searchVideos(String keyword) async {
    final value = keyword.trim();
    if (value.isEmpty) return const [];
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/x/web-interface/search/type',
        queryParameters: {
          'search_type': 'video',
          'keyword': value,
          'page': 1,
          'order_type': 'totalrank',
          // Bilibili rejects values above 50 with API code -400.
          'page_size': '50',
        },
        options: await _options,
      );
      await _ensureLoggedIn(response.data);
      final rows = response.data?['data']?['result'];
      if (rows is! List) return const [];
      final result = rows
          .whereType<Map>()
          .map((row) {
            final bvid = '${row['bvid'] ?? ''}';
            return BilibiliSearchResult(
              title: stripHtmlTags('${row['title'] ?? ''}'),
              author: '${row['author'] ?? ''}',
              bvid: bvid,
              coverUrl: _cover(row['pic']),
              detailUrl: 'https://www.bilibili.com/video/$bvid',
              description: stripHtmlTags('${row['description'] ?? ''}'),
              durationSeconds: _duration(row['duration']),
              publishedAt: _date(row['pubdate']),
            );
          })
          .where((item) => item.bvid.isNotEmpty)
          .toList();
      _logger.info(
        'bilibili',
        'search_succeeded',
        data: {'count': result.length},
      );
      return result;
    } on DioException catch (error) {
      _logger.error(
        'bilibili',
        'search_failed',
        error: error,
        stackTrace: error.stackTrace,
        data: {'status_code': error.response?.statusCode},
      );
      throw DataFetchException('B站搜索失败，请稍后重试', cause: error);
    }
  }

  Future<BilibiliVideoDetail> getVideoDetail(String bvid) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/x/web-interface/view',
        queryParameters: {'bvid': bvid},
        options: await _options,
      );
      await _ensureLoggedIn(response.data);
      final data = response.data?['data'];
      if (data is! Map) throw const FormatException('missing detail data');
      final owner = data['owner'] is Map ? data['owner'] as Map : const {};
      BilibiliCollection? collection;
      final season = data['ugc_season'];
      if (season is Map && season['id'] is num) {
        final videos = <BilibiliVideo>[];
        for (final section
            in (season['sections'] is List
                ? season['sections'] as List
                : const [])) {
          if (section is Map && section['episodes'] is List) {
            videos.addAll(
              (section['episodes'] as List).whereType<Map>().map(_video),
            );
          }
        }
        collection = BilibiliCollection(
          id: (season['id'] as num).toInt(),
          name: '${season['name'] ?? ''}',
          videos: videos,
        );
      }
      return BilibiliVideoDetail(
        bvid: '${data['bvid'] ?? bvid}',
        title: stripHtmlTags('${data['title'] ?? ''}'),
        description: stripHtmlTags('${data['desc'] ?? ''}'),
        coverUrl: _cover(data['pic']),
        ownerMid: (owner['mid'] as num?)?.toInt() ?? 0,
        ownerName: '${owner['name'] ?? ''}',
        collection: collection,
        pages: _pages(data),
      );
    } on DioException catch (error) {
      throw DataFetchException('B站单集详情获取失败，请稍后重试', cause: error);
    }
  }

  Future<List<BilibiliVideo>> getCollectionVideos({
    required int mid,
    required int collectionId,
    int page = 1,
    int pageSize = 30,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/x/polymer/web-space/seasons_archives_list',
        queryParameters: {
          'mid': mid,
          'season_id': collectionId,
          'sort_reverse': false,
          'page_num': page,
          'page_size': pageSize,
        },
        options: await _options,
      );
      await _ensureLoggedIn(response.data);
      final rows = response.data?['data']?['archives'];
      return rows is List
          ? rows.whereType<Map>().map(_video).toList()
          : const [];
    } on DioException catch (error) {
      throw DataFetchException('合集视频获取失败，请稍后重试', cause: error);
    }
  }

  BilibiliVideo _video(Map row) => BilibiliVideo(
    title: stripHtmlTags('${row['title'] ?? ''}'),
    bvid: '${row['bvid'] ?? ''}',
    author: '${row['author'] ?? row['owner']?['name'] ?? ''}',
    coverUrl: _cover(row['pic'] ?? row['cover']),
    detailUrl:
        '${row['arcurl'] ?? 'https://www.bilibili.com/video/${row['bvid'] ?? ''}'}',
    description: stripHtmlTags('${row['description'] ?? row['desc'] ?? ''}'),
    durationSeconds: _duration(row['duration']),
    publishedAt: _date(row['pubdate']),
    pages: _pages(row),
  );

  static List<BilibiliPage> _pages(Map row) {
    final value = row['pages'];
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (page) => BilibiliPage(
            page: (page['page'] as num?)?.toInt() ?? 1,
            cid: (page['cid'] as num?)?.toInt() ?? 0,
            part: '${page['part'] ?? ''}',
            durationSeconds: _duration(page['duration']),
          ),
        )
        .toList();
  }

  static String _cover(Object? value) =>
      '${value ?? ''}'.replaceFirst('//', 'https://');

  static int? _duration(Object? value) {
    if (value is num) return value.toInt();
    if (value is! String || value.trim().isEmpty) return null;
    final parts = value.split(':').map(int.tryParse).toList();
    if (parts.any((part) => part == null)) return null;
    if (parts.length == 3) return parts[0]! * 3600 + parts[1]! * 60 + parts[2]!;
    if (parts.length == 2) return parts[0]! * 60 + parts[1]!;
    return parts.length == 1 ? parts.first : null;
  }

  static DateTime? _date(Object? value) {
    final seconds = value is num ? value.toInt() : int.tryParse('$value');
    return seconds == null || seconds <= 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000,
            isUtc: true,
          ).toLocal();
  }

  Future<Map<String, String>> _sessionCookies() async {
    final store = sessionStore;
    return store == null ? const {} : store.cookies();
  }

  Future<Map<String, String>> _anonymousCookies() {
    return _anonymousCookiesFuture ??= _loadAnonymousCookies();
  }

  Future<Map<String, String>> _loadAnonymousCookies() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/x/frontend/finger/spi',
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
                'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36',
            'Referer': 'https://www.bilibili.com/',
          },
        ),
      );
      final data = response.data?['data'];
      if (data is! Map) return const {};
      return {
        if (data['b_3'] is String && (data['b_3'] as String).isNotEmpty)
          'buvid3': data['b_3'] as String,
        if (data['b_4'] is String && (data['b_4'] as String).isNotEmpty)
          'buvid4': data['b_4'] as String,
      };
    } on DioException catch (error, stackTrace) {
      _logger.warning(
        'bilibili',
        'anonymous_cookie_failed',
        error: error,
        stackTrace: stackTrace,
        data: {'status_code': error.response?.statusCode},
      );
      return const {};
    }
  }

  Future<void> _ensureLoggedIn(Map<String, dynamic>? body) async {
    if (body?['code'] != -101) return;
    await sessionStore?.clear();
    throw const DataFetchException('B站登录已失效，请重新登录');
  }
}
