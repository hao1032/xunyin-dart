import 'package:flutter_test/flutter_test.dart';
import 'package:xunyin_dart/features/episode/model.dart';

void main() {
  test('accepts valid episode json', () {
    final episode = Episode.tryFromJson({
      'id': 'ep-1',
      'seriesId': 'series-1',
      'title': 'Episode 1',
      'sourceType': 'bilibili',
      'originalUrl': 'https://example.com',
      'duration': 120000,
      'aid': 42,
      'cid': 99,
      'page': 1,
    });

    expect(episode, isNotNull);
    expect(episode!.cid, 99);
  });

  test('skips malformed episode json', () {
    final episode = Episode.tryFromJson({
      'id': 'ep-1',
      'seriesId': 'series-1',
      'title': 'Episode 1',
      'sourceType': 'bilibili',
    });

    expect(episode, isNull);
  });
}
