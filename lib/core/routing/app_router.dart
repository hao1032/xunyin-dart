import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/library/presentation/library_screen.dart';
import '../../features/podcast/domain/episode.dart';
import '../../features/podcast/domain/podcast_show.dart';
import '../../features/podcast/presentation/episode_screen.dart';
import '../../features/podcast/presentation/show_detail_screen.dart';
import '../../features/player/presentation/queue_screen.dart';
import '../../features/search/presentation/search_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SearchScreen()),
    GoRoute(
      path: '/library',
      builder: (context, state) => const LibraryScreen(),
    ),
    GoRoute(path: '/queue', builder: (context, state) => const QueueScreen()),
    GoRoute(
      path: '/show',
      builder: (context, state) {
        final show = state.extra;
        if (show is! PodcastShow) return const _MissingRouteData();
        return ShowDetailScreen(show: show);
      },
    ),
    GoRoute(
      path: '/episode',
      builder: (context, state) {
        final episode = state.extra;
        if (episode is! Episode) return const _MissingRouteData();
        return EpisodeScreen(episode: episode);
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
