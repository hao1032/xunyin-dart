import 'package:flutter_test/flutter_test.dart';
import 'package:xunyin_dart/features/series/model.dart';

void main() {
  test('parses concrete series types', () {
    final creator = Series.fromJson({
      'id': 'bili-up-42',
      'title': 'Alice',
      'type': 'bilibiliCreator',
      'sourceType': 'bilibili',
      'originalUrl': 'https://space.bilibili.com/42',
    });
    final rss = Series.fromJson({
      'id': 'rss-example',
      'title': 'Example',
      'type': 'rssPodcast',
      'sourceType': 'rss',
      'originalUrl': 'https://example.com',
      'feedUrl': 'https://example.com/feed.xml',
    });

    expect(creator, isA<BilibiliCreatorSeries>());
    expect(rss, isA<RssPodcastSeries>());
  });

  test('serializes the explicit series type', () {
    final series = Series.fromJson({
      'id': 'bili-season-88',
      'title': 'Season',
      'type': 'bilibiliCollection',
      'sourceType': 'bilibili',
      'originalUrl': 'https://www.bilibili.com',
    });

    expect(series, isA<BilibiliCollectionSeries>());
    expect(series.toJson()['type'], 'bilibiliCollection');
  });

  test('preserves B站 collection creator link', () {
    final series = Series.fromJson({
      'id': 'bili-season-88',
      'title': 'Season',
      'type': 'bilibiliCollection',
      'sourceType': 'bilibili',
      'originalUrl': 'https://www.bilibili.com/video/BV1',
      'creator': {
        'id': 'bili-up-42',
        'title': 'Alice',
        'type': 'bilibiliCreator',
        'sourceType': 'bilibili',
        'originalUrl': 'https://space.bilibili.com/42',
      },
    });

    expect(series, isA<BilibiliCollectionSeries>());
    final collection = series as BilibiliCollectionSeries;
    expect(collection.creator?.title, 'Alice');
    expect(
      (collection.toJson()['creator'] as Map<String, Object?>)['id'],
      'bili-up-42',
    );
  });
}
