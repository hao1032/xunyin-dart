import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/network/http_client.dart';
import '../../search/domain/search_result.dart';
import '../domain/source_type.dart';

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
        'entity': 'podcast',
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
      final collectionId = json['collectionId']?.toString() ?? feedUrl;
      return SearchResult(
        id: 'apple-$collectionId',
        title: json['collectionName'] as String? ?? '未命名播客',
        sourceType: SourceType.applePodcast,
        originalUrl: json['collectionViewUrl'] as String? ?? feedUrl ?? '',
        subtitle: json['artistName'] as String?,
        imageUrl:
            json['artworkUrl600'] as String? ??
            json['artworkUrl100'] as String?,
        feedUrl: feedUrl,
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
