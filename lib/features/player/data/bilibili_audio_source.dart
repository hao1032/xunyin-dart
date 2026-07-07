// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';

import '../../../core/logging/app_logger.dart';

class BilibiliAudioSource extends StreamAudioSource {
  BilibiliAudioSource({
    required this.uri,
    required this.headers,
    required this.episodeId,
    super.tag,
  });

  final Uri uri;
  final Map<String, String> headers;
  final String episodeId;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final client = HttpClient();
    HttpClientRequest? request;
    try {
      AppLogger.result(
        'bilibili_stream_request',
        area: 'player',
        message: 'request',
        data: {
          'episodeId': episodeId,
          'start': start,
          'end': end,
          'host': uri.host,
        },
      );
      request = await client.getUrl(uri);
      headers.forEach(request.headers.set);
      if (start != null || end != null) {
        request.headers.set(HttpHeaders.rangeHeader, _rangeHeader(start, end));
      }

      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('B站音频流请求失败: HTTP ${response.statusCode}', uri: uri);
      }

      final range = _ContentRange.parse(
        response.headers.value(HttpHeaders.contentRangeHeader),
      );
      final contentLength = response.contentLength < 0
          ? null
          : response.contentLength;
      final sourceLength = range?.sourceLength ?? contentLength;
      final offset = response.statusCode == HttpStatus.partialContent
          ? range?.start ?? start ?? 0
          : null;

      AppLogger.result(
        'bilibili_stream_request',
        area: 'player',
        data: {
          'episodeId': episodeId,
          'statusCode': response.statusCode,
          'contentLength': contentLength,
          'sourceLength': sourceLength,
          'offset': offset,
          'contentType': 'audio/mp4',
        },
      );

      return StreamAudioResponse(
        rangeRequestsSupported: true,
        sourceLength: sourceLength,
        contentLength: contentLength,
        offset: offset,
        contentType: 'audio/mp4',
        stream: _closeClientAfterStream(response, client),
      );
    } catch (error, stackTrace) {
      client.close(force: true);
      AppLogger.failure(
        'bilibili_stream_request',
        error,
        area: 'player',
        stackTrace: stackTrace,
        data: {'episodeId': episodeId, 'host': uri.host},
      );
      rethrow;
    }
  }

  String _rangeHeader(int? start, int? end) {
    final startText = start?.toString() ?? '';
    final endText = end == null ? '' : (end - 1).toString();
    return 'bytes=$startText-$endText';
  }

  Stream<List<int>> _closeClientAfterStream(
    HttpClientResponse response,
    HttpClient client,
  ) async* {
    try {
      yield* response;
    } finally {
      client.close(force: true);
    }
  }
}

class _ContentRange {
  const _ContentRange({required this.start, required this.sourceLength});

  final int? start;
  final int? sourceLength;

  static _ContentRange? parse(String? header) {
    if (header == null || header.isEmpty) return null;
    final match = RegExp(r'^bytes\s+(\d+)-\d+/(\d+|\*)$').firstMatch(header);
    if (match == null) return null;
    return _ContentRange(
      start: int.tryParse(match.group(1) ?? ''),
      sourceLength: int.tryParse(match.group(2) ?? ''),
    );
  }
}
