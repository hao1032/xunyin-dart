import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xunyin_dart/core/logging/app_logger.dart';
import 'package:xunyin_dart/features/bilibili/client.dart';
import 'package:xunyin_dart/features/discovery/apple_podcast_source.dart';
import 'package:xunyin_dart/features/discovery/bilibili_source.dart';
import 'package:xunyin_dart/features/discovery/page.dart';
import 'package:xunyin_dart/features/discovery/source.dart';
import 'package:xunyin_dart/features/podcast/client.dart';

void main() {
  test('B站来源映射搜索结果和详情', () async {
    final dio = Dio()
      ..httpClientAdapter = _RoutingAdapter({
        '/x/web-interface/search/type': {
          'data': {
            'result': [
              {
                'title': '视频',
                'author': 'UP主',
                'bvid': 'BV1',
                'pic': '//image.test/video.jpg',
              },
            ],
          },
        },
        '/x/web-interface/view': {
          'data': {
            'bvid': 'BV1',
            'title': '视频详情',
            'desc': '说明',
            'owner': {'mid': 1, 'name': 'UP主'},
            'pages': [
              {'page': 1, 'cid': 2, 'part': '第一P', 'duration': 60},
            ],
          },
        },
      });
    final source = BilibiliDiscoverySource(
      BilibiliClient(dio, const NoopAppLogger()),
    );

    final item = (await source.search('视频')).single;
    expect(item.source, same(source));
    expect(item.sourceItemId, 'BV1');
    expect(item.title, '视频');

    final detail = await source.loadDetail(item);
    expect(detail.title, '视频详情');
    expect(detail.entries.single.title, 'P1 第一P');
  });

  test('Apple Podcasts 来源映射搜索结果', () async {
    final appleDio = Dio()
      ..httpClientAdapter = _RoutingAdapter({
        '/search': {
          'results': [
            {
              'trackName': '播客单集',
              'artistName': '主播',
              'feedUrl': 'https://feed.test/podcast.xml',
              'trackViewUrl': 'https://apple.test/episode',
            },
          ],
        },
      });
    final source = ApplePodcastDiscoverySource(
      ApplePodcastClient(appleDio, const NoopAppLogger()),
      RssClient(Dio(), const NoopAppLogger()),
    );

    final item = (await source.search('播客')).single;
    expect(item.source, same(source));
    expect(item.sourceItemId, 'https://feed.test/podcast.xml');
    expect(item.title, '播客单集');
  });

  testWidgets('发现页按当前来源搜索，切换来源立即重新搜索并进入统一详情页', (tester) async {
    final bilibili = _FakeSource('bilibili', 'B站');
    final apple = _FakeSource('apple', 'Apple Podcasts');
    await tester.pumpWidget(
      MaterialApp(home: DiscoveryPage(sources: [bilibili, apple])),
    );

    await tester.enterText(find.byType(TextField), '关键词');
    await tester.tap(find.byTooltip('搜索'));
    await tester.pumpAndSettle();
    expect(bilibili.queries, ['关键词']);
    expect(apple.queries, isEmpty);
    expect(find.text('B站结果'), findsOneWidget);

    await tester.tap(find.text('Apple Podcasts'));
    await tester.pumpAndSettle();
    expect(apple.queries, ['关键词']);
    expect(find.text('Apple Podcasts结果'), findsOneWidget);

    await tester.tap(find.text('Apple Podcasts结果'));
    await tester.pumpAndSettle();
    expect(apple.detailRequests, 1);
    expect(find.byType(DiscoveryDetailPage), findsOneWidget);
    expect(find.text('Apple Podcasts详情'), findsOneWidget);
  });
}

class _FakeSource extends DiscoverySource {
  _FakeSource(this.id, this.name);

  @override
  final String id;
  @override
  final String name;
  final List<String> queries = [];
  var detailRequests = 0;

  @override
  IconData get icon => Icons.search;

  @override
  Future<DiscoveryDetail> loadDetail(DiscoveryItem item) async {
    detailRequests++;
    return DiscoveryDetail(title: '$name详情', entries: const []);
  }

  @override
  Future<List<DiscoveryItem>> search(String keyword) async {
    queries.add(keyword);
    return [
      DiscoveryItem(
        source: this,
        sourceItemId: keyword,
        title: '$name结果',
        detailUrl: 'https://example.test/$id',
      ),
    ];
  }
}

class _RoutingAdapter implements HttpClientAdapter {
  _RoutingAdapter(this.responses);

  final Map<String, Object> responses;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = responses[options.uri.path] ?? <String, Object>{};
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
