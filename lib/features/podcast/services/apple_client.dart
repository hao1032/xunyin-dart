import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_logger.dart';
import '../../../core/http_client.dart';
import '../../episode/model.dart';
import '../../search/model.dart';

final applePodcastClientProvider = Provider<ApplePodcastClient>((ref) {
  return ApplePodcastClient(ref.watch(dioProvider));
});

class ApplePodcastClient {
  const ApplePodcastClient(this._dio);

  final Dio _dio;

  Future<List<SearchResult>> search(String keyword) async {
    if (keyword.trim().isEmpty) return const [];
    AppLogger.result(
      'search',
      area: 'apple_podcast',
      message: 'request',
      data: {'keyword': keyword.trim()},
    );
    final response = await _dio.get<Object?>(
      'https://itunes.apple.com/search',
      queryParameters: {
        'media': 'podcast',
        'entity': 'podcastEpisode',
        'term': keyword.trim(),
        'limit': 25,
      },
      options: Options(responseType: ResponseType.plain),
    );
    final body = parseAppleSearchBody(response.data);
    final results = body['results'];
    if (results is! List) {
      AppLogger.result(
        'search',
        area: 'apple_podcast',
        data: {'keyword': keyword.trim(), 'count': 0},
      );
      return const [];
    }
    final mapped = results.whereType<Map>().map((raw) {
      final json = raw.cast<String, dynamic>();
      final feedUrl = json['feedUrl'] as String?;
      final trackId = json['trackId']?.toString() ?? json['episodeGuid'];
      final collectionName = json['collectionName'] as String?;
      final trackName = json['trackName'] as String?;
      return SearchResult(
        id: 'apple-episode-${trackId ?? trackName ?? feedUrl}',
        title: trackName ?? '未命名单集',
        sourceType: SourceType.applePodcast,
        originalUrl:
            json['trackViewUrl'] as String? ??
            json['collectionViewUrl'] as String? ??
            feedUrl ??
            '',
        subtitle: collectionName ?? json['artistName'] as String?,
        description:
            json['description'] as String? ??
            json['shortDescription'] as String?,
        imageUrl:
            json['artworkUrl600'] as String? ??
            json['artworkUrl100'] as String?,
        feedUrl: feedUrl,
        mediaUrl: json['episodeUrl'] as String?,
        duration: _durationFromMillis(json['trackTimeMillis'] as num?),
        publishedAt: DateTime.tryParse(json['releaseDate'] as String? ?? ''),
        seriesTitle: collectionName,
      );
    }).toList();
    AppLogger.result(
      'search',
      area: 'apple_podcast',
      data: {'keyword': keyword.trim(), 'count': mapped.length},
    );
    return mapped;
  }
}

Duration? _durationFromMillis(num? milliseconds) {
  final value = milliseconds?.toInt();
  if (value == null || value <= 0) return null;
  return Duration(milliseconds: value);
}

Map<String, dynamic> parseAppleSearchBody(Object? body) {
  if (body is Map<String, dynamic>) return body;
  if (body is Map) return body.cast<String, dynamic>();
  if (body is String && body.trim().isNotEmpty) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
  }
  return const {};
}
