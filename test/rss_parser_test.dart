import 'package:flutter_test/flutter_test.dart';
import 'package:xunyin_dart/features/podcast/data/rss_parser.dart';
import 'package:xunyin_dart/features/podcast/domain/source_type.dart';

void main() {
  test('parses an RSS feed into a PodcastShow with episodes', () {
    final show = RssParser().parse('''
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

    expect(show.title, 'Example Show');
    expect(show.sourceType, SourceType.rss);
    expect(show.episodes, hasLength(1));
    expect(show.episodes.single.audioUrl, 'https://example.com/ep-1.mp3');
    expect(
      show.episodes.single.duration,
      const Duration(hours: 1, minutes: 2, seconds: 3),
    );
  });
}
