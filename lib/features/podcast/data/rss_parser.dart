import 'package:xml/xml.dart';

import '../domain/episode.dart';
import '../domain/podcast_show.dart';
import '../domain/source_type.dart';

class RssParser {
  PodcastShow parse(String xml, {required String feedUrl}) {
    final document = XmlDocument.parse(xml);
    final channel = document.findAllElements('channel').firstOrNull;
    if (channel == null) {
      throw const FormatException('RSS feed 缺少 channel');
    }
    final title = _text(channel, 'title') ?? '未命名播客';
    final imageUrl =
        _text(channel, 'image', child: 'url') ??
        channel.findAllElements('image').firstOrNull?.getAttribute('href');
    final show = PodcastShow(
      id: 'rss-$feedUrl',
      title: title,
      sourceType: SourceType.rss,
      originalUrl: _text(channel, 'link') ?? feedUrl,
      description: _text(channel, 'description'),
      author: _text(channel, 'author') ?? _text(channel, 'itunes:author'),
      imageUrl: imageUrl,
      feedUrl: feedUrl,
      episodes: const [],
    );
    final episodes = channel.findElements('item').map((item) {
      final enclosure = item.findElements('enclosure').firstOrNull;
      final guid =
          _text(item, 'guid') ?? _text(item, 'link') ?? _text(item, 'title');
      return Episode(
        id: 'rss-$guid',
        showId: show.id,
        title: _text(item, 'title') ?? '未命名单集',
        sourceType: SourceType.rss,
        originalUrl: _text(item, 'link') ?? feedUrl,
        description:
            _text(item, 'description') ?? _text(item, 'itunes:summary'),
        author: show.author,
        imageUrl:
            item
                .findElements('itunes:image')
                .firstOrNull
                ?.getAttribute('href') ??
            show.imageUrl,
        audioUrl: enclosure?.getAttribute('url'),
        publishedAt: DateTime.tryParse(_text(item, 'pubDate') ?? ''),
      );
    }).toList();
    return show.copyWith(episodes: episodes);
  }

  String? _text(XmlElement parent, String tag, {String? child}) {
    final element = parent.findElements(tag).firstOrNull;
    if (element == null) return null;
    if (child != null) {
      return element.findElements(child).firstOrNull?.innerText.trim();
    }
    final text = element.innerText.trim();
    return text.isEmpty ? null : text;
  }
}
