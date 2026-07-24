import 'package:flutter/material.dart';

import '../../core/utils.dart';
import '../podcast/client.dart';
import 'source.dart';

class ApplePodcastDiscoverySource extends DiscoverySource {
  ApplePodcastDiscoverySource(this._apple, this._rss);

  final ApplePodcastClient _apple;
  final RssClient _rss;

  @override
  String get id => 'apple-podcast';

  @override
  String get name => 'Apple Podcasts';

  @override
  IconData get icon => Icons.podcasts_outlined;

  @override
  Future<List<DiscoveryItem>> search(String keyword) async {
    final results = await _apple.search(keyword);
    return results
        .map(
          (result) => DiscoveryItem(
            source: this,
            sourceItemId: result.feedUrl,
            title: result.name,
            author: result.artist,
            imageUrl: result.artworkUrl,
            durationSeconds: result.durationSeconds,
            publishedAt: result.publishedAt,
            detailUrl: result.detailUrl,
          ),
        )
        .toList();
  }

  @override
  Future<DiscoveryDetail> loadDetail(DiscoveryItem item) async {
    final feed = await _rss.loadFeed(item.sourceItemId);
    return DiscoveryDetail(
      title: feed.title,
      author: feed.author,
      imageUrl: feed.artworkUrl,
      description: feed.description,
      entries: feed.episodes
          .map(
            (episode) => DiscoveryDetailEntry(
              title: episode.title,
              subtitle:
                  '${formatDate(episode.publishedAt)}  ${formatDuration(episode.durationSeconds)}',
              description: episode.description,
            ),
          )
          .toList(),
    );
  }
}
