import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_logger.dart';
import '../../series/model.dart';
import '../../episode/model.dart';
import '../../discover/model.dart';
import 'client.dart';

final bilibiliRepositoryProvider = Provider<BilibiliRepository>((ref) {
  return BilibiliRepository(ref.watch(bilibiliClientProvider));
});

class BilibiliRepository {
  const BilibiliRepository(this._client);

  final BilibiliClient _client;

  Future<List<SearchResult>> search(
    String keyword, {
    int page = 1,
    int pageSize = 20,
  }) async {
    if (keyword.trim().isEmpty) return const [];
    AppLogger.result(
      'search',
      area: 'bilibili',
      message: 'start',
      data: {'keyword': keyword.trim(), 'page': page, 'pageSize': pageSize},
    );
    final rows = await _client.searchVideos(
      keyword.trim(),
      page: page,
      pageSize: pageSize,
    );
    final results = rows.map(_searchResultFromJson).toList();
    final missingBvidCount = results
        .where((result) => result.bvid == null)
        .length;
    AppLogger.result(
      'search',
      area: 'bilibili',
      data: {
        'keyword': keyword.trim(),
        'page': page,
        'pageSize': pageSize,
        'count': results.length,
        'missingBvidCount': missingBvidCount,
      },
    );
    return results;
  }

  Future<Series> resolveAsSeries(SearchResult result) async {
    final bvid = _normalizeBvid(result.bvid);
    if (bvid == null) {
      throw ArgumentError('B站搜索结果缺少 bvid');
    }
    AppLogger.result(
      'resolve_as_series',
      area: 'bilibili',
      message: 'start',
      data: {'bvid': bvid, 'title': result.title},
    );
    final detail = await _client.videoDetail(bvid);
    final seasonEpisodes = _episodesFromUgcSeason(detail);
    if (seasonEpisodes.isNotEmpty) {
      final series = _seriesFromDetail(
        detail,
        episodes: seasonEpisodes,
        collection: true,
      );
      AppLogger.result(
        'resolve_as_series',
        area: 'bilibili',
        message: 'collection',
        data: {'seriesId': series.id, 'episodeCount': series.episodes.length},
      );
      return series;
    }

    final pageEpisodes = _episodesFromPages(detail);
    if (pageEpisodes.length > 1) {
      final series = _seriesFromDetail(detail, episodes: pageEpisodes);
      AppLogger.result(
        'resolve_as_series',
        area: 'bilibili',
        message: 'multipart',
        data: {'seriesId': series.id, 'episodeCount': series.episodes.length},
      );
      return series;
    }

    final series = _seriesFromDetail(
      detail,
      episodes: [_singleEpisode(detail)],
    );
    AppLogger.result(
      'resolve_as_series',
      area: 'bilibili',
      message: 'single',
      data: {'seriesId': series.id, 'episodeCount': series.episodes.length},
    );
    return series;
  }

  Future<BilibiliEpisodeContext> resolveEpisodeContext(
    SearchResult result,
  ) async {
    final bvid = _normalizeBvid(result.bvid);
    if (bvid == null) {
      throw ArgumentError('B站搜索结果缺少 bvid');
    }
    AppLogger.result(
      'resolve_episode_context',
      area: 'bilibili',
      message: 'start',
      data: {'bvid': bvid, 'title': result.title},
    );
    final detail = await _client.videoDetail(bvid);
    final episode = _singleEpisode(detail);
    Series? collectionSeries;

    final seasonEpisodes = _episodesFromUgcSeason(detail);
    if (seasonEpisodes.isNotEmpty) {
      collectionSeries = _seriesFromDetail(
        detail,
        episodes: seasonEpisodes,
        collection: true,
      );
    } else {
      final pageEpisodes = _episodesFromPages(detail);
      if (pageEpisodes.length > 1) {
        collectionSeries = _seriesFromDetail(detail, episodes: pageEpisodes);
      }
    }

    final creatorSeries = _creatorSeriesFromDetail(detail, episode);
    AppLogger.result(
      'resolve_episode_context',
      area: 'bilibili',
      data: {
        'episodeId': episode.id,
        'collectionSeriesId': collectionSeries?.id,
        'creatorSeriesId': creatorSeries?.id,
      },
    );
    return BilibiliEpisodeContext(
      episode: episode,
      collectionSeries: collectionSeries,
      creatorSeries: creatorSeries,
    );
  }

  Future<Series> loadCreatorSeries(
    BilibiliCreatorSeries series, {
    int page = 1,
    int pageSize = 10,
  }) async {
    final mid = _midFromCreatorSeriesId(series.id);
    if (mid == null) return series;
    AppLogger.result(
      'load_creator_series',
      area: 'bilibili',
      message: 'start',
      data: {
        'seriesId': series.id,
        'mid': mid,
        'title': series.title,
        'page': page,
        'pageSize': pageSize,
      },
    );
    final rows = await _client.ownerVideos(mid, page: page, pageSize: pageSize);
    final episodes = <Episode>[];
    for (final row in rows) {
      final bvid = _normalizeBvid(row['bvid'] as String?);
      if (bvid == null) continue;
      try {
        episodes.add(_singleEpisode(await _client.videoDetail(bvid)));
      } catch (error, stackTrace) {
        AppLogger.failure(
          'load_creator_episode_detail',
          error,
          area: 'bilibili',
          stackTrace: stackTrace,
          data: {'seriesId': series.id, 'mid': mid, 'bvid': bvid},
        );
      }
    }
    final loaded = series.copyWith(episodes: episodes);
    AppLogger.result(
      'load_creator_series',
      area: 'bilibili',
      data: {
        'seriesId': loaded.id,
        'mid': mid,
        'page': page,
        'pageSize': pageSize,
        'episodeCount': loaded.episodes.length,
      },
    );
    return loaded;
  }

  Future<String> resolveMediaUrl(Episode episode) {
    final bvid = episode.bvid;
    final cid = episode.cid;
    if (bvid == null || cid == null) {
      throw ArgumentError('B站 Episode 缺少 bvid 或 cid');
    }
    AppLogger.result(
      'resolve_media_url',
      area: 'bilibili',
      message: 'start',
      data: {'episodeId': episode.id, 'bvid': bvid, 'cid': cid},
    );
    return _client.mediaUrl(bvid: bvid, cid: cid);
  }

  SearchResult _searchResultFromJson(Map<String, dynamic> json) {
    final bvid = _normalizeBvid(json['bvid'] as String?);
    final title = _stripHtml(json['title'] as String? ?? '未命名视频');
    return SearchResult(
      id: bvid ?? json['aid']?.toString() ?? title,
      title: title,
      sourceType: SourceType.bilibili,
      originalUrl: 'https://www.bilibili.com/video/${bvid ?? ''}',
      subtitle: json['author'] as String?,
      imageUrl: _normalizeImageUrl(json['pic'] as String?),
      duration: _durationFromSearch(json['duration']),
      publishedAt: _dateTimeFromSeconds(json['pubdate'] as num?),
      bvid: bvid,
      bilibiliKind: bvid == null
          ? BilibiliResultKind.unavailable
          : BilibiliResultKind.unknown,
    );
  }

  Series _seriesFromDetail(
    Map<String, dynamic> detail, {
    required List<Episode> episodes,
    bool collection = false,
  }) {
    final bvid = detail['bvid'] as String? ?? episodes.first.bvid ?? '';
    final owner = detail['owner'] is Map
        ? (detail['owner'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final season = detail['ugc_season'] is Map
        ? (detail['ugc_season'] as Map).cast<String, dynamic>()
        : null;
    final detailTitle = detail['title'] as String?;
    final title = collection
        ? (season?['title'] as String?) ?? detailTitle ?? 'B站合集'
        : detailTitle ?? 'B站节目';
    return BilibiliCollectionSeries(
      id: collection ? 'bili-season-${season?['id'] ?? bvid}' : 'bili-$bvid',
      title: title,
      originalUrl: 'https://www.bilibili.com/video/$bvid',
      description: detail['desc'] as String?,
      author: owner['name'] as String?,
      imageUrl: _normalizeImageUrl(detail['pic'] as String?),
      creator: _creatorSeriesFromOwner(detail),
      episodes: episodes,
    );
  }

  List<Episode> _episodesFromUgcSeason(Map<String, dynamic> detail) {
    final season = detail['ugc_season'];
    if (season is! Map) return const [];
    final sections = season['sections'];
    if (sections is! List) return const [];
    final episodes = <Episode>[];
    for (final section in sections.whereType<Map>()) {
      final rawEpisodes = section['episodes'];
      if (rawEpisodes is! List) continue;
      for (final raw in rawEpisodes.whereType<Map>()) {
        final json = raw.cast<String, dynamic>();
        final bvid = json['bvid'] as String?;
        final cid = (json['cid'] as num?)?.toInt();
        if (bvid == null || cid == null) continue;
        episodes.add(
          Episode(
            id: 'bili-$bvid-$cid',
            seriesId: 'bili-season-${season['id'] ?? detail['bvid']}',
            title: json['title'] as String? ?? '未命名合集条目',
            sourceType: SourceType.bilibili,
            originalUrl: 'https://www.bilibili.com/video/$bvid',
            author: _ownerName(detail),
            imageUrl: _normalizeImageUrl(
              json['arc'] is Map
                  ? (json['arc'] as Map)['pic'] as String?
                  : detail['pic'] as String?,
            ),
            duration: _durationFromSeconds(
              json['duration'] as num? ??
                  (json['arc'] is Map
                      ? (json['arc'] as Map)['duration'] as num?
                      : null),
            ),
            publishedAt: _dateTimeFromSeconds(
              json['arc'] is Map
                  ? (json['arc'] as Map)['pubdate'] as num?
                  : null,
            ),
            bvid: bvid,
            aid: (json['aid'] as num?)?.toInt(),
            cid: cid,
            page: episodes.length + 1,
          ),
        );
      }
    }
    return episodes;
  }

  List<Episode> _episodesFromPages(Map<String, dynamic> detail) {
    final pages = detail['pages'];
    if (pages is! List) return const [];
    final bvid = detail['bvid'] as String? ?? '';
    return pages.whereType<Map>().map((raw) {
      final json = raw.cast<String, dynamic>();
      final page = (json['page'] as num?)?.toInt() ?? 1;
      final cid = (json['cid'] as num?)?.toInt() ?? 0;
      return Episode(
        id: 'bili-$bvid-$cid',
        seriesId: 'bili-$bvid',
        title:
            json['part'] as String? ?? detail['title'] as String? ?? '分P $page',
        sourceType: SourceType.bilibili,
        originalUrl: 'https://www.bilibili.com/video/$bvid?p=$page',
        author: _ownerName(detail),
        imageUrl: _normalizeImageUrl(detail['pic'] as String?),
        duration: _durationFromSeconds(json['duration'] as num?),
        publishedAt: _dateTimeFromSeconds(detail['pubdate'] as num?),
        bvid: bvid,
        aid: (detail['aid'] as num?)?.toInt(),
        cid: cid,
        page: page,
      );
    }).toList();
  }

  Episode _singleEpisode(Map<String, dynamic> detail) {
    final bvid = detail['bvid'] as String? ?? '';
    final pages = detail['pages'];
    final firstPage = pages is List && pages.isNotEmpty && pages.first is Map
        ? (pages.first as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final cid =
        (firstPage['cid'] as num?)?.toInt() ??
        (detail['cid'] as num?)?.toInt() ??
        0;
    return Episode(
      id: 'bili-$bvid-$cid',
      seriesId: 'bili-single-${_ownerMid(detail) ?? bvid}',
      title: detail['title'] as String? ?? 'B站单集',
      sourceType: SourceType.bilibili,
      originalUrl: 'https://www.bilibili.com/video/$bvid',
      description: detail['desc'] as String?,
      author: _ownerName(detail),
      imageUrl: _normalizeImageUrl(detail['pic'] as String?),
      duration: _durationFromSeconds(
        detail['duration'] as num? ?? firstPage['duration'] as num?,
      ),
      publishedAt: _dateTimeFromSeconds(detail['pubdate'] as num?),
      bvid: bvid,
      aid: (detail['aid'] as num?)?.toInt(),
      cid: cid,
      page: 1,
    );
  }

  Series? _creatorSeriesFromDetail(
    Map<String, dynamic> detail,
    Episode episode,
  ) {
    final creator = _creatorSeriesFromOwner(detail, fallbackEpisode: episode);
    if (creator == null) return null;
    return creator.copyWith(episodes: [episode]);
  }

  BilibiliCreatorSeries? _creatorSeriesFromOwner(
    Map<String, dynamic> detail, {
    Episode? fallbackEpisode,
  }) {
    final owner = detail['owner'];
    if (owner is! Map) return null;
    final name = owner['name'] as String?;
    if (name == null || name.trim().isEmpty) return null;
    final mid = (owner['mid'] as num?)?.toInt();
    return BilibiliCreatorSeries(
      id: 'bili-up-${mid ?? fallbackEpisode?.bvid ?? fallbackEpisode?.id ?? detail['bvid'] ?? detail['aid'] ?? name}',
      title: name,
      originalUrl: mid == null
          ? fallbackEpisode?.originalUrl ??
                'https://www.bilibili.com/video/${detail['bvid'] ?? ''}'
          : 'https://space.bilibili.com/$mid',
      author: name,
      description: owner['sign'] as String?,
      imageUrl:
          _normalizeImageUrl(owner['face'] as String?) ??
          fallbackEpisode?.imageUrl ??
          _normalizeImageUrl(detail['pic'] as String?),
    );
  }

  String? _ownerName(Map<String, dynamic> detail) {
    final owner = detail['owner'];
    return owner is Map ? owner['name'] as String? : null;
  }

  int? _ownerMid(Map<String, dynamic> detail) {
    final owner = detail['owner'];
    return owner is Map ? (owner['mid'] as num?)?.toInt() : null;
  }

  int? _midFromCreatorSeriesId(String id) {
    if (!id.startsWith('bili-up-')) return null;
    return int.tryParse(id.substring('bili-up-'.length));
  }

  Duration? _durationFromSeconds(num? seconds) {
    final value = seconds?.toInt();
    if (value == null || value <= 0) return null;
    return Duration(seconds: value);
  }

  Duration? _durationFromSearch(Object? value) {
    if (value is num) return _durationFromSeconds(value);
    if (value is! String || value.trim().isEmpty) return null;
    final parts = value.split(':').map(int.tryParse).toList();
    if (parts.any((part) => part == null)) return null;
    if (parts.length == 2) {
      return Duration(minutes: parts[0]!, seconds: parts[1]!);
    }
    if (parts.length == 3) {
      return Duration(hours: parts[0]!, minutes: parts[1]!, seconds: parts[2]!);
    }
    return null;
  }

  DateTime? _dateTimeFromSeconds(num? seconds) {
    final value = seconds?.toInt();
    if (value == null || value <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(value * 1000);
  }

  String _stripHtml(String input) {
    return input.replaceAll(RegExp('<[^>]+>'), '');
  }

  String? _normalizeBvid(String? bvid) {
    final value = bvid?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String? _normalizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('//')) return 'https:$url';
    return url;
  }
}

class BilibiliEpisodeContext {
  const BilibiliEpisodeContext({
    required this.episode,
    this.collectionSeries,
    this.creatorSeries,
  });

  final Episode episode;
  final Series? collectionSeries;
  final Series? creatorSeries;
}
