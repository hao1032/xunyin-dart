class BilibiliSearchResult {
  const BilibiliSearchResult({
    required this.title,
    required this.author,
    required this.bvid,
    required this.coverUrl,
    required this.detailUrl,
    this.description,
    this.durationSeconds,
    this.publishedAt,
  });

  final String title;
  final String author;
  final String bvid;
  final String coverUrl;
  final String detailUrl;
  final String? description;
  final int? durationSeconds;
  final DateTime? publishedAt;
}

class BilibiliVideo {
  const BilibiliVideo({
    required this.title,
    required this.bvid,
    required this.author,
    required this.coverUrl,
    required this.detailUrl,
    this.description,
    this.durationSeconds,
    this.publishedAt,
    this.pages = const [],
  });

  final String title;
  final String bvid;
  final String author;
  final String coverUrl;
  final String detailUrl;
  final String? description;
  final int? durationSeconds;
  final DateTime? publishedAt;

  /// 分P信息。一个合集中的视频也可能包含多个分P。
  final List<BilibiliPage> pages;
}

class BilibiliPage {
  const BilibiliPage({
    required this.page,
    required this.cid,
    required this.part,
    this.durationSeconds,
  });
  final int page;
  final int cid;
  final String part;
  final int? durationSeconds;
}

class BilibiliCollection {
  const BilibiliCollection({
    required this.id,
    required this.name,
    this.videos = const [],
  });

  final int id;
  final String name;
  final List<BilibiliVideo> videos;
}

class BilibiliVideoDetail {
  const BilibiliVideoDetail({
    required this.bvid,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.ownerMid,
    required this.ownerName,
    this.collection,
    this.pages = const [],
  });

  final String bvid;
  final String title;
  final String description;
  final String coverUrl;
  final int ownerMid;
  final String ownerName;
  final BilibiliCollection? collection;
  final List<BilibiliPage> pages;

  /// B 站的合集概念包含 UGC 合集和单视频分P两种情况。
  bool get isCollection => collection != null || pages.isNotEmpty;

  int? get collectionId => collection?.id;
  String? get collectionName => collection?.name;
  List<BilibiliVideo> get collectionVideos => collection?.videos ?? const [];
}
