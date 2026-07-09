import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/logging/app_logger.dart';
import '../../bilibili/data/bilibili_repository.dart';
import '../../cache/data/audio_cache_repository.dart';
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
  final controller = PlaybackController(
    ref.watch(appAudioPlayerProvider),
    ref.watch(bilibiliRepositoryProvider),
    ref.watch(audioCacheRepositoryProvider),
    ref.watch(libraryRepositoryProvider),
    ref.watch(playbackQueueProvider.notifier),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

class PlaybackController {
  PlaybackController(
    this._player,
    this._bilibiliRepository,
    this._cacheRepository,
    this._library,
    this._queue,
  ) {
    _playerStateSubscription = _player.playerStateStream.listen(
      _handlePlayerState,
    );
  }

  static const _positionSaveInterval = Duration(seconds: 10);
  static const _minimumResumePosition = Duration(seconds: 5);
  static const _completedThreshold = Duration(seconds: 10);

  final AudioPlayer _player;
  final BilibiliRepository _bilibiliRepository;
  final AudioCacheRepository _cacheRepository;
  final LibraryRepository _library;
  final PlaybackQueueController? _queue;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  Timer? _positionTimer;
  Episode? _currentEpisode;
  Duration? _lastSavedPosition;

  AudioPlayer get player => _player;

  void dispose() {
    _positionTimer?.cancel();
    _positionTimer = null;
    unawaited(_saveCurrentPosition(reason: 'dispose'));
    unawaited(_playerStateSubscription?.cancel());
    _playerStateSubscription = null;
  }

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
    await _saveCurrentPosition(reason: 'switch');
    _queue?.playNow(episode);
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    final cachedPath = await _cacheRepository.localPathFor(episode);
    if (cachedPath != null) {
      await _player.setFilePath(cachedPath);
      _currentEpisode = episode;
      _lastSavedPosition = null;
      await _seekToSavedPosition(episode);
      await _library.recordPlayback(episode);
      _startPositionTimer();
      unawaited(
        _player.play().catchError((Object error, StackTrace stackTrace) {
          AppLogger.failure(
            'play_cached_episode',
            error,
            area: 'player',
            stackTrace: stackTrace,
            data: {'episodeId': episode.id, 'title': episode.title},
          );
        }),
      );
      AppLogger.result(
        'play_cached_episode',
        area: 'player',
        data: {'episodeId': episode.id, 'path': cachedPath},
      );
      return;
    }
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
    _currentEpisode = episode;
    _lastSavedPosition = null;
    await _seekToSavedPosition(episode);
    await _library.recordPlayback(episode);
    _startPositionTimer();
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

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(_positionSaveInterval, (_) {
      if (_player.playing) {
        unawaited(_saveCurrentPosition(reason: 'timer'));
      }
    });
  }

  Future<void> _seekToSavedPosition(Episode episode) async {
    final saved = await _library.playbackPosition(episode.id);
    if (saved == null || saved < _minimumResumePosition) return;
    final duration = _player.duration ?? episode.duration;
    if (duration != null && duration - saved <= _completedThreshold) {
      await _library.clearPlaybackPosition(episode);
      return;
    }
    await _player.seek(saved);
    AppLogger.result(
      'resume_playback_position',
      area: 'player',
      data: {
        'episodeId': episode.id,
        'title': episode.title,
        'positionMs': saved.inMilliseconds,
      },
    );
  }

  void _handlePlayerState(PlayerState state) {
    if (_currentEpisode == null) return;
    if (state.processingState == ProcessingState.completed) {
      final episode = _currentEpisode!;
      _positionTimer?.cancel();
      _positionTimer = null;
      _lastSavedPosition = null;
      unawaited(_library.clearPlaybackPosition(episode));
      return;
    }
    if (!state.playing) {
      unawaited(_saveCurrentPosition(reason: 'pause'));
    }
  }

  Future<void> _saveCurrentPosition({required String reason}) async {
    final episode = _currentEpisode;
    if (episode == null) return;
    final position = _player.position;
    if (position < _minimumResumePosition) return;
    if (_lastSavedPosition == position) return;
    final duration = _player.duration ?? episode.duration;
    if (duration != null && duration - position <= _completedThreshold) {
      await _library.clearPlaybackPosition(episode);
      _lastSavedPosition = null;
      return;
    }
    await _library.savePlaybackPosition(episode, position);
    _lastSavedPosition = position;
    AppLogger.result(
      'autosave_playback_position',
      area: 'player',
      data: {
        'episodeId': episode.id,
        'positionMs': position.inMilliseconds,
        'reason': reason,
      },
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
