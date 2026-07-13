import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_logger.dart';
import '../../../core/display_formatters.dart';
import '../../../core/app_layout.dart';
import '../../../shared/wigets/app_bar.dart';
import '../../../shared/wigets/app_list_item.dart';
import '../../episode/model.dart';
import '../repository.dart';
import '../model.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key, this.showSettingsAction = true});

  final bool showSettingsAction;

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  static const _pageSize = 20;

  final _controller = TextEditingController();
  SearchScope _scope = SearchScope.bilibili;
  AsyncValue<List<SearchResult>> _results = const AsyncData([]);
  int _page = 1;
  bool _hasNextPage = false;
  String? _lastKeyword;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search({int page = 1}) async {
    final keyword = _controller.text.trim();
    if (keyword.isEmpty) return;
    AppLogger.userAction(
      'search',
      area: 'search',
      data: {'keyword': keyword, 'scope': _scope.name, 'page': page},
    );
    setState(() => _results = const AsyncLoading());
    final repository = ref.read(searchRepositoryProvider);
    try {
      final results = await repository.search(
        keyword,
        _scope,
        page: page,
        pageSize: _pageSize,
      );
      AppLogger.result(
        'search',
        area: 'search',
        data: {
          'keyword': keyword,
          'scope': _scope.name,
          'page': page,
          'count': results.length,
        },
      );
      if (mounted) {
        setState(() {
          _results = AsyncData(results);
          _page = page;
          _lastKeyword = keyword;
          _hasNextPage = _canLoadNextPage(results);
        });
      }
    } catch (error, stackTrace) {
      AppLogger.failure(
        'search',
        error,
        area: 'search',
        stackTrace: stackTrace,
        data: {'keyword': keyword, 'scope': _scope.name, 'page': page},
      );
      if (mounted) setState(() => _results = AsyncError(error, stackTrace));
    }
  }

  bool _canLoadNextPage(List<SearchResult> results) {
    return switch (_scope) {
      SearchScope.bilibili => results.length == _pageSize,
      SearchScope.all || SearchScope.podcast => false,
    };
  }

  bool get _showPager => _scope == SearchScope.bilibili && _lastKeyword != null;

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
    context.push('/discover/result', extra: result);
  }

  bool _canOpen(SearchResult result) {
    if (result.sourceType != SourceType.bilibili) return true;
    return result.bvid != null && result.bvid!.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppPageBar(
        title: '发现',
        actions: widget.showSettingsAction
            ? [
                IconButton(
                  tooltip: '设置',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    AppLogger.userAction('open_settings', area: 'settings');
                    context.push('/settings');
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
                      onPressed: () => _search(),
                    ),
                  ),
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<SearchScope>(
                    segments: [SearchScope.bilibili, SearchScope.podcast].map((
                      scope,
                    ) {
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
                if (results.isEmpty && _lastKeyword == null) {
                  return const _SearchWelcome();
                }
                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        if (results.isEmpty) const _SearchEmpty(),
                        ...results.map((result) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: _SearchResultTile(
                              result: result,
                              enabled: _canOpen(result),
                              onTap: () => _open(result),
                            ),
                          );
                        }),
                        if (_showPager)
                          _SearchPager(
                            page: _page,
                            loading: _results.isLoading,
                            hasNextPage: _hasNextPage,
                            onPrevious: _page <= 1
                                ? null
                                : () => _search(page: _page - 1),
                            onNext: _hasNextPage
                                ? () => _search(page: _page + 1)
                                : null,
                          ),
                      ],
                    ),
                  ),
                );
              },
              error: (error, _) => Center(child: Text(error.toString())),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
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
                  borderRadius: BorderRadius.circular(10),
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
                    const Text('从 B站长内容到 RSS 播客，统一整理成你的收听订阅。'),
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
                      subtitle: '把系列视频作为一个合集持续收听',
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

class _SearchEmpty extends StatelessWidget {
  const _SearchEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(child: Text('没有更多结果')),
    );
  }
}

class _SearchPager extends StatelessWidget {
  const _SearchPager({
    required this.page,
    required this.loading,
    required this.hasNextPage,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final bool loading;
  final bool hasNextPage;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.navigate_before),
              label: const Text('上一页'),
              onPressed: loading ? null : onPrevious,
            ),
          ),
          const SizedBox(width: 12),
          loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('第 $page 页'),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.navigate_next),
              label: const Text('下一页'),
              onPressed: loading || !hasNextPage ? null : onNext,
            ),
          ),
        ],
      ),
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
          borderRadius: BorderRadius.circular(6),
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
    return AppListItem(
      coverUrl: result.imageUrl,
      title: result.title,
      subtitle: result.subtitle ?? result.seriesTitle,
      metadata: [
        if (result.publishedAt != null) formatRelativeDate(result.publishedAt!),
        if (result.duration != null) formatDuration(result.duration!),
      ].join(' · '),
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
