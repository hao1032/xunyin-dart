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

  static const _baseUrl = 'https://api.bilibili.com';

  Options get _requestOptions => Options(
    headers: {
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

  Future<List<BilibiliSearchResult>> searchVideos(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return const [];
    try {
      final options = _requestOptions;
      Response<Map<String, dynamic>>? response;
      DioException? last412;
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          response = await _dio.get<Map<String, dynamic>>(
            '$_baseUrl/x/web-interface/search/type',
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
      _logger.error(
        'bilibili',
        'search_failed',
        error: error,
        stackTrace: error.stackTrace,
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

  Future<BilibiliVideoDetail> getVideoDetail(String bvid) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/x/web-interface/view',
        queryParameters: {'bvid': bvid},
        options: _requestOptions,
      );
      final data = response.data?['data'];
      if (data is! Map) throw const FormatException('missing detail data');
      final owner = data['owner'] is Map ? data['owner'] as Map : const {};
      final pages = _pagesFromRow(data);
      final season = data['ugc_season'];
      BilibiliCollection? collection;
      if (season is Map) {
        final id = (season['id'] as num?)?.toInt();
        if (id != null) {
          final videos = <BilibiliVideo>[];
          final sections = season['sections'];
          if (sections is List) {
            for (final section in sections.whereType<Map>()) {
              final episodes = section['episodes'];
              if (episodes is List) {
                videos.addAll(episodes.whereType<Map>().map(_videoFromRow));
              }
            }
          }
          collection = BilibiliCollection(
            id: id,
            name: '${season['name'] ?? ''}',
            videos: videos,
          );
        }
      }
      final detail = BilibiliVideoDetail(
        bvid: '${data['bvid'] ?? bvid}',
        title: stripHtmlTags('${data['title'] ?? ''}'),
        description: stripHtmlTags('${data['desc'] ?? ''}'),
        coverUrl: _cover(data['pic']),
        ownerMid: (owner['mid'] as num?)?.toInt() ?? 0,
        ownerName: '${owner['name'] ?? ''}',
        collection: collection,
        pages: pages,
      );
      _logger.info('bilibili', 'detail_succeeded');
      return detail;
    } on DioException catch (error) {
      _logger.warning(
        'bilibili',
        'detail_failed',
        data: {'status_code': error.response?.statusCode},
      );
      throw DataFetchException('B站单集详情获取失败，请稍后重试', cause: error);
    } on Object catch (error, stackTrace) {
      _logger.error(
        'bilibili',
        'detail_parse_failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw DataFetchException('B站单集详情无法解析', cause: error);
    }
  }

  Future<List<BilibiliVideo>> getCollectionVideos({
    required int mid,
    required int collectionId,
    int page = 1,
    int pageSize = 30,
  }) async {
    try {
      // ugc_season.id 是 season_id，不是旧版 series_id。该接口也不需要
      // WBI 签名，使用页面公开的合集归档接口。
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/x/polymer/web-space/seasons_archives_list',
        queryParameters: {
          'mid': mid,
          'season_id': collectionId,
          'sort_reverse': false,
          'page_num': page,
          'page_size': pageSize,
        },
        options: _requestOptions,
      );
      final data = response.data?['data'];
      final rows = data is Map ? data['archives'] ?? data['list'] : null;
      final videos = rows is List
          ? rows.whereType<Map>().map(_videoFromRow).toList()
          : <BilibiliVideo>[];
      _logger.info(
        'bilibili',
        'collection_videos_succeeded',
        data: {'count': videos.length},
      );
      return videos;
    } on DioException catch (error) {
      _logger.warning(
        'bilibili',
        'collection_videos_failed',
        data: {'status_code': error.response?.statusCode},
      );
      throw DataFetchException('合集视频获取失败，请稍后重试', cause: error);
    } on Object catch (error, stackTrace) {
      _logger.error(
        'bilibili',
        'collection_videos_parse_failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw DataFetchException('合集视频数据无法解析', cause: error);
    }
  }

  BilibiliVideo _videoFromRow(Map row) {
    final bvid = '${row['bvid'] ?? ''}';
    return BilibiliVideo(
      title: stripHtmlTags('${row['title'] ?? ''}'),
      bvid: bvid,
      author: '${row['author'] ?? row['owner']?['name'] ?? ''}',
      coverUrl: _cover(row['pic'] ?? row['cover']),
      detailUrl: '${row['arcurl'] ?? 'https://www.bilibili.com/video/$bvid'}',
      description: stripHtmlTags('${row['description'] ?? row['desc'] ?? ''}'),
      durationSeconds: _parseDuration(row['duration']),
      publishedAt: _parsePublishedAt(row['pubdate']),
      pages: _pagesFromRow(row),
    );
  }

  List<BilibiliPage> _pagesFromRow(Map row) {
    final raw = row['pages'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((page) {
      final number = (page['page'] as num?)?.toInt() ?? 1;
      final cid = (page['cid'] as num?)?.toInt() ?? 0;
      return BilibiliPage(
        page: number,
        cid: cid,
        part: '${page['part'] ?? ''}',
        durationSeconds: _parseDuration(page['duration']),
      );
    }).toList();
  }

  static String _cover(Object? value) {
    return '${value ?? ''}'.replaceFirst('//', 'https://');
  }

  /* Removed WBI and anonymous UP-list support.
  // ignore: unused_element
  Future<Response<Map<String, dynamic>>> _wbiGet(
    String path,
    Map<String, Object> parameters,
  ) async {
    final keys = await (_wbiKeys ??= _loadWbiKeys());
    final values = <String, Object>{...parameters};
    // 空间视频接口当前还会校验这些网页端请求参数；它们不是用户
    // 凭证，只是 B 站网页端固定的风控字段。
    values.addAll(const {
      'web_location': 1550101,
      'dm_img_list': '[]',
      'dm_img_str': 'AB',
      'dm_cover_img_str': 'CD',
      'dm_img_inter': '{"ds":[],"wh":[0,0,0],"of":[0,0,0]}',
    });
    final mid = values['mid'];
    if (path == '/x/space/wbi/arc/search' && mid is int && mid > 0) {
      final webId = await (_spaceWebIds[mid] ??= _loadSpaceWebId(mid));
      if (webId != null && webId.isNotEmpty) values['w_webid'] = webId;
    }
    values['wts'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final sorted = values.keys.toList()..sort();
    final query = sorted
        .map((key) => '$key=${Uri.encodeQueryComponent('${values[key]}')}')
        .join('&');
    final rid = md5.convert(utf8.encode(query + keys.mixinKey)).toString();
    final headers = <String, String>{...?_requestOptions.headers?.cast<String, String>()};
    if (path == '/x/space/wbi/arc/search') {
      final cookies = await (_anonymousCookies ??= _loadAnonymousCookies());
      if (cookies.isNotEmpty) {
        headers['Cookie'] = cookies.entries
            .map((entry) => '${entry.key}=${entry.value}')
            .join('; ');
      }
    }
    return _dio.get<Map<String, dynamic>>(
      '$_baseUrl$path',
      queryParameters: {...values, 'w_rid': rid},
      options: Options(headers: headers),
    );
  }

  Future<Map<String, String>> _loadAnonymousCookies() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/x/frontend/finger/spi',
        options: _requestOptions,
      );
      final data = response.data?['data'];
      if (data is Map) {
        final b3 = '${data['b_3'] ?? ''}';
        final b4 = '${data['b_4'] ?? ''}';
        return {
          if (b3.isNotEmpty) 'buvid3': b3,
          if (b4.isNotEmpty) 'buvid4': b4,
          'opus-goback': '1',
        };
      }
    } on DioException catch (error) {
      _logger.warning('bilibili', 'anonymous_cookie_failed',
          data: {'status_code': error.response?.statusCode});
    }
    return const {'opus-goback': '1'};
  }

  Future<_WbiKeys> _loadWbiKeys() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_baseUrl/x/web-interface/nav',
      options: _requestOptions,
    );
    final image = response.data?['data']?['wbi_img'];
    if (image is! Map) throw const FormatException('missing WBI keys');
    final img = '${image['img_url'] ?? ''}';
    final sub = '${image['sub_url'] ?? ''}';
    String key(String url) => url.split('/').last.split('.').first;
    final imgKey = key(img);
    final subKey = key(sub);
    if (imgKey.isEmpty || subKey.isEmpty) {
      throw const FormatException('invalid WBI keys');
    }
    return _WbiKeys(_mixinKey(imgKey, subKey));
  }

  Future<String?> _loadSpaceWebId(int mid) async {
    try {
      final response = await _dio.get<String>(
        'https://space.bilibili.com/$mid/dynamic',
        options: _requestOptions.copyWith(responseType: ResponseType.plain),
      );
      final html = response.data ?? '';
      final patterns = <RegExp>[
        RegExp(r'''["']w_webid["']\s*:\s*["']([^"']+)''', caseSensitive: false),
        RegExp(r'''["']webid["']\s*:\s*["']([^"']+)''', caseSensitive: false),
      ];
      for (final pattern in patterns) {
        final value = pattern.firstMatch(html)?.group(1);
        if (value != null && value.isNotEmpty) return value;
      }
    } on DioException catch (error) {
      _logger.warning(
        'bilibili',
        'space_webid_failed',
        data: {'status_code': error.response?.statusCode},
      );
    }
    return null;
  }

  static String _mixinKey(String imgKey, String subKey) {
    const table = [
      46,
      47,
      18,
      2,
      53,
      8,
      23,
      32,
      15,
      50,
      10,
      31,
      58,
      3,
      45,
      35,
      27,
      43,
      5,
      49,
      33,
      9,
      30,
      28,
      44,
      22,
      6,
      17,
      48,
      34,
      4,
      24,
      37,
      54,
      7,
      42,
      14,
      39,
      19,
      41,
      26,
      38,
      40,
      12,
      25,
      52,
      13,
      56,
      29,
      57,
      36,
      21,
      1,
      55,
      11,
      60,
      16,
      51,
      0,
      20,
      59,
      8,
      43,
      24,
    ];
    final source = '$imgKey$subKey';
    return table
        .where((index) => index < source.length)
        .map((index) => source[index])
        .join()
        .substring(0, 32);
  }

  */

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
