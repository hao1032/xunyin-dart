import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/downloads/page.dart';
import '../features/home.dart';
import '../features/library/pages/history.dart';
import '../features/library/pages/main.dart';
import '../features/library/pages/series.dart';
import '../features/episode/model.dart';
import '../features/series/model.dart';
import '../features/episode/page.dart';
import '../features/player/pages/main.dart';
import '../features/series/page.dart';
import '../features/player/pages/queue.dart';
import '../features/search/model.dart';
import '../features/search/pages/result.dart';
import '../features/search/pages/main.dart';
import '../features/settings.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MainShellPage()),
    GoRoute(path: '/search', builder: (context, state) => const SearchPage()),
    GoRoute(
      path: '/search/result',
      builder: (context, state) {
        final result = state.extra;
        if (result is! SearchResult) return const _MissingRouteData();
        return SearchResultPage(result: result);
      },
    ),
    GoRoute(path: '/library', builder: (context, state) => const LibraryPage()),
    GoRoute(
      path: '/subscriptions',
      builder: (context, state) => const SeriesPage(),
    ),
    GoRoute(path: '/history', builder: (context, state) => const HistoryPage()),
    GoRoute(
      path: '/downloads',
      builder: (context, state) => const DownloadsPage(),
    ),
    GoRoute(path: '/queue', builder: (context, state) => const QueuePage()),
    GoRoute(path: '/player', builder: (context, state) => const PlayerPage()),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/series',
      builder: (context, state) {
        final series = state.extra;
        if (series is! Series) return const _MissingRouteData();
        return SeriesDetailPage(series: series);
      },
    ),
    GoRoute(
      path: '/episode',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is EpisodePageArgs) {
          return EpisodePage(
            episode: extra.episode,
            relatedSeries: extra.relatedSeries,
          );
        }
        if (extra is Episode) return EpisodePage(episode: extra);
        return const _MissingRouteData();
      },
    ),
  ],
);

class _MissingRouteData extends StatelessWidget {
  const _MissingRouteData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('无法打开')),
      body: const Center(child: Text('页面缺少必要数据')),
    );
  }
}
