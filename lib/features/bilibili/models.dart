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
