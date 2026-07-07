import 'episode.dart';
import 'source_type.dart';

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
