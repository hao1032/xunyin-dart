import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bilibili/services/repository.dart';
import '../podcast/services/repository.dart';
import 'model.dart';

final channelServiceProvider = Provider<ChannelService>((ref) {
  return ChannelService(
    ref.watch(bilibiliRepositoryProvider),
    ref.watch(podcastRepositoryProvider),
  );
});

/// Loads any supported channel through one platform-independent entry point.
class ChannelService {
  const ChannelService(this._bilibili, this._podcast);

  final BilibiliRepository _bilibili;
  final PodcastRepository _podcast;

  Future<AudioShow> load(AudioShow channel) {
    return switch (channel) {
      BilibiliCreatorShow() => _bilibili.loadCreatorShow(channel),
      RssPodcastShow() => _loadRss(channel),
      BilibiliCollectionShow() => Future.value(channel),
    };
  }

  Future<AudioShow> _loadRss(RssPodcastShow channel) {
    final feedUrl = channel.feedUrl;
    if (feedUrl.isEmpty) return Future.value(channel);
    return _podcast.loadRssFeed(feedUrl, title: channel.title);
  }
}
