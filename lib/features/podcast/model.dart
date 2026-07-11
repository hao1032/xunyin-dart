enum SourceType {
  bilibili,
  applePodcast,
  rss;

  String get label {
    return switch (this) {
      SourceType.bilibili => 'B站',
      SourceType.applePodcast => '播客',
      SourceType.rss => 'RSS',
    };
  }
}

class Episode {
  const Episode({
    required this.id,
    required this.showId,
    required this.title,
    required this.sourceType,
    required this.originalUrl,
    this.description,
    this.author,
    this.imageUrl,
    this.audioUrl,
    this.duration,
    this.publishedAt,
    this.bvid,
    this.aid,
    this.cid,
    this.page,
  });

  final String id;
  final String showId;
  final String title;
  final SourceType sourceType;
  final String originalUrl;
  final String? description;
  final String? author;
  final String? imageUrl;
  final String? audioUrl;
  final Duration? duration;
  final DateTime? publishedAt;
  final String? bvid;
  final int? aid;
  final int? cid;
  final int? page;

  Map<String, Object?> toJson() => {
    'id': id,
    'showId': showId,
    'title': title,
    'sourceType': sourceType.name,
    'originalUrl': originalUrl,
    'description': description,
    'author': author,
    'imageUrl': imageUrl,
    'audioUrl': audioUrl,
    'duration': duration?.inMilliseconds,
    'publishedAt': publishedAt?.toIso8601String(),
    'bvid': bvid,
    'aid': aid,
    'cid': cid,
    'page': page,
  };

  factory Episode.fromJson(Map<String, Object?> json) {
    return Episode(
      id: json['id'] as String,
      showId: json['showId'] as String,
      title: json['title'] as String,
      sourceType: SourceType.values.byName(json['sourceType'] as String),
      originalUrl: json['originalUrl'] as String,
      description: json['description'] as String?,
      author: json['author'] as String?,
      imageUrl: json['imageUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      duration: json['duration'] == null
          ? null
          : Duration(milliseconds: json['duration'] as int),
      publishedAt: json['publishedAt'] == null
          ? null
          : DateTime.tryParse(json['publishedAt'] as String),
      bvid: json['bvid'] as String?,
      aid: json['aid'] as int?,
      cid: json['cid'] as int?,
      page: json['page'] as int?,
    );
  }
}

class PlayableItem {
  const PlayableItem({
    required this.id,
    required this.title,
    required this.sourceType,
    required this.originalUrl,
    this.author,
    this.imageUrl,
    this.audioUrl,
    this.bvid,
    this.cid,
  });

  final String id;
  final String title;
  final SourceType sourceType;
  final String originalUrl;
  final String? author;
  final String? imageUrl;
  final String? audioUrl;
  final String? bvid;
  final int? cid;

  factory PlayableItem.fromEpisode(Episode episode) {
    return PlayableItem(
      id: episode.id,
      title: episode.title,
      sourceType: episode.sourceType,
      originalUrl: episode.originalUrl,
      author: episode.author,
      imageUrl: episode.imageUrl,
      audioUrl: episode.audioUrl,
      bvid: episode.bvid,
      cid: episode.cid,
    );
  }
}
