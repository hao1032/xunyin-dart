import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/http_client.dart';

final bilibiliClientProvider = Provider<BilibiliClient>((ref) {
  return BilibiliClient(ref.watch(dioProvider));
});

class BilibiliClient {
  const BilibiliClient(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> searchVideos(String keyword) async {
    AppLogger.result(
      'request_search_videos',
      area: 'bilibili',
      message: 'request',
      data: {'keyword': keyword},
    );
    final response = await _get(
      'https://api.bilibili.com/x/web-interface/wbi/search/type',
      queryParameters: {
        'search_type': 'video',
        'keyword': keyword,
        'page': 1,
        'order': 'totalrank',
      },
    );
    final result = response['data']?['result'];
    if (result is! List) {
      AppLogger.result(
        'request_search_videos',
        area: 'bilibili',
        data: {'keyword': keyword, 'count': 0},
      );
      return const [];
    }
    final videos = result.whereType<Map>().map((item) {
      return item.cast<String, dynamic>();
    }).toList();
    AppLogger.result(
      'request_search_videos',
      area: 'bilibili',
      data: {'keyword': keyword, 'count': videos.length},
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

  Future<String> audioUrl({required String bvid, required int cid}) async {
    AppLogger.result(
      'request_audio_url',
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
        code: 'bad_audio_url',
      );
    }
    final normalizedUrl = _normalizeMediaUrl(url);
    AppLogger.result(
      'request_audio_url',
      area: 'bilibili',
      data: {
        'bvid': bvid,
        'cid': cid,
        'audioCount': sorted.length,
        'selectedId': selected['id'],
        'selectedCodecs': selected['codecs'],
        'selectedBandwidth': selected['bandwidth'],
        'scheme': Uri.tryParse(normalizedUrl)?.scheme,
        'host': Uri.tryParse(normalizedUrl)?.host,
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

  String _normalizeMediaUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    if (uri.scheme == 'http') {
      return uri.replace(scheme: 'https').toString();
    }
    return url;
  }

  Future<Map<String, dynamic>> _get(
    String url, {
    Map<String, Object?>? queryParameters,
  }) async {
    try {
      AppLogger.result(
        'http_get',
        area: 'bilibili',
        message: 'request',
        data: {'url': url, 'query': queryParameters},
      );
      final response = await _dio.get<Map<String, dynamic>>(
        url,
        queryParameters: queryParameters,
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
