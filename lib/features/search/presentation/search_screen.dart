import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logging/app_logger.dart';
import '../../player/presentation/mini_player.dart';
import '../../podcast/domain/source_type.dart';
import '../data/search_repository.dart';
import '../domain/search_result.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({
    super.key,
    this.showMiniPlayer = true,
    this.showLibraryAction = true,
  });

  final bool showMiniPlayer;
  final bool showLibraryAction;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  SearchScope _scope = SearchScope.bilibili;
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
        title: const Text('寻音'),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: '搜索 B站视频或播客',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: '搜索',
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _search,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<SearchScope>(
              segments: SearchScope.values.map((scope) {
                return ButtonSegment(value: scope, label: Text(scope.label));
              }).toList(),
              selected: {_scope},
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
          const SizedBox(height: 12),
          Expanded(
            child: _results.when(
              data: (results) {
                if (results.isEmpty) {
                  return const Center(child: Text('输入关键词开始搜索'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final result = results[index];
                    return _SearchResultTile(
                      result: result,
                      enabled: _canOpen(result),
                      onTap: () => _open(result),
                    );
                  },
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Cover(url: result.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            [
                              if (result.publishedAt != null)
                                _formatRelativeDate(result.publishedAt!),
                              if (result.duration != null)
                                _formatDuration(result.duration!),
                              result.subtitle ?? result.showTitle,
                            ].whereType<String>().join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          enabled ? Icons.chevron_right : Icons.block,
                          color: enabled
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).disabledColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRelativeDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(local);
    final days = today.difference(day).inDays;
    if (days == 0) return '今天';
    if (days == 1) return '昨天';
    if (days > 1 && days < 7) return '$days天前';
    if (days >= 7 && days < 30) return '${days ~/ 7}周前';
    if (days >= 30 && days < 365) return '${days ~/ 30}个月前';
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _Cover extends StatelessWidget {
  const _Cover({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox.square(
        dimension: 56,
        child: url == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.podcasts),
              )
            : Image.network(url!, fit: BoxFit.cover),
      ),
    );
  }
}
