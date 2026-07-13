import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_error.dart';
import '../../../core/app_logger.dart';
import '../../../core/http_client.dart';

final bilibiliClientProvider = Provider<BilibiliClient>((ref) {
  return BilibiliClient(ref.watch(dioProvider));
});

class BilibiliClient {
  const BilibiliClient(this._dio);

  final Dio _dio;
  static Future<String>? _wbiMixinKeyFuture;
  static Future<Map<String, String>>? _buvidCookiesFuture;

  Future<List<Map<String, dynamic>>> searchVideos(
    String keyword, {
    int page = 1,
    int pageSize = 20,
  }) async {
    AppLogger.result(
      'request_search_videos',
      area: 'bilibili',
      message: 'request',
      data: {'keyword': keyword, 'page': page, 'pageSize': pageSize},
    );
    final response = await _get(
      'https://api.bilibili.com/x/web-interface/wbi/search/type',
      queryParameters: {
        'search_type': 'video',
        'keyword': keyword,
        'page': page,
        'page_size': pageSize,
        'duration': 0,
      },
      includeCookies: false,
    );
    final result = response['data']?['result'];
    if (result is! List) {
      final data = response['data'];
      final pageinfo = data is Map ? data['pageinfo'] : null;
      AppLogger.result(
        'request_search_videos',
        area: 'bilibili',
        message: 'type_empty',
        data: {
          'keyword': keyword,
          'count': 0,
          'code': response['code'],
          'message': response['message'],
          'resultType': result.runtimeType.toString(),
          'numResults': data is Map ? data['numResults'] : null,
          'dataKeys': data is Map ? data.keys.join(',') : null,
          'pageinfoVideo': pageinfo is Map ? pageinfo['video'] : null,
        },
      );
      return const [];
    }
    final videos = result.whereType<Map>().map((item) {
      return item.cast<String, dynamic>();
    }).toList();
    if (videos.isEmpty) {
      AppLogger.result(
        'request_search_videos',
        area: 'bilibili',
        message: 'type_empty',
        data: {
          'keyword': keyword,
          'count': 0,
          'code': response['code'],
          'message': response['message'],
          'numResults': response['data']?['numResults'],
        },
      );
      return const [];
    }
    AppLogger.result(
      'request_search_videos',
      area: 'bilibili',
      data: {
        'keyword': keyword,
        'count': videos.length,
        'numResults': response['data']?['numResults'],
        'code': response['code'],
      },
    );
    return videos;
  }

  Future<Map<String, dynamic>> videoDetail(String bvid) async {
    AppLogger.result(
      'request_video_detail',
      area: 'bilibili',
      message: 'request',
      data: {'bvid': bvid},
    );
    final response = await _get(
      'https://api.bilibili.com/x/web-interface/view',
      queryParameters: {'bvid': bvid},
    );
    final data = response['data'];
    if (data is! Map) {
      throw const BilibiliUnavailableException('无法读取 B站视频详情');
    }
    final detail = data.cast<String, dynamic>();
    AppLogger.result(
      'request_video_detail',
      area: 'bilibili',
      data: {
        'bvid': bvid,
        'title': detail['title'],
        'pages': detail['pages'] is List ? (detail['pages'] as List).length : 0,
        'hasSeason': detail['ugc_season'] is Map,
      },
    );
    return detail;
  }

  Future<List<Map<String, dynamic>>> ownerVideos(
    int mid, {
    int page = 1,
    int pageSize = 30,
  }) async {
    AppLogger.result(
      'request_owner_videos',
      area: 'bilibili',
      message: 'request',
      data: {
        'mid': mid,
        'page': page,
        'pageSize': pageSize,
        'strategy': 'wbi_only',
      },
    );
    late final Map<String, dynamic> response;
    try {
      final webId = await _spaceWebId(mid);
      final signedQuery = await _signedWbiQuery({
        'mid': mid,
        'tid': 0,
        'pn': page,
        'ps': pageSize,
        'keyword': '',
        'order': 'pubdate',
        'order_avoided': 'true',
        'platform': 'web',
        ...?(webId == null ? null : {'w_webid': webId}),
      }, wbi2: true);
      response = await _get(
        'https://api.bilibili.com/x/space/wbi/arc/search',
        queryParameters: signedQuery,
      );
    } on BilibiliUnavailableException catch (error, stackTrace) {
      AppLogger.failure(
        'request_owner_videos_wbi',
        error,
        area: 'bilibili',
        stackTrace: stackTrace,
        data: {'mid': mid},
      );
      rethrow;
    }
    final vlist = response['data']?['list']?['vlist'];
    if (vlist is! List) {
      AppLogger.result(
        'request_owner_videos',
        area: 'bilibili',
        data: {'mid': mid, 'count': 0},
      );
      return const [];
    }
    final videos = vlist.whereType<Map>().map((item) {
      return item.cast<String, dynamic>();
    }).toList();
    AppLogger.result(
      'request_owner_videos',
      area: 'bilibili',
      data: {'mid': mid, 'count': videos.length},
    );
    return videos;
  }

  Future<Map<String, Object?>> _signedWbiQuery(
    Map<String, Object?> queryParameters, {
    bool wbi2 = false,
  }) async {
    final mixinKey = await _wbiMixinKey();
    final signed = <String, Object?>{
      ...queryParameters,
      'wts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    if (wbi2) {
      signed.addAll(_wbi2Params());
    }
    signed.putIfAbsent('web_location', () => 1550101);
    final encoded = _encodeWbiQuery(signed);
    signed['w_rid'] = md5.convert(utf8.encode('$encoded$mixinKey')).toString();
    return signed;
  }

  Map<String, Object?> _wbi2Params() {
    return const {
      'dm_img_list': '[]',
      'dm_img_str': 'AB',
      'dm_cover_img_str': 'CD',
      'dm_img_inter': '{"ds":[],"wh":[0,0,0],"of":[0,0,0]}',
    };
  }

  Future<String> _wbiMixinKey() {
    return _wbiMixinKeyFuture ??= _loadWbiMixinKey();
  }

  Future<Map<String, String>> _buvidCookies() {
    return _buvidCookiesFuture ??= _loadBuvidCookies();
  }

  Future<Map<String, String>> _loadBuvidCookies() async {
    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.bilibili.com/x/frontend/finger/spi',
    );
    final data = response.data?['data'];
    if (data is! Map) return const {'opus-goback': '1'};
    final buvid3 = data['b_3'] as String?;
    final buvid4 = data['b_4'] as String?;
    return {
      if (buvid3 != null && buvid3.isNotEmpty) 'buvid3': buvid3,
      if (buvid4 != null && buvid4.isNotEmpty) 'buvid4': buvid4,
      'opus-goback': '1',
    };
  }

  Future<String?> _spaceWebId(int mid) async {
    final cookies = await _buvidCookies();
    try {
      final response = await _dio.get<String>(
        'https://space.bilibili.com/$mid/dynamic',
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            if (cookies.isNotEmpty)
              'cookie': cookies.entries
                  .map((entry) => '${entry.key}=${entry.value}')
                  .join('; '),
          },
        ),
      );
      final html = response.data ?? '';
      final renderData = _renderDataFromHtml(html);
      final webId = _findString(renderData, const {
        'access_id',
        'webid',
        'w_webid',
      });
      if (webId == null || webId.isEmpty) {
        AppLogger.result(
          'request_space_webid',
          area: 'bilibili',
          message: 'empty',
          data: {'mid': mid, 'htmlLength': html.length},
        );
        return null;
      }
      AppLogger.result(
        'request_space_webid',
        area: 'bilibili',
        data: {'mid': mid},
      );
      return webId;
    } on DioException catch (error, stackTrace) {
      AppLogger.failure(
        'request_space_webid',
        error,
        area: 'bilibili',
        stackTrace: stackTrace,
        data: {'mid': mid},
      );
      return null;
    }
  }

  Object? _renderDataFromHtml(String html) {
    final idMatch = RegExp(
      r'<script[^>]+id="__RENDER_DATA__"[^>]*>(.*?)</script>',
      dotAll: true,
    ).firstMatch(html);
    if (idMatch != null) {
      return _decodeRenderData(idMatch.group(1));
    }
    final assignmentMatch = RegExp(
      r'__RENDER_DATA__\s*=\s*(.*?)(?:</script>|;)',
      dotAll: true,
    ).firstMatch(html);
    if (assignmentMatch != null) {
      return _decodeRenderData(assignmentMatch.group(1));
    }
    return null;
  }

  Object? _decodeRenderData(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    final withoutJsonParse = text
        .replaceFirst(RegExp(r'^JSON\.parse\('), '')
        .replaceFirst(RegExp(r'\)$'), '');
    final unquoted = _stripJsStringQuotes(withoutJsonParse);
    final decoded = Uri.decodeComponent(unquoted);
    try {
      return jsonDecode(decoded);
    } on FormatException {
      return null;
    }
  }

  String _stripJsStringQuotes(String value) {
    final text = value.trim();
    if (text.length < 2) return text;
    final quote = text[0];
    if ((quote != '"' && quote != "'") || text[text.length - 1] != quote) {
      return text;
    }
    return text.substring(1, text.length - 1).replaceAll(r'\"', '"');
  }

  String? _findString(Object? value, Set<String> keys) {
    if (value is Map) {
      for (final key in keys) {
        final found = value[key];
        if (found is String && found.isNotEmpty) return found;
      }
      for (final child in value.values) {
        final found = _findString(child, keys);
        if (found != null) return found;
      }
    } else if (value is List) {
      for (final child in value) {
        final found = _findString(child, keys);
        if (found != null) return found;
      }
    }
    return null;
  }

  Future<String> _loadWbiMixinKey() async {
    AppLogger.result(
      'request_wbi_mixin_key',
      area: 'bilibili',
      message: 'request',
    );
    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.bilibili.com/x/web-interface/nav',
      options: Options(
        headers: {
          'cookie': (await _buvidCookies()).entries
              .map((entry) => '${entry.key}=${entry.value}')
              .join('; '),
        },
      ),
    );
    final body = response.data ?? const <String, dynamic>{};
    final wbiImage = body['data']?['wbi_img'];
    if (wbiImage is! Map) {
      throw const BilibiliUnavailableException('无法读取 B站 WBI 签名参数');
    }
    final imageKey = _fileStem(wbiImage['img_url'] as String?);
    final subKey = _fileStem(wbiImage['sub_url'] as String?);
    if (imageKey == null || subKey == null) {
      throw const BilibiliUnavailableException('B站 WBI 签名参数无效');
    }
    final mixinKey = _mixinKey('$imageKey$subKey');
    AppLogger.result(
      'request_wbi_mixin_key',
      area: 'bilibili',
      data: {'code': body['code']},
    );
    return mixinKey;
  }

  String _encodeWbiQuery(Map<String, Object?> queryParameters) {
    final keys = queryParameters.keys.toList()..sort();
    return keys
        .map((key) {
          final value = _sanitizeWbiValue(
            queryParameters[key]?.toString() ?? '',
          );
          return '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}';
        })
        .join('&');
  }

  String _sanitizeWbiValue(String value) {
    return value.replaceAll(RegExp(r"[!'()*]"), '');
  }

  String? _fileStem(String? url) {
    if (url == null || url.isEmpty) return null;
    final path = Uri.tryParse(url)?.path ?? url;
    final name = path.split('/').last;
    final dot = name.indexOf('.');
    return dot <= 0 ? name : name.substring(0, dot);
  }

  String _mixinKey(String rawKey) {
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
      42,
      19,
      29,
      28,
      14,
      39,
      12,
      38,
      41,
      13,
      37,
      48,
      7,
      16,
      24,
      55,
      40,
      61,
      26,
      17,
      0,
      1,
      60,
      51,
      30,
      4,
      22,
      25,
      54,
      21,
      56,
      59,
      6,
      63,
      57,
      62,
      11,
      36,
      20,
      34,
      44,
      52,
    ];
    return table
        .where((index) => index < rawKey.length)
        .map((index) => rawKey[index])
        .join()
        .substring(0, 32);
  }

  Future<String> mediaUrl({required String bvid, required int cid}) async {
    AppLogger.result(
      'request_media_url',
      area: 'bilibili',
      message: 'request',
      data: {'bvid': bvid, 'cid': cid},
    );
    final response = await _get(
      'https://api.bilibili.com/x/player/wbi/playurl',
      queryParameters: {'bvid': bvid, 'cid': cid, 'fnval': 4048, 'fourk': 1},
    );
    final dash = response['data']?['dash'];
    final audios = dash is Map ? dash['audio'] : null;
    if (audios is! List || audios.isEmpty) {
      throw const BilibiliUnavailableException(
        '该 B站内容暂时没有可播放音频',
        code: 'no_audio',
      );
    }
    final sorted =
        audios.whereType<Map>().map((item) {
          return item.cast<String, dynamic>();
        }).toList()..sort((a, b) {
          final left = (a['bandwidth'] as num?)?.toInt() ?? 0;
          final right = (b['bandwidth'] as num?)?.toInt() ?? 0;
          return right.compareTo(left);
        });
    final selected = _selectAudioCandidate(sorted);
    final url = selected['baseUrl'] ?? selected['base_url'];
    if (url is! String || url.isEmpty) {
      throw const BilibiliUnavailableException(
        '该 B站音频地址不可用',
        code: 'bad_media_url',
      );
    }
    final normalizedUrl = normalizeMediaUrl(url);
    final normalizedUri = Uri.tryParse(normalizedUrl);
    AppLogger.result(
      'request_media_url',
      area: 'bilibili',
      data: {
        'bvid': bvid,
        'cid': cid,
        'mediaCount': sorted.length,
        'selectedId': selected['id'],
        'selectedCodecs': selected['codecs'],
        'selectedBandwidth': selected['bandwidth'],
        'scheme': normalizedUri?.scheme,
        'host': normalizedUri?.host,
        'port': normalizedUri?.hasPort == true ? normalizedUri?.port : null,
      },
    );
    return normalizedUrl;
  }

  Map<String, dynamic> _selectAudioCandidate(
    List<Map<String, dynamic>> sorted,
  ) {
    final aacCandidates = sorted.where((item) {
      final codecs = item['codecs'];
      return codecs is String && codecs.toLowerCase().startsWith('mp4a');
    });
    return aacCandidates.isNotEmpty ? aacCandidates.first : sorted.first;
  }

  static String normalizeMediaUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    if (uri.scheme == 'http' && !uri.hasPort) {
      return uri.replace(scheme: 'https').toString();
    }
    return url;
  }

  Future<Map<String, dynamic>> _get(
    String url, {
    Map<String, Object?>? queryParameters,
    bool includeCookies = true,
  }) async {
    try {
      AppLogger.result(
        'http_get',
        area: 'bilibili',
        message: 'request',
        data: {'url': url, 'query': queryParameters},
      );
      final cookies = includeCookies
          ? await _buvidCookies()
          : const <String, String>{};
      final response = await _dio.get<Map<String, dynamic>>(
        url,
        queryParameters: queryParameters,
        options: Options(
          headers: {
            if (cookies.isNotEmpty)
              'cookie': cookies.entries
                  .map((entry) => '${entry.key}=${entry.value}')
                  .join('; '),
          },
        ),
      );
      final body = response.data ?? const {};
      final code = body['code'];
      if (code == 0) {
        AppLogger.result(
          'http_get',
          area: 'bilibili',
          data: {'url': url, 'statusCode': response.statusCode},
        );
        return body;
      }
      throw BilibiliUnavailableException(
        _messageForCode(code),
        code: code?.toString(),
      );
    } on DioException catch (error, stackTrace) {
      final statusCode = error.response?.statusCode;
      AppLogger.failure(
        'http_get',
        error,
        area: 'bilibili',
        stackTrace: stackTrace,
        data: {'url': url, 'statusCode': statusCode},
      );
      if (statusCode == 403 || statusCode == 412) {
        throw BilibiliUnavailableException(
          'B站拒绝了本次请求，可能触发了风控或内容需要登录',
          code: statusCode.toString(),
          cause: error,
        );
      }
      throw BilibiliUnavailableException('B站请求失败', cause: error);
    }
  }

  String _messageForCode(Object? code) {
    return switch (code) {
      -404 => 'B站内容不存在或已不可见',
      -400 => 'B站请求参数无效',
      -101 => '该 B站内容需要登录后访问',
      -10403 => '该 B站内容受限，无法播放',
      _ => 'B站接口暂时不可用',
    };
  }
}
