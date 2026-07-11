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

  factory DownloadedEpisode.fromJson(Map<String, Object?> json) {
    return DownloadedEpisode(
      episode: Episode.fromJson(
        (json['episode'] as Map).cast<String, Object?>(),
      ),
      filePath: json['filePath'] as String,
      bytes: json['bytes'] as int,
      downloadedAt:
          DateTime.tryParse(json['downloadedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
