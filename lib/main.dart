import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/logging/app_logger.dart';
import 'core/logging/logger_provider.dart';
import 'core/http_client.dart';
import 'core/utils.dart';
import 'features/bilibili/client.dart';
import 'features/bilibili/login_page.dart';
import 'features/bilibili/session_store.dart';
import 'features/podcast/client.dart';
import 'features/podcast/models.dart';

void main() {
  final logger = createAppLogger();
  final dio = createHttpClient(logger);
  final bilibiliSession = BilibiliSessionStore(dio, logger);
  _installGlobalErrorLogging(logger);
  runApp(
    ProviderScope(
      overrides: [appLoggerProvider.overrideWithValue(logger)],
      child: XunyinApp(
        bilibili: BilibiliClient(dio, logger, sessionStore: bilibiliSession),
        bilibiliSession: bilibiliSession,
        apple: ApplePodcastClient(dio, logger),
        rss: RssClient(dio, logger),
      ),
    ),
  );
}

void _installGlobalErrorLogging(AppLogger logger) {
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    logger.error(
      'ui',
      'flutter_error',
      error: details.exception,
      stackTrace: details.stack,
      data: {'library': details.library},
    );
    previousOnError?.call(details);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    logger.error(
      'app',
      'uncaught_async_error',
      error: error,
      stackTrace: stackTrace,
    );
    return false;
  };
}

class XunyinApp extends StatelessWidget {
  const XunyinApp({
    required this.bilibili,
    required this.bilibiliSession,
    required this.apple,
    required this.rss,
    super.key,
  });

  final BilibiliClient bilibili;
  final BilibiliSessionStore bilibiliSession;
  final ApplePodcastClient apple;
  final RssClient rss;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AppNavigationShell(
        bilibili: bilibili,
        bilibiliSession: bilibiliSession,
        apple: apple,
        rss: rss,
      ),
    );
  }
}

class AppNavigationShell extends StatefulWidget {
  const AppNavigationShell({
    required this.bilibili,
    required this.bilibiliSession,
    required this.apple,
    required this.rss,
    super.key,
  });

  final BilibiliClient bilibili;
  final BilibiliSessionStore bilibiliSession;
  final ApplePodcastClient apple;
  final RssClient rss;

  @override
  State<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends State<AppNavigationShell> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _EmptyTabPage(title: '播放列表'),
      const _EmptyTabPage(title: '发现'),
      _SettingsPage(
        bilibili: widget.bilibili,
        bilibiliSession: widget.bilibiliSession,
        apple: widget.apple,
        rss: widget.rss,
      ),
    ];
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.queue_music_outlined),
            selectedIcon: Icon(Icons.queue_music),
            label: '播放列表',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: '发现',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

class _EmptyTabPage extends StatelessWidget {
  const _EmptyTabPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: const SizedBox.expand(),
  );
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.bilibili,
    required this.bilibiliSession,
    required this.apple,
    required this.rss,
  });

  final BilibiliClient bilibili;
  final BilibiliSessionStore bilibiliSession;
  final ApplePodcastClient apple;
  final RssClient rss;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('设置')),
    body: ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.bug_report_outlined),
          title: const Text('数据获取调试'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  DataDebugPage(bilibili: bilibili, apple: apple, rss: rss),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.login),
          title: const Text('B站登录'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BilibiliLoginPage(sessionStore: bilibiliSession),
            ),
          ),
        ),
      ],
    ),
  );
}

class DataDebugPage extends StatefulWidget {
  const DataDebugPage({
    required this.bilibili,
    required this.apple,
    required this.rss,
    super.key,
  });

  final BilibiliClient bilibili;
  final ApplePodcastClient apple;
  final RssClient rss;

  @override
  State<DataDebugPage> createState() => _DataDebugPageState();
}

class _DataDebugPageState extends State<DataDebugPage> {
  final _bilibiliKeyword = TextEditingController();
  final _podcastKeyword = TextEditingController();
  List<BilibiliSearchResult> _videos = const [];
  BilibiliVideoDetail? _bilibiliDetail;
  List<BilibiliVideo> _collectionVideos = const [];
  bool _loadingCollection = false;
  String? _relatedError;
  List<ApplePodcastResult> _podcasts = const [];
  RssFeed? _feed;
  String? _error;
  bool _loading = false;
  DateTime? _lastBilibiliSearchAt;

  BilibiliClient get _bilibili => widget.bilibili;
  ApplePodcastClient get _apple => widget.apple;
  RssClient get _rss => widget.rss;

  @override
  void dispose() {
    _bilibiliKeyword.dispose();
    _podcastKeyword.dispose();
    super.dispose();
  }

  Future<void> _searchBilibili() async {
    if (_loading) return;
    final now = DateTime.now();
    final last = _lastBilibiliSearchAt;
    if (last != null &&
        now.difference(last) < const Duration(milliseconds: 500)) {
      return;
    }
    _lastBilibiliSearchAt = now;
    await _run(
      () async => _videos = await _bilibili.searchVideos(_bilibiliKeyword.text),
    );
  }

  Future<void> _searchPodcast() async {
    await _run(
      () async => _podcasts = await _apple.search(_podcastKeyword.text),
    );
  }

  Future<void> _loadFeed(String url) async {
    await _run(() async => _feed = await _rss.loadFeed(url));
  }

  Future<void> _loadBilibiliDetail(String bvid) async {
    await _run(() async {
      _bilibiliDetail = await _bilibili.getVideoDetail(bvid);
      _collectionVideos = const [];
      _relatedError = null;
    });
  }

  Future<void> _loadCollectionVideos() async {
    final detail = _bilibiliDetail;
    final collectionId = detail?.collectionId;
    if (detail == null || collectionId == null || _loadingCollection) return;
    setState(() {
      _loadingCollection = true;
      _relatedError = null;
    });
    try {
      final videos = await _bilibili.getCollectionVideos(
        mid: detail.ownerMid,
        collectionId: collectionId,
      );
      if (mounted) setState(() => _collectionVideos = videos);
    } catch (error) {
      if (mounted) setState(() => _relatedError = error.toString());
    } finally {
      if (mounted) setState(() => _loadingCollection = false);
    }
  }

  Future<void> _run(Future<void> Function() operation) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await operation();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据获取调试')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SearchSection(
            title: 'B站搜索',
            controller: _bilibiliKeyword,
            onSearch: _searchBilibili,
            enabled: !_loading,
            child: _videos.isEmpty
                ? const Text('暂无结果')
                : Column(
                    children: _videos
                        .map(
                          (video) => ListTile(
                            title: Text(video.title),
                            subtitle: Text(
                              '${video.author}  ${video.bvid}\n'
                              '${formatDate(video.publishedAt)}  '
                              '${formatDuration(video.durationSeconds)}',
                            ),
                            onTap: () => _loadBilibiliDetail(video.bvid),
                          ),
                        )
                        .toList(),
                  ),
          ),
          if (_bilibiliDetail != null) ...[
            const Divider(height: 32),
            Text(
              '单集详情：${_bilibiliDetail!.title}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'UP主：${_bilibiliDetail!.ownerName}（${_bilibiliDetail!.ownerMid}）',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed:
                      _bilibiliDetail!.collectionId == null ||
                          _loadingCollection
                      ? null
                      : _loadCollectionVideos,
                  child: Text(_loadingCollection ? '加载中…' : '加载所属合集视频'),
                ),
              ],
            ),
            if (!_bilibiliDetail!.isCollection) const Text('该单集不属于合集或分P'),
            if (_bilibiliDetail!.pages.isNotEmpty) ...[
              const Text('分P列表'),
              ..._bilibiliDetail!.pages.map(
                (page) => Text(
                  '${page.page}. ${page.part.isEmpty ? '未命名分P' : page.part} · ${formatDuration(page.durationSeconds)}',
                ),
              ),
            ],
            if (_collectionVideos.isNotEmpty) ...[
              const Text('所属合集视频'),
              ..._collectionVideos.take(20).map(_relatedTile),
            ],
            if (_relatedError != null)
              Text(
                _relatedError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
          const Divider(height: 32),
          _SearchSection(
            title: 'Apple Podcasts 搜索',
            controller: _podcastKeyword,
            onSearch: _searchPodcast,
            enabled: !_loading,
            child: _podcasts.isEmpty
                ? const Text('暂无结果')
                : Column(
                    children: _podcasts
                        .map(
                          (podcast) => ListTile(
                            title: Text(podcast.name),
                            subtitle: Text(
                              '${podcast.artist}  '
                              '${formatDate(podcast.publishedAt)}  '
                              '${formatDuration(podcast.durationSeconds)}',
                            ),
                            onTap: () => _loadFeed(podcast.feedUrl),
                          ),
                        )
                        .toList(),
                  ),
          ),
          if (_feed != null) ...[
            const Divider(height: 32),
            Text(_feed!.title, style: Theme.of(context).textTheme.titleLarge),
            Text('单集：${_feed!.episodes.length}'),
            ..._feed!.episodes
                .take(20)
                .map(
                  (episode) => ListTile(
                    title: Text(episode.title),
                    subtitle: Text(
                      '${formatDate(episode.publishedAt)}  '
                      '${formatDuration(episode.durationSeconds)}',
                    ),
                  ),
                ),
          ],
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }

  Widget _relatedTile(BilibiliVideo video) => ListTile(
    dense: true,
    title: Text(video.title),
    subtitle: Text(
      '${video.author}  ${video.bvid}\n'
      '${formatDate(video.publishedAt)}  ${formatDuration(video.durationSeconds)}',
    ),
  );
}

class _SearchSection extends StatelessWidget {
  const _SearchSection({
    required this.title,
    required this.controller,
    required this.onSearch,
    required this.enabled,
    required this.child,
  });
  final String title;
  final TextEditingController controller;
  final VoidCallback onSearch;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: enabled ? (_) => onSearch() : null,
              decoration: const InputDecoration(hintText: '输入关键词'),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: enabled ? onSearch : null,
            child: const Text('搜索'),
          ),
        ],
      ),
      child,
    ],
  );
}
