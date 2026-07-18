import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xunyin_dart/core/logging/app_logger.dart';
import 'package:xunyin_dart/features/bilibili/client.dart';
import 'package:xunyin_dart/features/podcast/client.dart';
import 'package:xunyin_dart/features/podcast/rss.dart';
import 'package:xunyin_dart/core/utils.dart';

void main() {
  test('解析 B 站搜索结果并去除标题 HTML', () async {
    final dio = Dio()
      ..httpClientAdapter = _JsonAdapter({
        'data': {
          'result': [
            {
              'title': '<em class="keyword">测试</em> 视频',
              'author': '作者',
              'bvid': 'BV1xx',
              'pic': '//image.test/a.jpg',
              'duration': '01:02:03',
              'pubdate': 1735689600,
            },
          ],
        },
      });
    final result = await BilibiliClient(
      dio,
      const NoopAppLogger(),
    ).searchVideos('测试');
    expect(result.single.title, '测试 视频');
    expect(result.single.bvid, 'BV1xx');
    expect(result.single.coverUrl, 'https://image.test/a.jpg');
    expect(result.single.durationSeconds, 3723);
    expect(result.single.publishedAt, isNotNull);
  });

  test('解析 Apple Podcasts 搜索结果', () async {
    final dio = Dio()
      ..httpClientAdapter = _JsonAdapter({
        'results': [
          {
            'collectionName': '播客',
            'artistName': '作者',
            'feedUrl': 'https://example.test/feed.xml',
            'collectionId': 42,
          },
        ],
      });
    final result = await ApplePodcastClient(
      dio,
      const NoopAppLogger(),
    ).search('播客');
    expect(result.single.name, '播客');
    expect(result.single.feedUrl, 'https://example.test/feed.xml');
    expect(result.single.collectionId, 42);
  });

  test('解析 RSS 单集和时长、字节数', () {
    final feed = RssParser.parse('''
      <rss><channel>
        <title>节目</title><author>作者</author>
        <item><title>第一集</title><pubDate>Wed, 01 Jan 2025 00:00:00 GMT</pubDate>
          <description>说明</description>
          <duration>01:02:03</duration>
          <enclosure url="https://example.test/a.mp3" length="1234" />
        </item>
      </channel></rss>
    ''');
    expect(feed.title, '节目');
    expect(feed.episodes.single.publishedAt, isNotNull);
    expect(feed.episodes.single.durationSeconds, 3723);
    expect(feed.episodes.single.audioBytes, 1234);
    expect(feed.episodes.single.audioUrl, 'https://example.test/a.mp3');
  });

  test('解析 RSS 命名空间时长和日期', () {
    final feed = RssParser.parse('''
      <rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
        <channel><title>节目</title><item><title>第一集</title>
          <pubDate>Wed, 01 Jan 2025 00:00:00 GMT</pubDate>
          <itunes:duration>01:02:03</itunes:duration>
          <enclosure url="https://example.test/a.mp3" />
        </item></channel>
      </rss>
    ''');
    expect(feed.episodes.single.publishedAt, isNotNull);
    expect(feed.episodes.single.durationSeconds, 3723);
  });

  test('格式化日期和时长', () {
    expect(formatDate(DateTime(2025, 1, 2)), '2025-01-02');
    expect(formatDate(null), '未知日期');
    expect(formatDuration(65), '1:05');
    expect(formatDuration(3723), '1:02:03');
    expect(formatDuration(null), '未知时长');
  });
}

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.body);
  final Object body;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    body is Map ? _encode(body) : '$body',
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  static String _encode(Object value) {
    if (value is Map) {
      return '{${value.entries.map((entry) => '"${entry.key}":${_encode(entry.value as Object)}').join(',')}}';
    }
    if (value is List) {
      return '[${value.map((item) => _encode(item as Object)).join(',')}]';
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    return '"${value.toString().replaceAll('"', '\\"')}"';
  }
}
