import '../podcast/model.dart';

enum BilibiliResultKind {
  collection,
  multipart,
  single,
  unavailable,
  unknown;

  String get label {
    return switch (this) {
      BilibiliResultKind.collection => '合集',
      BilibiliResultKind.multipart => '分P',
      BilibiliResultKind.single => '单集',
      BilibiliResultKind.unavailable => '不可识别',
      BilibiliResultKind.unknown => '待识别',
    };
  }
}

class SearchResult {
  const SearchResult({
    required this.id,
    required this.title,
    required this.sourceType,
    required this.originalUrl,
    this.subtitle,
    this.description,
    this.imageUrl,
    this.feedUrl,
    this.audioUrl,
    this.duration,
    this.publishedAt,
    this.showTitle,
    this.bvid,
    this.bilibiliKind = BilibiliResultKind.unknown,
  });

  final String id;
  final String title;
  final SourceType sourceType;
  final String originalUrl;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final String? feedUrl;
  final String? audioUrl;
  final Duration? duration;
  final DateTime? publishedAt;
  final String? showTitle;
  final String? bvid;
  final BilibiliResultKind bilibiliKind;
}
