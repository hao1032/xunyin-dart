import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../podcast/domain/episode.dart';
import '../../podcast/domain/podcast_show.dart';
import '../../podcast/domain/source_type.dart';
import '../../search/domain/search_result.dart';
import 'bilibili_client.dart';

final bilibiliRepositoryProvider = Provider<BilibiliRepository>((ref) {
  return BilibiliRepository(ref.watch(bilibiliClientProvider));
});

class BilibiliRepository {
  const BilibiliRepository(this._client);

  final BilibiliClient _client;

  Future<List<SearchResult>> search(String keyword) async {
    if (keyword.trim().isEmpty) return const [];
    AppLogger.result(
      'search',
      area: 'bilibili',
      message: 'start',
      data: {'keyword': keyword.trim()},
    );
    final rows = await _client.searchVideos(keyword.trim());
    final results = rows.map(_searchResultFromJson).toList();
    final missingBvidCount = results
        .where((result) => result.bvid == null)
        .length;
    AppLogger.result(
      'search',
      area: 'bilibili',
      data: {
        'keyword': keyword.trim(),
        'count': results.length,
        'missingBvidCount': missingBvidCount,
      },
    );
    return results;
  }

  Future<PodcastShow> resolveAsShow(SearchResult result) async {
    final bvid = _normalizeBvid(result.bvid);
    if (bvid == null) {
      throw ArgumentError('B站搜索结果缺少 bvid');
    }
    AppLogger.result(
      'resolve_as_show',
      area: 'bilibili',
      message: 'start',
      data: {'bvid': bvid, 'title': result.title},
    );
    final detail = await _client.videoDetail(bvid);
    final seasonEpisodes = _episodesFromUgcSeason(detail);
    if (seasonEpisodes.isNotEmpty) {
      final show = _showFromDetail(
        detail,
        episodes: seasonEpisodes,
        collection: true,
      );
      AppLogger.result(
        'resolve_as_show',
        area: 'bilibili',
        message: 'collection',
        data: {'showId': show.id, 'episodeCount': show.episodes.length},
      );
      return show;
    }

    final pageEpisodes = _episodesFromPages(detail);
    if (pageEpisodes.length > 1) {
      final show = _showFromDetail(detail, episodes: pageEpisodes);
      AppLogger.result(
        'resolve_as_show',
        area: 'bilibili',
        message: 'multipart',
        data: {'showId': show.id, 'episodeCount': show.episodes.length},
      );
      return show;
    }

    final show = _showFromDetail(detail, episodes: [_singleEpisode(detail)]);
    AppLogger.result(
      'resolve_as_show',
      area: 'bilibili',
      message: 'single',
      data: {'showId': show.id, 'episodeCount': show.episodes.length},
    );
    return show;
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
    PodcastShow? collectionShow;

    final seasonEpisodes = _episodesFromUgcSeason(detail);
    if (seasonEpisodes.isNotEmpty) {
      collectionShow = _showFromDetail(
        detail,
        episodes: seasonEpisodes,
        collection: true,
      );
    } else {
      final pageEpisodes = _episodesFromPages(detail);
      if (pageEpisodes.length > 1) {
        collectionShow = _showFromDetail(detail, episodes: pageEpisodes);
      }
    }

    final creatorShow = _creatorShowFromDetail(detail, episode);
    AppLogger.result(
      'resolve_episode_context',
      area: 'bilibili',
      data: {
        'episodeId': episode.id,
        'collectionShowId': collectionShow?.id,
        'creatorShowId': creatorShow?.id,
      },
    );
    return BilibiliEpisodeContext(
      episode: episode,
      collectionShow: collectionShow,
      creatorShow: creatorShow,
    );
  }

  Future<PodcastShow> loadCreatorShow(PodcastShow show) async {
    final mid = _midFromCreatorShowId(show.id);
    if (mid == null) return show;
    AppLogger.result(
      'load_creator_show',
      area: 'bilibili',
      message: 'start',
      data: {'showId': show.id, 'mid': mid, 'title': show.title},
    );
    final rows = await _client.ownerVideos(mid);
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
          data: {'showId': show.id, 'mid': mid, 'bvid': bvid},
        );
      }
    }
    final loaded = show.copyWith(episodes: episodes);
    AppLogger.result(
      'load_creator_show',
      area: 'bilibili',
      data: {
        'showId': loaded.id,
        'mid': mid,
        'episodeCount': loaded.episodes.length,
      },
    );
    return loaded;
  }

  Future<String> resolveAudioUrl(Episode episode) {
    final bvid = episode.bvid;
    final cid = episode.cid;
    if (bvid == null || cid == null) {
      throw ArgumentError('B站 Episode 缺少 bvid 或 cid');
    }
    AppLogger.result(
      'resolve_audio_url',
      area: 'bilibili',
      message: 'start',
      data: {'episodeId': episode.id, 'bvid': bvid, 'cid': cid},
    );
    return _client.audioUrl(bvid: bvid, cid: cid);
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
      bvid: bvid,
      bilibiliKind: bvid == null
          ? BilibiliResultKind.unavailable
          : BilibiliResultKind.unknown,
    );
  }

  PodcastShow _showFromDetail(
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
    return PodcastShow(
      id: collection ? 'bili-season-${season?['id'] ?? bvid}' : 'bili-$bvid',
      title: title,
      sourceType: SourceType.bilibili,
      originalUrl: 'https://www.bilibili.com/video/$bvid',
      description: detail['desc'] as String?,
      author: owner['name'] as String?,
      imageUrl: _normalizeImageUrl(detail['pic'] as String?),
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
            showId: 'bili-season-${season['id'] ?? detail['bvid']}',
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
        showId: 'bili-$bvid',
        title:
            json['part'] as String? ?? detail['title'] as String? ?? '分P $page',
        sourceType: SourceType.bilibili,
        originalUrl: 'https://www.bilibili.com/video/$bvid?p=$page',
        author: _ownerName(detail),
        imageUrl: _normalizeImageUrl(detail['pic'] as String?),
        duration: _durationFromSeconds(json['duration'] as num?),
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
      showId: 'bili-single-${_ownerMid(detail) ?? bvid}',
      title: detail['title'] as String? ?? 'B站单集',
      sourceType: SourceType.bilibili,
      originalUrl: 'https://www.bilibili.com/video/$bvid',
      description: detail['desc'] as String?,
      author: _ownerName(detail),
      imageUrl: _normalizeImageUrl(detail['pic'] as String?),
      duration: _durationFromSeconds(
        detail['duration'] as num? ?? firstPage['duration'] as num?,
      ),
      bvid: bvid,
      aid: (detail['aid'] as num?)?.toInt(),
      cid: cid,
      page: 1,
    );
  }

  PodcastShow? _creatorShowFromDetail(
    Map<String, dynamic> detail,
    Episode episode,
  ) {
    final owner = detail['owner'];
    if (owner is! Map) return null;
    final name = owner['name'] as String?;
    if (name == null || name.trim().isEmpty) return null;
    final mid = (owner['mid'] as num?)?.toInt();
    return PodcastShow(
      id: 'bili-up-${mid ?? episode.bvid ?? episode.id}',
      title: name,
      sourceType: SourceType.bilibili,
      originalUrl: mid == null
          ? episode.originalUrl
          : 'https://space.bilibili.com/$mid',
      author: name,
      imageUrl: episode.imageUrl,
      episodes: [episode],
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

  int? _midFromCreatorShowId(String id) {
    if (!id.startsWith('bili-up-')) return null;
    return int.tryParse(id.substring('bili-up-'.length));
  }

  Duration? _durationFromSeconds(num? seconds) {
    final value = seconds?.toInt();
    if (value == null || value <= 0) return null;
    return Duration(seconds: value);
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
    this.collectionShow,
    this.creatorShow,
  });

  final Episode episode;
  final PodcastShow? collectionShow;
  final PodcastShow? creatorShow;
}
