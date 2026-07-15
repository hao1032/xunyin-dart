import '../episode/model.dart';

class DownloadedEpisode {
  const DownloadedEpisode({
    required this.episode,
    required this.filePath,
    required this.bytes,
    required this.downloadedAt,
  });

  final Episode episode;
  final String filePath;
  final int bytes;
  final DateTime downloadedAt;

  Map<String, Object?> toJson() => {
    'episode': episode.toJson(),
    'filePath': filePath,
    'bytes': bytes,
    'downloadedAt': downloadedAt.toIso8601String(),
  };

  static DownloadedEpisode? tryFromJson(Map<String, Object?> json) {
    final episodeJson = json['episode'];
    if (episodeJson is! Map) return null;
    final episode = Episode.tryFromJson(episodeJson.cast<String, Object?>());
    if (episode == null) return null;
    final filePath = json['filePath'];
    final bytes = json['bytes'];
    final downloadedAt = DateTime.tryParse(
      json['downloadedAt'] as String? ?? '',
    );
    if (filePath is! String || bytes is! num || downloadedAt == null) {
      return null;
    }
    return DownloadedEpisode(
      episode: episode,
      filePath: filePath,
      bytes: bytes.toInt(),
      downloadedAt: downloadedAt,
    );
  }

  factory DownloadedEpisode.fromJson(Map<String, Object?> json) {
    final downloaded = tryFromJson(json);
    if (downloaded == null) {
      throw FormatException('Invalid downloaded episode JSON');
    }
    return downloaded;
  }
}
