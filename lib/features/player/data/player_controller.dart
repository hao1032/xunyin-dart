import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/logging/app_logger.dart';
import '../../bilibili/data/bilibili_repository.dart';
import '../../library/data/library_repository.dart';
import '../../podcast/domain/episode.dart';
import '../../podcast/domain/source_type.dart';
import 'bilibili_audio_source.dart';
import 'playback_queue.dart';

final appAudioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer(useProxyForRequestHeaders: false);
  ref.onDispose(player.dispose);
  return player;
});

final playbackControllerProvider = Provider<PlaybackController>((ref) {
  return PlaybackController(
    ref.watch(appAudioPlayerProvider),
    ref.watch(bilibiliRepositoryProvider),
    ref.watch(libraryRepositoryProvider),
    ref.watch(playbackQueueProvider.notifier),
  );
});

class PlaybackController {
  const PlaybackController(
    this._player,
    this._bilibiliRepository,
    this._library,
    this._queue,
  );

  final AudioPlayer _player;
  final BilibiliRepository _bilibiliRepository;
  final LibraryRepository _library;
  final PlaybackQueueController? _queue;

  AudioPlayer get player => _player;

  Future<void> play(Episode episode) async {
    AppLogger.userAction(
      'play_episode',
      area: 'player',
      data: {
        'episodeId': episode.id,
        'title': episode.title,
        'source': episode.sourceType.name,
        'bvid': episode.bvid,
        'cid': episode.cid,
      },
    );
    _queue?.playNow(episode);
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    final audioUrl = await _audioUrlFor(episode);
    AppLogger.result(
      'prepare_audio',
      area: 'player',
      data: {
        'episodeId': episode.id,
        'source': episode.sourceType.name,
        'hasAudioUrl': audioUrl.isNotEmpty,
      },
    );
    if (episode.sourceType == SourceType.bilibili) {
      await _player.setAudioSource(
        BilibiliAudioSource(
          uri: Uri.parse(audioUrl),
          headers: _bilibiliPlaybackHeaders(episode),
          episodeId: episode.id,
        ),
      );
    } else {
      await _player.setUrl(audioUrl);
    }
    await _library.recordPlayback(episode);
    unawaited(
      _player.play().catchError((Object error, StackTrace stackTrace) {
        AppLogger.failure(
          'play_episode',
          error,
          area: 'player',
          stackTrace: stackTrace,
          data: {'episodeId': episode.id, 'title': episode.title},
        );
      }),
    );
    AppLogger.result(
      'play_episode',
      area: 'player',
      data: {'episodeId': episode.id, 'title': episode.title},
    );
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

  Map<String, String> _bilibiliPlaybackHeaders(Episode episode) {
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
}
