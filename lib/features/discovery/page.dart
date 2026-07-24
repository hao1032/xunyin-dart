import 'package:flutter/material.dart';

import '../../core/utils.dart';
import 'source.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({required this.sources, super.key})
    : assert(sources.length > 0);

  final List<DiscoverySource> sources;

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  final _keyword = TextEditingController();
  late DiscoverySource _source = widget.sources.first;
  List<DiscoveryItem> _items = const [];
  String? _error;
  bool _loading = false;
  bool _hasSearched = false;
  var _requestId = 0;

  @override
  void dispose() {
    _keyword.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final keyword = _keyword.text.trim();
    if (keyword.isEmpty) return;
    final source = _source;
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
      _hasSearched = true;
    });
    try {
      final items = await source.search(keyword);
      if (!mounted || requestId != _requestId) return;
      setState(() => _items = items);
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _items = const [];
        _error = error.toString();
      });
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loading = false);
      }
    }
  }

  void _selectSource(DiscoverySource source) {
    if (source == _source) return;
    setState(() {
      _source = source;
      _items = const [];
      _error = null;
      _hasSearched = false;
    });
    if (_keyword.text.trim().isNotEmpty) _search();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('发现')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<DiscoverySource>(
                segments: widget.sources
                    .map(
                      (source) => ButtonSegment(
                        value: source,
                        icon: Icon(source.icon),
                        label: Text(source.name),
                      ),
                    )
                    .toList(),
                selected: {_source},
                onSelectionChanged: (sources) => _selectSource(sources.first),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _keyword,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: const InputDecoration(hintText: '输入关键词'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: '搜索',
                    onPressed: _loading ? null : _search,
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody(context)),
      ],
    ),
  );

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }
    if (!_hasSearched) return const SizedBox.expand();
    if (_items.isEmpty) return const Center(child: Text('暂无结果'));
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _items[index];
        final metadata = [
          if (item.author != null && item.author!.isNotEmpty) item.author!,
          formatDate(item.publishedAt),
          formatDuration(item.durationSeconds),
        ];
        return ListTile(
          leading: Icon(item.source.icon),
          title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(metadata.join('  '), maxLines: 1),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DiscoveryDetailPage(item: item)),
          ),
        );
      },
    );
  }
}

class DiscoveryDetailPage extends StatefulWidget {
  const DiscoveryDetailPage({required this.item, super.key});

  final DiscoveryItem item;

  @override
  State<DiscoveryDetailPage> createState() => _DiscoveryDetailPageState();
}

class _DiscoveryDetailPageState extends State<DiscoveryDetailPage> {
  late final Future<DiscoveryDetail> _detail = widget.item.source.loadDetail(
    widget.item,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.item.title)),
    body: FutureBuilder<DiscoveryDetail>(
      future: _detail,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                snapshot.error.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        }
        final detail = snapshot.requireData;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(detail.title, style: Theme.of(context).textTheme.titleLarge),
            if (detail.author != null && detail.author!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(detail.author!),
              ),
            if (detail.description != null && detail.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(detail.description!),
              ),
            if (detail.entries.isNotEmpty) ...[
              const Divider(height: 32),
              ...detail.entries.map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.title),
                  subtitle: entry.subtitle == null && entry.description == null
                      ? null
                      : Text(
                          [
                            if (entry.subtitle != null) entry.subtitle!,
                            if (entry.description != null) entry.description!,
                          ].join('\n'),
                        ),
                ),
              ),
            ],
          ],
        );
      },
    ),
  );
}
