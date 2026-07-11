import '../podcast/model.dart';

sealed class AudioShow {
  const AudioShow({
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
  String get _jsonKind;

  AudioShow copyWith({List<Episode>? episodes});

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'kind': _jsonKind,
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
    'kind': _jsonKind,
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

  factory AudioShow.fromJson(Map<String, Object?> json) {
    final sourceType = SourceType.values.byName(json['sourceType'] as String);
    final kind = _kindFromJson(json, sourceType);
    final episodes = _episodesFromJson(json);

    return switch (kind) {
      _AudioShowKind.bilibiliCreator => BilibiliCreatorShow(
        id: json['id'] as String,
        title: json['title'] as String,
        originalUrl: json['originalUrl'] as String,
        description: json['description'] as String?,
        author: json['author'] as String?,
        imageUrl: json['imageUrl'] as String?,
        episodes: episodes,
      ),
      _AudioShowKind.rssPodcast => RssPodcastShow(
        id: json['id'] as String,
        title: json['title'] as String,
        originalUrl: json['originalUrl'] as String,
        feedUrl: json['feedUrl'] as String? ?? json['originalUrl'] as String,
        description: json['description'] as String?,
        author: json['author'] as String?,
        imageUrl: json['imageUrl'] as String?,
        episodes: episodes,
      ),
      _AudioShowKind.bilibiliCollection => BilibiliCollectionShow(
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

  static _AudioShowKind _kindFromJson(
    Map<String, Object?> json,
    SourceType sourceType,
  ) {
    final stored = json['kind'] as String?;
    if (stored == 'bilibiliCreator') return _AudioShowKind.bilibiliCreator;
    if (stored == 'rssPodcast') return _AudioShowKind.rssPodcast;
    if (stored == 'bilibiliCollection') {
      return _AudioShowKind.bilibiliCollection;
    }

    final id = json['id'] as String? ?? '';
    if (id.startsWith('bili-up-')) return _AudioShowKind.bilibiliCreator;
    if (sourceType == SourceType.bilibili) {
      return _AudioShowKind.bilibiliCollection;
    }
    return _AudioShowKind.rssPodcast;
  }
}

final class BilibiliCollectionShow extends AudioShow {
  const BilibiliCollectionShow({
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
  String get _jsonKind => 'bilibiliCollection';

  @override
  BilibiliCollectionShow copyWith({List<Episode>? episodes}) {
    return BilibiliCollectionShow(
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

final class BilibiliCreatorShow extends AudioShow {
  const BilibiliCreatorShow({
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
  String get _jsonKind => 'bilibiliCreator';

  @override
  BilibiliCreatorShow copyWith({List<Episode>? episodes}) {
    return BilibiliCreatorShow(
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

final class RssPodcastShow extends AudioShow {
  const RssPodcastShow({
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
  String get _jsonKind => 'rssPodcast';

  @override
  RssPodcastShow copyWith({List<Episode>? episodes}) {
    return RssPodcastShow(
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

enum _AudioShowKind { bilibiliCollection, bilibiliCreator, rssPodcast }
