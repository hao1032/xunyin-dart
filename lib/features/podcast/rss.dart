import 'package:xml/xml.dart';
import 'package:intl/intl.dart';

import '../../core/exceptions.dart';
import 'models.dart';

class RssParser {
  static RssFeed parse(String xmlText) {
    if (xmlText.trim().isEmpty) throw const DataFetchException('RSS 内容为空');
    try {
      final document = XmlDocument.parse(xmlText);
      final channel = document.findAllElements('channel').firstOrNull;
      if (channel == null) throw const DataFetchException('RSS 缺少 channel');
      final episodes = <RssEpisode>[];
      for (final item in channel.findElements('item')) {
        final enclosure = item.findElements('enclosure').firstOrNull;
        final audioUrl = enclosure?.getAttribute('url');
        if (audioUrl == null || audioUrl.isEmpty) continue;
        episodes.add(
          RssEpisode(
            title: _childText(item, {'title'}) ?? '',
            description: _childText(item, {'description'}),
            audioUrl: audioUrl,
            audioBytes: int.tryParse(enclosure?.getAttribute('length') ?? ''),
            publishedAt: _parseDate(
              _childText(item, {'pubDate', 'date', 'published', 'updated'}),
            ),
            durationSeconds: _duration(_childText(item, {'duration'})),
          ),
        );
      }
      return RssFeed(
        title:
            channel.findElements('title').firstOrNull?.innerText.trim() ?? '',
        author: channel.findElements('author').firstOrNull?.innerText.trim(),
        description: channel
            .findElements('description')
            .firstOrNull
            ?.innerText
            .trim(),
        artworkUrl: channel
            .findElements('image')
            .firstOrNull
            ?.findElements('url')
            .firstOrNull
            ?.innerText
            .trim(),
        episodes: episodes,
      );
    } on DataFetchException {
      rethrow;
    } on Object catch (error) {
      throw DataFetchException('RSS XML 无效', cause: error);
    }
  }

  static int? _duration(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.trim().split(':').map(int.tryParse).toList();
    if (parts.any((part) => part == null)) return int.tryParse(value.trim());
    if (parts.length == 3) return parts[0]! * 3600 + parts[1]! * 60 + parts[2]!;
    if (parts.length == 2) return parts[0]! * 60 + parts[1]!;
    return parts.first;
  }

  static String? _childText(XmlElement element, Set<String> names) {
    for (final child in element.children.whereType<XmlElement>()) {
      if (names.contains(child.name.local)) return child.innerText.trim();
    }
    return null;
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    final iso = DateTime.tryParse(value);
    if (iso != null) return iso.toLocal();
    for (final pattern in [
      'EEE, dd MMM yyyy HH:mm:ss Z',
      'EEE, dd MMM yyyy HH:mm Z',
    ]) {
      try {
        return DateFormat(pattern, 'en_US').parse(value).toLocal();
      } on FormatException {
        // Try the next common RSS date format.
      }
    }
    return null;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
