class ApplePodcastResult {
  const ApplePodcastResult({
    required this.name,
    required this.artist,
    required this.artworkUrl,
    required this.detailUrl,
    required this.feedUrl,
    this.collectionId,
    this.publishedAt,
    this.durationSeconds,
    this.episodeId,
    this.collectionName,
  });

  final String name;
  final String artist;
  final String artworkUrl;
  final String detailUrl;
  final String feedUrl;
  final int? collectionId;

  /// 单集发布时间（Apple 的 trackTimeMillis/releaseDate）。
  final DateTime? publishedAt;

  /// 单集时长（秒）。
  final int? durationSeconds;
  final int? episodeId;
  final String? collectionName;
}

class RssEpisode {
  const RssEpisode({
    required this.title,
    required this.audioUrl,
    this.description,
    this.publishedAt,
    this.durationSeconds,
    this.audioBytes,
  });

  final String title;
  final String audioUrl;
  final String? description;
  final DateTime? publishedAt;
  final int? durationSeconds;
  final int? audioBytes;
}

class RssFeed {
  const RssFeed({
    required this.title,
    required this.author,
    required this.episodes,
    this.description,
    this.artworkUrl,
  });

  final String title;
  final String? author;
  final String? description;
  final String? artworkUrl;
  final List<RssEpisode> episodes;
}
