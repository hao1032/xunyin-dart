import 'episode.dart';
import 'source_type.dart';

class PodcastShow {
  const PodcastShow({
    required this.id,
    required this.title,
    required this.sourceType,
    required this.originalUrl,
    this.description,
    this.author,
    this.imageUrl,
    this.feedUrl,
    this.episodes = const [],
  });

  final String id;
  final String title;
  final SourceType sourceType;
  final String originalUrl;
  final String? description;
  final String? author;
  final String? imageUrl;
  final String? feedUrl;
  final List<Episode> episodes;

  PodcastShow copyWith({List<Episode>? episodes}) {
    return PodcastShow(
      id: id,
      title: title,
      sourceType: sourceType,
      originalUrl: originalUrl,
      description: description,
      author: author,
      imageUrl: imageUrl,
      feedUrl: feedUrl,
      episodes: episodes ?? this.episodes,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'sourceType': sourceType.name,
    'originalUrl': originalUrl,
    'description': description,
    'author': author,
    'imageUrl': imageUrl,
    'feedUrl': feedUrl,
    'episodes': episodes.map((episode) => episode.toJson()).toList(),
  };

  factory PodcastShow.fromJson(Map<String, Object?> json) {
    final episodes = (json['episodes'] as List<dynamic>? ?? const [])
        .cast<Map<String, Object?>>()
        .map(Episode.fromJson)
        .toList();
    return PodcastShow(
      id: json['id'] as String,
      title: json['title'] as String,
      sourceType: SourceType.values.byName(json['sourceType'] as String),
      originalUrl: json['originalUrl'] as String,
      description: json['description'] as String?,
      author: json['author'] as String?,
      imageUrl: json['imageUrl'] as String?,
      feedUrl: json['feedUrl'] as String?,
      episodes: episodes,
    );
  }
}
