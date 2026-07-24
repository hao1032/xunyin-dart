import 'package:flutter/material.dart';

import '../bilibili/client.dart';
import '../../core/utils.dart';
import 'source.dart';

class BilibiliDiscoverySource extends DiscoverySource {
  BilibiliDiscoverySource(this._client);

  final BilibiliClient _client;

  @override
  String get id => 'bilibili';

  @override
  String get name => 'B站';

  @override
  IconData get icon => Icons.video_library_outlined;

  @override
  Future<List<DiscoveryItem>> search(String keyword) async {
    final results = await _client.searchVideos(keyword);
    return results
        .map(
          (result) => DiscoveryItem(
            source: this,
            sourceItemId: result.bvid,
            title: result.title,
            author: result.author,
            imageUrl: result.coverUrl,
            description: result.description,
            durationSeconds: result.durationSeconds,
            publishedAt: result.publishedAt,
            detailUrl: result.detailUrl,
          ),
        )
        .toList();
  }

  @override
  Future<DiscoveryDetail> loadDetail(DiscoveryItem item) async {
    final detail = await _client.getVideoDetail(item.sourceItemId);
    final entries = <DiscoveryDetailEntry>[
      ...detail.pages.map(
        (page) => DiscoveryDetailEntry(
          title: 'P${page.page} ${page.part.isEmpty ? '未命名分P' : page.part}',
          subtitle: formatDuration(page.durationSeconds),
        ),
      ),
      ...detail.collectionVideos.map(
        (video) => DiscoveryDetailEntry(
          title: video.title,
          subtitle: '${video.author}  ${formatDuration(video.durationSeconds)}',
          description: video.description,
        ),
      ),
    ];
    return DiscoveryDetail(
      title: detail.title,
      author: detail.ownerName,
      imageUrl: detail.coverUrl,
      description: detail.description,
      entries: entries,
    );
  }
}
