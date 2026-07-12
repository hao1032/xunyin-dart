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
    required this.seriesId,
    required this.title,
    required this.sourceType,
    required this.originalUrl,
    this.description,
    this.author,
    this.imageUrl,
    this.mediaUrl,
    this.duration,
    this.publishedAt,
    this.bvid,
    this.aid,
    this.cid,
    this.page,
  });

  final String id;
  final String seriesId;
  final String title;
  final SourceType sourceType;
  final String originalUrl;
  final String? description;
  final String? author;
  final String? imageUrl;
  final String? mediaUrl;
  final Duration? duration;
  final DateTime? publishedAt;
  final String? bvid;
  final int? aid;
  final int? cid;
  final int? page;

  Map<String, Object?> toJson() => {
    'id': id,
    'seriesId': seriesId,
    'title': title,
    'sourceType': sourceType.name,
    'originalUrl': originalUrl,
    'description': description,
    'author': author,
    'imageUrl': imageUrl,
    'mediaUrl': mediaUrl,
    'duration': duration?.inMilliseconds,
    'publishedAt': publishedAt?.toIso8601String(),
    'bvid': bvid,
    'aid': aid,
    'cid': cid,
    'page': page,
  };

  static Episode? tryFromJson(Map<String, Object?> json) {
    final id = json['id'];
    final seriesId = json['seriesId'];
    final title = json['title'];
    final sourceTypeName = json['sourceType'];
    final originalUrl = json['originalUrl'];
    if (id is! String ||
        seriesId is! String ||
        title is! String ||
        sourceTypeName is! String ||
        originalUrl is! String) {
      return null;
    }

    final sourceType = SourceType.values
        .where((item) => item.name == sourceTypeName)
        .firstOrNull;
    if (sourceType == null) return null;

    final duration = json['duration'];
    final publishedAt = json['publishedAt'];
    final aid = json['aid'];
    final cid = json['cid'];
    final page = json['page'];

    return Episode(
      id: id,
      seriesId: seriesId,
      title: title,
      sourceType: sourceType,
      originalUrl: originalUrl,
      description: json['description'] as String?,
      author: json['author'] as String?,
      imageUrl: json['imageUrl'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      duration: duration is num
          ? Duration(milliseconds: duration.toInt())
          : null,
      publishedAt: publishedAt is String
          ? DateTime.tryParse(publishedAt)
          : null,
      bvid: json['bvid'] as String?,
      aid: aid is num ? aid.toInt() : null,
      cid: cid is num ? cid.toInt() : null,
      page: page is num ? page.toInt() : null,
    );
  }

  factory Episode.fromJson(Map<String, Object?> json) {
    final episode = tryFromJson(json);
    if (episode == null) {
      throw FormatException('Invalid episode JSON');
    }
    return episode;
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
    this.mediaUrl,
    this.bvid,
    this.cid,
  });

  final String id;
  final String title;
  final SourceType sourceType;
  final String originalUrl;
  final String? author;
  final String? imageUrl;
  final String? mediaUrl;
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
      mediaUrl: episode.mediaUrl,
      bvid: episode.bvid,
      cid: episode.cid,
    );
  }
}
