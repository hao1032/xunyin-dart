import 'package:flutter_test/flutter_test.dart';
import 'package:xunyin_dart/features/series/model.dart';
import 'package:xunyin_dart/features/podcast/services/rss_parser.dart';
import 'package:xunyin_dart/features/episode/model.dart';

void main() {
  test('parses an RSS feed into a Series with episodes', () {
    final series = RssParser().parse('''
      <rss>
        <channel>
          <title>Example Show</title>
          <description>Talks</description>
          <author>Ada</author>
          <image><url>https://example.com/cover.jpg</url></image>
          <item>
            <title>Episode 1</title>
            <guid>ep-1</guid>
            <link>https://example.com/ep-1</link>
            <enclosure url="https://example.com/ep-1.mp3" />
            <itunes:duration>01:02:03</itunes:duration>
          </item>
        </channel>
      </rss>
      ''', feedUrl: 'https://example.com/feed.xml');

    expect(series.title, 'Example Show');
    expect(series.sourceType, SourceType.rss);
    expect(series, isA<RssPodcastSeries>());
    expect(series.episodes, hasLength(1));
    expect(series.episodes.single.mediaUrl, 'https://example.com/ep-1.mp3');
    expect(
      series.episodes.single.duration,
      const Duration(hours: 1, minutes: 2, seconds: 3),
    );
  });
}
