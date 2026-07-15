import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/app_logger.dart';
import '../../core/http_client.dart';
import '../../core/storage/user_data_store.dart';
import '../episode/model.dart';
import '../episode/playback_info.dart';
import 'model.dart';

final episodeDownloadRepositoryProvider = Provider<EpisodeDownloadRepository>((
  ref,
) {
  return EpisodeDownloadRepository(
    ref.watch(dioProvider),
    ref.watch(userDataStoreProvider),
    ref.watch(episodePlaybackInfoProvider),
  );
});

class EpisodeDownloadRepository {
  const EpisodeDownloadRepository(this._dio, this._store, this._playbackInfo);

  final Dio _dio;
  final UserDataStore _store;
  final EpisodePlaybackInfoProvider _playbackInfo;

  Future<List<DownloadedEpisode>> downloadedEpisodes() async {
    final episodes = await _store.loadDownloadedEpisodes();
    final existing = <DownloadedEpisode>[];
    for (final downloaded in episodes) {
      if (await File(downloaded.filePath).exists()) existing.add(downloaded);
    }
    if (existing.length != episodes.length) {
      for (final downloaded in existing) {
        await _store.saveDownloadedEpisode(downloaded);
      }
      for (final downloaded in episodes) {
        if (!existing.any((item) => item.episode.id == downloaded.episode.id)) {
          await _store.removeDownloadedEpisode(downloaded.episode.id);
        }
      }
    }
    return existing;
  }

  Future<DownloadedEpisode?> downloadedEpisode(String episodeId) async {
    final episodes = await downloadedEpisodes();
    for (final downloaded in episodes) {
      if (downloaded.episode.id == episodeId) return downloaded;
    }
    return null;
  }

  Future<bool> isDownloaded(String episodeId) async {
    return (await downloadedEpisode(episodeId)) != null;
  }

  Future<DownloadedEpisode> download(Episode episode) async {
    final existing = await downloadedEpisode(episode.id);
    if (existing != null) return existing;

    final source = await _playbackInfo.downloadInfo(episode);
    final directory = await _downloadDirectory();
    final extension = _extensionFor(episode, source.url);
    final file = File(
      '${directory.path}/${_safeFileName(episode.id)}$extension',
    );
    final temp = File('${file.path}.download');
    if (await temp.exists()) {
      await temp.delete();
    }

    AppLogger.result(
      'download_episode',
      area: 'download',
      message: 'start',
      data: {
        'episodeId': episode.id,
        'title': episode.title,
        'source': episode.sourceType.name,
      },
    );

    try {
      await _dio.download(
        source.url,
        temp.path,
        options: Options(headers: source.headers),
      );
      if (await file.exists()) {
        await file.delete();
      }
      await temp.rename(file.path);
      final downloaded = DownloadedEpisode(
        episode: episode,
        filePath: file.path,
        bytes: await file.length(),
        downloadedAt: DateTime.now(),
      );
      await _store.saveDownloadedEpisode(downloaded);
      AppLogger.result(
        'download_episode',
        area: 'download',
        data: {
          'episodeId': episode.id,
          'path': file.path,
          'bytes': downloaded.bytes,
        },
      );
      return downloaded;
    } catch (error, stackTrace) {
      if (await temp.exists()) {
        await temp.delete();
      }
      AppLogger.failure(
        'download_episode',
        error,
        area: 'download',
        stackTrace: stackTrace,
        data: {'episodeId': episode.id, 'title': episode.title},
      );
      rethrow;
    }
  }

  Future<void> remove(String episodeId) async {
    final downloaded = await downloadedEpisode(episodeId);
    if (downloaded != null) {
      final file = File(downloaded.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _store.removeDownloadedEpisode(episodeId);
    AppLogger.result(
      'remove_downloaded_episode',
      area: 'download',
      data: {'episodeId': episodeId},
    );
  }

  Future<String?> localPathFor(Episode episode) async {
    final downloaded = await downloadedEpisode(episode.id);
    if (downloaded == null) return null;
    return downloaded.filePath;
  }

  Future<Directory> _downloadDirectory() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/download/episodes');
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

  String _extensionFor(Episode episode, String mediaUrl) {
    if (episode.sourceType == SourceType.bilibili) return '.m4a';
    final path = Uri.tryParse(mediaUrl)?.path.toLowerCase() ?? '';
    for (final extension in const ['.mp3', '.m4a', '.mp4', '.aac', '.wav']) {
      if (path.endsWith(extension)) return extension;
    }
    return '.mp3';
  }
}
