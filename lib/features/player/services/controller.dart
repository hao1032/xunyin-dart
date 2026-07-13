import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/app_logger.dart';
import '../../downloads/repository.dart';
import '../../episode/playback_info.dart';
import '../../settings/repository.dart';
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
    ref.watch(settingsRepositoryProvider),
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
    this._settings,
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
  final SettingsRepository _settings;
  final PlaybackQueueController? _queue;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  Timer? _positionTimer;
  Episode? _currentEpisode;
  String? _preparingEpisodeId;
  int _playRequestId = 0;
  String? _advancingFromCompletedEpisodeId;
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
    if (_preparingEpisodeId == episode.id) {
      AppLogger.result(
        'play_episode_ignored',
        area: 'player',
        data: {'episodeId': episode.id, 'reason': 'preparing'},
      );
      return;
    }
    final requestId = ++_playRequestId;
    if (_currentEpisode?.id == episode.id) {
      _preparingEpisodeId = null;
      _queue?.playNow(episode);
      unawaited(
        _player.play().catchError((Object error, StackTrace stackTrace) {
          AppLogger.failure(
            'resume_current_episode',
            error,
            area: 'player',
            stackTrace: stackTrace,
            data: {'episodeId': episode.id, 'title': episode.title},
          );
        }),
      );
      AppLogger.result(
        'resume_current_episode',
        area: 'player',
        data: {'episodeId': episode.id, 'title': episode.title},
      );
      return;
    }
    _preparingEpisodeId = episode.id;
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
    try {
      await _saveCurrentPosition(reason: 'switch');
      if (!_isActivePlayRequest(requestId)) return;
      _queue?.playNow(episode);
      final session = await AudioSession.instance;
      if (!_isActivePlayRequest(requestId)) return;
      await session.configure(const AudioSessionConfiguration.speech());
      if (!_isActivePlayRequest(requestId)) return;
      await _player.stop();
      if (!_isActivePlayRequest(requestId)) return;
      final downloadedPath = await _downloadRepository.localPathFor(episode);
      if (!_isActivePlayRequest(requestId)) return;
      if (downloadedPath != null) {
        await _player.setFilePath(downloadedPath);
        if (!_isActivePlayRequest(requestId)) return;
        _currentEpisode = episode;
        _lastSavedPosition = null;
        await _seekToSavedPosition(episode);
        if (!_isActivePlayRequest(requestId)) return;
        await _settings.recordPlayback(episode);
        if (!_isActivePlayRequest(requestId)) return;
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
      if (!_isActivePlayRequest(requestId)) return;
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
      if (!_isActivePlayRequest(requestId)) return;
      _currentEpisode = episode;
      _lastSavedPosition = null;
      await _seekToSavedPosition(episode);
      if (!_isActivePlayRequest(requestId)) return;
      await _settings.recordPlayback(episode);
      if (!_isActivePlayRequest(requestId)) return;
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
        'play_episode',
        area: 'player',
        data: {'episodeId': episode.id, 'title': episode.title},
      );
    } catch (error, stackTrace) {
      if (!_isActivePlayRequest(requestId)) {
        AppLogger.result(
          'play_episode_superseded',
          area: 'player',
          data: {'episodeId': episode.id, 'title': episode.title},
        );
        return;
      }
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      if (_isActivePlayRequest(requestId) &&
          _preparingEpisodeId == episode.id) {
        _preparingEpisodeId = null;
      }
    }
  }

  bool _isActivePlayRequest(int requestId) {
    return requestId == _playRequestId;
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
    final saved = await _settings.playbackPosition(episode.id);
    if (saved == null || saved < _minimumResumePosition) return;
    final duration = _player.duration ?? episode.duration;
    if (duration != null && duration - saved <= _completedThreshold) {
      await _settings.clearPlaybackPosition(episode);
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
      if (_advancingFromCompletedEpisodeId == episode.id) return;
      _advancingFromCompletedEpisodeId = episode.id;
      _positionTimer?.cancel();
      _positionTimer = null;
      _lastSavedPosition = null;
      unawaited(_handleCompletedEpisode(episode));
      return;
    }
    if (!state.playing) {
      unawaited(_saveCurrentPosition(reason: 'pause'));
    }
  }

  Future<void> _handleCompletedEpisode(Episode episode) async {
    try {
      await _settings.clearPlaybackPosition(episode);
      final nextEpisode = _queue?.playNextAfter(episode);
      if (nextEpisode == null) {
        AppLogger.result(
          'auto_play_next_missing',
          area: 'player',
          data: {'episodeId': episode.id, 'title': episode.title},
        );
        return;
      }
      AppLogger.result(
        'auto_play_next',
        area: 'player',
        data: {
          'fromEpisodeId': episode.id,
          'episodeId': nextEpisode.id,
          'title': nextEpisode.title,
        },
      );
      await play(nextEpisode);
    } catch (error, stackTrace) {
      AppLogger.failure(
        'auto_play_next',
        error,
        area: 'player',
        stackTrace: stackTrace,
        data: {'episodeId': episode.id, 'title': episode.title},
      );
    } finally {
      if (_advancingFromCompletedEpisodeId == episode.id) {
        _advancingFromCompletedEpisodeId = null;
      }
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
      await _settings.clearPlaybackPosition(episode);
      _lastSavedPosition = null;
      return;
    }
    await _settings.savePlaybackPosition(episode, position);
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
