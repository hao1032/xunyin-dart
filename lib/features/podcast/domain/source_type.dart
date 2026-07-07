enum SourceType {
  bilibili,
  applePodcast,
  rss;

  String get label {
    return switch (this) {
      SourceType.bilibili => 'B站',
      SourceType.applePodcast => '播客',
      SourceType.rss => 'RSS',
    };
  }
}
