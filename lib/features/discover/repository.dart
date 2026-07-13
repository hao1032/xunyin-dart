import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bilibili/services/repository.dart';
import '../podcast/services/repository.dart';
import '../episode/model.dart';
import 'model.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(
    ref.watch(bilibiliRepositoryProvider),
    ref.watch(podcastRepositoryProvider),
  );
});

enum SearchScope {
  all,
  bilibili,
  podcast;

  String get label {
    return switch (this) {
      SearchScope.all => '全部',
      SearchScope.bilibili => 'B站',
      SearchScope.podcast => '播客',
    };
  }
}

class SearchRepository {
  const SearchRepository(this._bilibiliRepository, this._podcastRepository);

  final BilibiliRepository _bilibiliRepository;
  final PodcastRepository _podcastRepository;

  Future<List<SearchResult>> search(
    String keyword,
    SearchScope scope, {
    int page = 1,
    int pageSize = 20,
  }) async {
    return switch (scope) {
      SearchScope.bilibili => _bilibiliRepository.search(
        keyword,
        page: page,
        pageSize: pageSize,
      ),
      SearchScope.podcast => _podcastRepository.searchApple(keyword),
      SearchScope.all => _searchAll(keyword, page: page, pageSize: pageSize),
    };
  }

  Future<List<SearchResult>> _searchAll(
    String keyword, {
    required int page,
    required int pageSize,
  }) async {
    final results = await Future.wait([
      _bilibiliRepository.search(keyword, page: page, pageSize: pageSize),
      _podcastRepository.searchApple(keyword),
    ]);
    return [
      ...results[0],
      ...results[1].where((item) => item.sourceType == SourceType.applePodcast),
    ];
  }
}
