import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../bilibili/services/episode_stream_source.dart';
import '../bilibili/services/repository.dart';
import 'model.dart';

final episodePlaybackInfoProvider = Provider<EpisodePlaybackInfoProvider>((
  ref,
) {
  return EpisodePlaybackInfoProvider(ref.watch(bilibiliRepositoryProvider));
});

class EpisodePlaybackInfoProvider {
  const EpisodePlaybackInfoProvider(this._bilibili);

  final BilibiliRepository _bilibili;

  Future<EpisodePlaybackInfo> playbackInfo(Episode episode) async {
    final source = await downloadInfo(episode);
    if (episode.sourceType == SourceType.bilibili) {
      return EpisodePlaybackInfo.custom(
        BilibiliEpisodeStreamSource(
          uri: Uri.parse(source.url),
          headers: source.headers,
          episodeId: episode.id,
        ),
      );
    }
    return EpisodePlaybackInfo.url(source.url);
  }

  Future<EpisodeDownloadInfo> downloadInfo(Episode episode) async {
    if (episode.sourceType == SourceType.bilibili) {
      return EpisodeDownloadInfo(
        url: await _bilibili.resolveMediaUrl(episode),
        headers: _bilibiliHeaders(episode),
      );
    }
    final url = episode.mediaUrl;
    if (url == null || url.isEmpty) {
      throw StateError('该单集没有音频地址');
    }
    return EpisodeDownloadInfo(url: url);
  }

  Map<String, String> _bilibiliHeaders(Episode episode) {
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

class EpisodeDownloadInfo {
  const EpisodeDownloadInfo({required this.url, this.headers = const {}});

  final String url;
  final Map<String, String> headers;
}

sealed class EpisodePlaybackInfo {
  const EpisodePlaybackInfo();

  const factory EpisodePlaybackInfo.url(String url) = EpisodeUrlPlaybackInfo;

  const factory EpisodePlaybackInfo.custom(AudioSource source) =
      EpisodeCustomPlaybackInfo;
}

class EpisodeUrlPlaybackInfo extends EpisodePlaybackInfo {
  const EpisodeUrlPlaybackInfo(this.url);

  final String url;
}

class EpisodeCustomPlaybackInfo extends EpisodePlaybackInfo {
  const EpisodeCustomPlaybackInfo(this.source);

  final AudioSource source;
}
