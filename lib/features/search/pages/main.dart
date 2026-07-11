import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/formatters/audio_formatters.dart';
import '../../../core/widgets/app_layout.dart';
import '../../audio/list_item.dart';
import '../../player/pages/mini.dart';
import '../../podcast/model.dart';
import '../repository.dart';
import '../model.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({
    super.key,
    this.showMiniPlayer = true,
    this.showLibraryAction = true,
  });

  final bool showMiniPlayer;
  final bool showLibraryAction;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  SearchScope _scope = SearchScope.all;
  AsyncValue<List<SearchResult>> _results = const AsyncData([]);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final keyword = _controller.text.trim();
    if (keyword.isEmpty) return;
    AppLogger.userAction(
      'search',
      area: 'search',
      data: {'keyword': keyword, 'scope': _scope.name},
    );
    setState(() => _results = const AsyncLoading());
    final repository = ref.read(searchRepositoryProvider);
    try {
      final results = await repository.search(keyword, _scope);
      AppLogger.result(
        'search',
        area: 'search',
        data: {
          'keyword': keyword,
          'scope': _scope.name,
          'count': results.length,
        },
      );
      if (mounted) setState(() => _results = AsyncData(results));
    } catch (error, stackTrace) {
      AppLogger.failure(
        'search',
        error,
        area: 'search',
        stackTrace: stackTrace,
        data: {'keyword': keyword, 'scope': _scope.name},
      );
      if (mounted) setState(() => _results = AsyncError(error, stackTrace));
    }
  }

  Future<void> _open(SearchResult result) async {
    if (!_canOpen(result)) {
      AppLogger.userAction(
        'open_search_result_blocked',
        area: 'search',
        data: {
          'id': result.id,
          'title': result.title,
          'source': result.sourceType.name,
          'reason': 'missing_bvid',
        },
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('这个 B站结果暂时无法识别')));
      return;
    }
    AppLogger.userAction(
      'open_search_result',
      area: 'search',
      data: {
        'id': result.id,
        'title': result.title,
        'source': result.sourceType.name,
        'bvid': result.bvid,
      },
    );
    context.push('/search/result', extra: result);
  }

  bool _canOpen(SearchResult result) {
    if (result.sourceType != SourceType.bilibili) return true;
    return result.bvid != null && result.bvid!.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发现'),
        actions: widget.showLibraryAction
            ? [
                IconButton(
                  tooltip: '资料库',
                  icon: const Icon(Icons.library_music_outlined),
                  onPressed: () {
                    AppLogger.userAction('open_library', area: 'library');
                    context.push('/library');
                  },
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          AppContent(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: '搜索视频、UP主或播客',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      tooltip: '搜索',
                      icon: const Icon(Icons.arrow_forward_rounded),
                      onPressed: _search,
                    ),
                  ),
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<SearchScope>(
                    segments: SearchScope.values.map((scope) {
                      return ButtonSegment(
                        value: scope,
                        label: Text(scope.label),
                      );
                    }).toList(),
                    selected: {_scope},
                    showSelectedIcon: false,
                    onSelectionChanged: (selected) {
                      setState(() => _scope = selected.first);
                      AppLogger.userAction(
                        'change_search_scope',
                        area: 'search',
                        data: {'scope': _scope.name},
                      );
                      _search();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _results.when(
              data: (results) {
                if (results.isEmpty) {
                  return const _SearchWelcome();
                }
                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 2),
                      itemBuilder: (context, index) {
                        final result = results[index];
                        return _SearchResultTile(
                          result: result,
                          enabled: _canOpen(result),
                          onTap: () => _open(result),
                        );
                      },
                    ),
                  ),
                );
              },
              error: (error, _) => Center(child: Text(error.toString())),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
          if (widget.showMiniPlayer) const MiniPlayer(),
        ],
      ),
    );
  }
}

class _SearchWelcome extends StatelessWidget {
  const _SearchWelcome();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        AppContent(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      colors.primaryContainer,
                      colors.secondaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.waves_rounded, size: 40),
                    const SizedBox(height: 32),
                    Text(
                      '找到值得听的声音',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text('从 B站长内容到 RSS 播客，统一整理成你的收听频道。'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              const AppSectionTitle(
                title: '支持的来源',
                subtitle: '搜索后可直接播放，或整理成长期订阅',
              ),
              const SizedBox(height: AppSpacing.item),
              Card(
                child: Column(
                  children: const [
                    _SourceHint(
                      icon: Icons.video_library_rounded,
                      title: 'B站合集',
                      subtitle: '把系列视频作为一个频道持续收听',
                    ),
                    Divider(indent: 64),
                    _SourceHint(
                      icon: Icons.person_rounded,
                      title: 'B站UP主',
                      subtitle: '按创作者浏览和订阅内容',
                    ),
                    Divider(indent: 64),
                    _SourceHint(
                      icon: Icons.podcasts_rounded,
                      title: 'RSS播客',
                      subtitle: '搜索节目并加载完整 RSS 单集',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SourceHint extends StatelessWidget {
  const _SourceHint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      minTileHeight: 72,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 21, color: colors.onSecondaryContainer),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.result,
    required this.enabled,
    required this.onTap,
  });

  final SearchResult result;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AudioListItem(
      coverUrl: result.imageUrl,
      title: result.title,
      metadata: [
        if (result.publishedAt != null) formatRelativeDate(result.publishedAt!),
        if (result.duration != null) formatDuration(result.duration!),
        result.subtitle ?? result.seriesTitle,
      ].whereType<String>().join(' · '),
      enabled: enabled,
      onTap: onTap,
      actions: [
        Icon(
          enabled ? Icons.chevron_right : Icons.block,
          color: enabled
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : Theme.of(context).disabledColor,
        ),
      ],
    );
  }
}
