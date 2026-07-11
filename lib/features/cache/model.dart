import '../podcast/model.dart';

class CachedEpisode {
  const CachedEpisode({
    required this.episode,
    required this.filePath,
    required this.bytes,
    required this.cachedAt,
  });

  final Episode episode;
  final String filePath;
  final int bytes;
  final DateTime cachedAt;

  Map<String, Object?> toJson() => {
    'episode': episode.toJson(),
    'filePath': filePath,
    'bytes': bytes,
    'cachedAt': cachedAt.toIso8601String(),
  };

  factory CachedEpisode.fromJson(Map<String, Object?> json) {
    return CachedEpisode(
      episode: Episode.fromJson(
        (json['episode'] as Map).cast<String, Object?>(),
      ),
      filePath: json['filePath'] as String,
      bytes: json['bytes'] as int,
      cachedAt:
          DateTime.tryParse(json['cachedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
