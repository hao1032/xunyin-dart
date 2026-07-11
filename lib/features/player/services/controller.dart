import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/app_logger.dart';
import '../../downloads/repository.dart';
import '../../episode/playback_info.dart';
import '../../library/repository.dart';
import '../../episode/model.dart';
import 'playback_queue.dart';

final appPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer(useProxyForRequestHeaders: false);
  ref.onDispose(player.dispose);
  return player;
});

final playbackControllerProvider = Provider<PlaybackController>((ref) {
  final controller = PlaybackController(
    ref.watch(appPlayerProvider),
    ref.watch(episodePlaybackInfoProvider),
    ref.watch(episodeDownloadRepositoryProvider),
    ref.watch(libraryRepositoryProvider),
    ref.watch(playbackQueueProvider.notifier),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

class PlaybackController {
  PlaybackController(
    this._player,
    this._playbackInfo,
    this._downloadRepository,
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
  final EpisodePlaybackInfoProvider _playbackInfo;
  final EpisodeDownloadRepository _downloadRepository;
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
    final downloadedPath = await _downloadRepository.localPathFor(episode);
    if (downloadedPath != null) {
      await _player.setFilePath(downloadedPath);
      _currentEpisode = episode;
      _lastSavedPosition = null;
      await _seekToSavedPosition(episode);
      await _library.recordPlayback(episode);
      _startPositionTimer();
      unawaited(
        _player.play().catchError((Object error, StackTrace stackTrace) {
          AppLogger.failure(
            'play_downloaded_episode',
            error,
            area: 'player',
            stackTrace: stackTrace,
            data: {'episodeId': episode.id, 'title': episode.title},
          );
        }),
      );
      AppLogger.result(
        'play_downloaded_episode',
        area: 'player',
        data: {'episodeId': episode.id, 'path': downloadedPath},
      );
      return;
    }
    final info = await _playbackInfo.playbackInfo(episode);
    AppLogger.result(
      'prepare_episode_source',
      area: 'player',
      data: {'episodeId': episode.id, 'source': episode.sourceType.name},
    );
    switch (info) {
      case EpisodeUrlPlaybackInfo(:final url):
        await _player.setUrl(url);
      case EpisodeCustomPlaybackInfo(:final source):
        await _player.setAudioSource(source);
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
}
