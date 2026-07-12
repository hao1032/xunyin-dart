import 'package:flutter_test/flutter_test.dart';
import 'package:xunyin_dart/features/episode/model.dart';
import 'package:xunyin_dart/features/player/services/playback_queue.dart';
import 'package:xunyin_dart/features/series/model.dart';

void main() {
  test('advances to the next episode inside a series', () {
    final first = _episode('series-1-1', seriesId: 'series-1');
    final second = _episode('series-1-2', seriesId: 'series-1');
    final state = PlaybackQueueState(
      current: first,
      items: [
        PlaybackQueueEntry.series(
          BilibiliCollectionSeries(
            id: 'series-1',
            title: 'Series 1',
            originalUrl: 'https://example.com/series-1',
            episodes: [first, second],
          ),
        ).markPlayed(first.id),
      ],
    );

    final advance = state.advanceAfter(first);

    expect(advance.episode, second);
    expect(advance.state.current, second);
    expect(advance.state.items.single.lastPlayedEpisodeId, second.id);
  });

  test('advances from a completed item to the next queue item', () {
    final first = _episode('episode-1');
    final second = _episode('episode-2');
    final state = PlaybackQueueState(
      current: first,
      items: [
        PlaybackQueueEntry.episode(first),
        PlaybackQueueEntry.episode(second),
      ],
    );

    final advance = state.advanceAfter(first);

    expect(advance.episode, second);
    expect(advance.state.current, second);
  });

  test('keeps the queue unchanged at the end', () {
    final episode = _episode('episode-1');
    final state = PlaybackQueueState(
      current: episode,
      items: [PlaybackQueueEntry.episode(episode)],
    );

    final advance = state.advanceAfter(episode);

    expect(advance.episode, isNull);
    expect(advance.state, same(state));
  });

  test('preserves series metadata through json roundtrip', () {
    final episode = _episode('series-1-1', seriesId: 'series-1');
    final series = BilibiliCreatorSeries(
      id: 'bili-up-42',
      title: 'Alice',
      originalUrl: 'https://space.bilibili.com/42',
      episodes: [episode],
    );
    final entry = PlaybackQueueEntry.series(series);

    final restored = PlaybackQueueEntry.fromJson(entry.toJson());

    expect(restored, isNotNull);
    expect(restored!.series, isA<BilibiliCreatorSeries>());
    expect(restored.series!.id, series.id);
    expect(restored.series!.title, series.title);
  });
}

Episode _episode(String id, {String seriesId = 'series'}) {
  return Episode(
    id: id,
    seriesId: seriesId,
    title: id,
    sourceType: SourceType.bilibili,
    originalUrl: 'https://example.com/$id',
  );
}
