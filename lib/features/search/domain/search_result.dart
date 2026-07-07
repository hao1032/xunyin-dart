import '../../podcast/domain/source_type.dart';

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
    this.imageUrl,
    this.feedUrl,
    this.bvid,
    this.bilibiliKind = BilibiliResultKind.unknown,
  });

  final String id;
  final String title;
  final SourceType sourceType;
  final String originalUrl;
  final String? subtitle;
  final String? imageUrl;
  final String? feedUrl;
  final String? bvid;
  final BilibiliResultKind bilibiliKind;
}
