import '../podcast/model.dart';

sealed class Series {
  const Series({
    required this.id,
    required this.title,
    required this.sourceType,
    required this.originalUrl,
    this.description,
    this.author,
    this.imageUrl,
    this.episodes = const [],
  });

  final String id;
  final String title;
  final SourceType sourceType;
  final String originalUrl;
  final String? description;
  final String? author;
  final String? imageUrl;
  final List<Episode> episodes;

  String get label;
  String get shortLabel;
  String get _jsonType;

  Series copyWith({List<Episode>? episodes});

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'type': _jsonType,
    'sourceType': sourceType.name,
    'originalUrl': originalUrl,
    'description': description,
    'author': author,
    'imageUrl': imageUrl,
    'episodes': episodes.map((episode) => episode.toJson()).toList(),
  };

  Map<String, Object?> _commonJson() => {
    'id': id,
    'title': title,
    'type': _jsonType,
    'sourceType': sourceType.name,
    'originalUrl': originalUrl,
    'description': description,
    'author': author,
    'imageUrl': imageUrl,
    'episodes': episodes.map((episode) => episode.toJson()).toList(),
  };

  static List<Episode> _episodesFromJson(Map<String, Object?> json) {
    return (json['episodes'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Episode.fromJson(item.cast<String, Object?>()))
        .toList();
  }

  factory Series.fromJson(Map<String, Object?> json) {
    final type = _typeFromJson(json);
    final episodes = _episodesFromJson(json);

    return switch (type) {
      _SeriesType.bilibiliCreator => BilibiliCreatorSeries(
        id: json['id'] as String,
        title: json['title'] as String,
        originalUrl: json['originalUrl'] as String,
        description: json['description'] as String?,
        author: json['author'] as String?,
        imageUrl: json['imageUrl'] as String?,
        episodes: episodes,
      ),
      _SeriesType.rssPodcast => RssPodcastSeries(
        id: json['id'] as String,
        title: json['title'] as String,
        originalUrl: json['originalUrl'] as String,
        feedUrl: json['feedUrl'] as String,
        description: json['description'] as String?,
        author: json['author'] as String?,
        imageUrl: json['imageUrl'] as String?,
        episodes: episodes,
      ),
      _SeriesType.bilibiliCollection => BilibiliCollectionSeries(
        id: json['id'] as String,
        title: json['title'] as String,
        originalUrl: json['originalUrl'] as String,
        description: json['description'] as String?,
        author: json['author'] as String?,
        imageUrl: json['imageUrl'] as String?,
        episodes: episodes,
      ),
    };
  }

  static _SeriesType _typeFromJson(Map<String, Object?> json) {
    final stored = json['type'] as String;
    if (stored == 'bilibiliCreator') return _SeriesType.bilibiliCreator;
    if (stored == 'rssPodcast') return _SeriesType.rssPodcast;
    if (stored == 'bilibiliCollection') {
      return _SeriesType.bilibiliCollection;
    }
    throw FormatException('Unknown series type: $stored');
  }
}

final class BilibiliCollectionSeries extends Series {
  const BilibiliCollectionSeries({
    required super.id,
    required super.title,
    required super.originalUrl,
    super.description,
    super.author,
    super.imageUrl,
    super.episodes,
  }) : super(sourceType: SourceType.bilibili);

  @override
  String get label => 'B站合集';

  @override
  String get shortLabel => '合集';

  @override
  String get _jsonType => 'bilibiliCollection';

  @override
  BilibiliCollectionSeries copyWith({List<Episode>? episodes}) {
    return BilibiliCollectionSeries(
      id: id,
      title: title,
      originalUrl: originalUrl,
      description: description,
      author: author,
      imageUrl: imageUrl,
      episodes: episodes ?? this.episodes,
    );
  }
}

final class BilibiliCreatorSeries extends Series {
  const BilibiliCreatorSeries({
    required super.id,
    required super.title,
    required super.originalUrl,
    super.description,
    super.author,
    super.imageUrl,
    super.episodes,
  }) : super(sourceType: SourceType.bilibili);

  @override
  String get label => 'B站UP主';

  @override
  String get shortLabel => 'UP主';

  @override
  String get _jsonType => 'bilibiliCreator';

  @override
  BilibiliCreatorSeries copyWith({List<Episode>? episodes}) {
    return BilibiliCreatorSeries(
      id: id,
      title: title,
      originalUrl: originalUrl,
      description: description,
      author: author,
      imageUrl: imageUrl,
      episodes: episodes ?? this.episodes,
    );
  }
}

final class RssPodcastSeries extends Series {
  const RssPodcastSeries({
    required super.id,
    required super.title,
    required super.originalUrl,
    required this.feedUrl,
    super.description,
    super.author,
    super.imageUrl,
    super.episodes,
  }) : super(sourceType: SourceType.rss);

  final String feedUrl;

  @override
  String get label => 'RSS播客';

  @override
  String get shortLabel => '播客';

  @override
  String get _jsonType => 'rssPodcast';

  @override
  RssPodcastSeries copyWith({List<Episode>? episodes}) {
    return RssPodcastSeries(
      id: id,
      title: title,
      originalUrl: originalUrl,
      feedUrl: feedUrl,
      description: description,
      author: author,
      imageUrl: imageUrl,
      episodes: episodes ?? this.episodes,
    );
  }

  @override
  Map<String, Object?> toJson() => {..._commonJson(), 'feedUrl': feedUrl};
}

enum _SeriesType { bilibiliCollection, bilibiliCreator, rssPodcast }
