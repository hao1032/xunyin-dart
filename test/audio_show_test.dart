import 'package:flutter_test/flutter_test.dart';
import 'package:xunyin_dart/features/channel/model.dart';

void main() {
  test('migrates legacy subscriptions to concrete show types', () {
    final creator = AudioShow.fromJson({
      'id': 'bili-up-42',
      'title': 'Alice',
      'sourceType': 'bilibili',
      'originalUrl': 'https://space.bilibili.com/42',
    });
    final rss = AudioShow.fromJson({
      'id': 'rss-example',
      'title': 'Example',
      'sourceType': 'rss',
      'originalUrl': 'https://example.com',
      'feedUrl': 'https://example.com/feed.xml',
    });

    expect(creator, isA<BilibiliCreatorShow>());
    expect(rss, isA<RssPodcastShow>());
  });

  test('preserves legacy kind values in serialized data', () {
    final show = AudioShow.fromJson({
      'id': 'bili-season-88',
      'title': 'Season',
      'kind': 'bilibiliCollection',
      'sourceType': 'bilibili',
      'originalUrl': 'https://www.bilibili.com',
    });

    expect(show, isA<BilibiliCollectionShow>());
    expect(show.toJson()['kind'], 'bilibiliCollection');
  });
}
