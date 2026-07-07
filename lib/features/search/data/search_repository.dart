import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bilibili/data/bilibili_repository.dart';
import '../../podcast/data/podcast_repository.dart';
import '../../podcast/domain/source_type.dart';
import '../domain/search_result.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(
    ref.watch(bilibiliRepositoryProvider),
    ref.watch(podcastRepositoryProvider),
  );
});

enum SearchScope {
  bilibili,
  podcast,
  all;

  String get label {
    return switch (this) {
      SearchScope.bilibili => 'B站',
      SearchScope.podcast => '播客',
      SearchScope.all => '全部',
    };
  }
}

class SearchRepository {
  const SearchRepository(this._bilibiliRepository, this._podcastRepository);

  final BilibiliRepository _bilibiliRepository;
  final PodcastRepository _podcastRepository;

  Future<List<SearchResult>> search(String keyword, SearchScope scope) async {
    return switch (scope) {
      SearchScope.bilibili => _bilibiliRepository.search(keyword),
      SearchScope.podcast => _podcastRepository.searchApple(keyword),
      SearchScope.all => _searchAll(keyword),
    };
  }

  Future<List<SearchResult>> _searchAll(String keyword) async {
    final results = await Future.wait([
      _bilibiliRepository.search(keyword),
      _podcastRepository.searchApple(keyword),
    ]);
    return [
      ...results[0],
      ...results[1].where((item) => item.sourceType == SourceType.applePodcast),
    ];
  }
}
