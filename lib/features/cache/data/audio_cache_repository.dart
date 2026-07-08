import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/network/http_client.dart';
import '../../../core/storage/library_store.dart';
import '../../bilibili/data/bilibili_repository.dart';
import '../../podcast/domain/episode.dart';
import '../../podcast/domain/source_type.dart';
import '../domain/cached_episode.dart';

final audioCacheRepositoryProvider = Provider<AudioCacheRepository>((ref) {
  return AudioCacheRepository(
    ref.watch(dioProvider),
    ref.watch(libraryStoreProvider),
    ref.watch(bilibiliRepositoryProvider),
  );
});

class AudioCacheRepository {
  const AudioCacheRepository(this._dio, this._store, this._bilibiliRepository);

  final Dio _dio;
  final LibraryStore _store;
  final BilibiliRepository _bilibiliRepository;

  Future<List<CachedEpisode>> cachedEpisodes() async {
    final episodes = await _store.loadCachedEpisodes();
    final existing = <CachedEpisode>[];
    var changed = false;
    for (final cached in episodes) {
      final migrated = await _migrateCachedFileIfNeeded(cached);
      if (migrated != null) {
        existing.add(migrated);
        changed = changed || migrated.filePath != cached.filePath;
      } else {
        changed = true;
      }
    }
    if (changed) {
      for (final cached in existing) {
        await _store.saveCachedEpisode(cached);
      }
      for (final cached in episodes) {
        if (!existing.any((item) => item.episode.id == cached.episode.id)) {
          await _store.removeCachedEpisode(cached.episode.id);
        }
      }
    }
    return existing;
  }

  Future<CachedEpisode?> cachedEpisode(String episodeId) async {
    final episodes = await cachedEpisodes();
    for (final cached in episodes) {
      if (cached.episode.id == episodeId) return cached;
    }
    return null;
  }

  Future<bool> isCached(String episodeId) async {
    return (await cachedEpisode(episodeId)) != null;
  }

  Future<CachedEpisode> cache(Episode episode) async {
    final existing = await cachedEpisode(episode.id);
    if (existing != null) return existing;

    final audioUrl = await _audioUrlFor(episode);
    final directory = await _cacheDirectory();
    final extension = _extensionFor(episode, audioUrl);
    final file = File(
      '${directory.path}/${_safeFileName(episode.id)}$extension',
    );
    final temp = File('${file.path}.download');
    if (await temp.exists()) {
      await temp.delete();
    }

    AppLogger.result(
      'cache_episode',
      area: 'cache',
      message: 'start',
      data: {
        'episodeId': episode.id,
        'title': episode.title,
        'source': episode.sourceType.name,
      },
    );

    try {
      await _dio.download(
        audioUrl,
        temp.path,
        options: Options(headers: _downloadHeaders(episode)),
      );
      if (await file.exists()) {
        await file.delete();
      }
      await temp.rename(file.path);
      final cached = CachedEpisode(
        episode: episode,
        filePath: file.path,
        bytes: await file.length(),
        cachedAt: DateTime.now(),
      );
      await _store.saveCachedEpisode(cached);
      AppLogger.result(
        'cache_episode',
        area: 'cache',
        data: {
          'episodeId': episode.id,
          'path': file.path,
          'bytes': cached.bytes,
        },
      );
      return cached;
    } catch (error, stackTrace) {
      if (await temp.exists()) {
        await temp.delete();
      }
      AppLogger.failure(
        'cache_episode',
        error,
        area: 'cache',
        stackTrace: stackTrace,
        data: {'episodeId': episode.id, 'title': episode.title},
      );
      rethrow;
    }
  }

  Future<void> remove(String episodeId) async {
    final cached = await cachedEpisode(episodeId);
    if (cached != null) {
      final file = File(cached.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _store.removeCachedEpisode(episodeId);
    AppLogger.result(
      'remove_cached_episode',
      area: 'cache',
      data: {'episodeId': episodeId},
    );
  }

  Future<String?> localPathFor(Episode episode) async {
    final cached = await cachedEpisode(episode.id);
    if (cached == null) return null;
    return cached.filePath;
  }

  Future<CachedEpisode?> _migrateCachedFileIfNeeded(
    CachedEpisode cached,
  ) async {
    final file = File(cached.filePath);
    if (!await file.exists()) return null;
    if (!_needsBilibiliExtensionMigration(cached)) return cached;

    final target = File('${file.path.substring(0, file.path.length - 6)}.m4a');
    if (!await target.exists()) {
      await file.rename(target.path);
    } else {
      await file.delete();
    }
    final migrated = CachedEpisode(
      episode: cached.episode,
      filePath: target.path,
      bytes: await target.length(),
      cachedAt: cached.cachedAt,
    );
    AppLogger.result(
      'migrate_cached_episode',
      area: 'cache',
      data: {
        'episodeId': cached.episode.id,
        'from': cached.filePath,
        'to': migrated.filePath,
      },
    );
    return migrated;
  }

  bool _needsBilibiliExtensionMigration(CachedEpisode cached) {
    return cached.episode.sourceType == SourceType.bilibili &&
        cached.filePath.toLowerCase().endsWith('.audio');
  }

  Future<String> _audioUrlFor(Episode episode) async {
    if (episode.sourceType == SourceType.bilibili) {
      return _bilibiliRepository.resolveAudioUrl(episode);
    }
    final audioUrl = episode.audioUrl;
    if (audioUrl == null || audioUrl.isEmpty) {
      throw StateError('该单集没有音频地址');
    }
    return audioUrl;
  }

  Map<String, String> _downloadHeaders(Episode episode) {
    if (episode.sourceType != SourceType.bilibili) return const {};
    return {
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
          'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36',
      'Referer': episode.bvid == null
          ? 'https://www.bilibili.com/'
          : 'https://www.bilibili.com/video/${episode.bvid}',
      'Origin': 'https://www.bilibili.com',
      'Accept': '*/*',
    };
  }

  Future<Directory> _cacheDirectory() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/cache/audio');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  String _safeFileName(String value) {
    final sanitized = value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return sanitized.isEmpty
        ? DateTime.now().microsecondsSinceEpoch.toString()
        : sanitized;
  }

  String _extensionFor(Episode episode, String audioUrl) {
    if (episode.sourceType == SourceType.bilibili) return '.m4a';
    final path = Uri.tryParse(audioUrl)?.path.toLowerCase() ?? '';
    for (final extension in const ['.mp3', '.m4a', '.mp4', '.aac', '.wav']) {
      if (path.endsWith(extension)) return extension;
    }
    return '.mp3';
  }
}
