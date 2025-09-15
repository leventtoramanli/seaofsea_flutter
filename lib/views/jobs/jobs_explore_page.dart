// Public job explore (published-only list)
// - Uses RecruitmentServiceV1.postList with status='published'
// - Simple search & pagination.

import 'package:flutter/material.dart';
import 'package:seaofsea/services/v1/recruitment_service.dart';

class JobsExplorePage extends StatefulWidget {
  const JobsExplorePage({super.key});

  @override
  State<JobsExplorePage> createState() => _JobsExplorePageState();
}

class _JobsExplorePageState extends State<JobsExplorePage> {
  final TextEditingController _searchCtrl = TextEditingController();

  bool _busy = false;
  int _page = 1;
  int _perPage = 25;
  int _total = 0;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _busy = true);
    try {
      final res = await RecruitmentServiceV1.postList(
        status: 'published', // no companyId => public list
        q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        page: _page,
        perPage: _perPage,
      );

      final data = (res is Map) ? (res['data'] as Map?) : null;
      final items = (data?['items'] as List?) ?? const [];
      final total = (data?['total'] as int?) ?? items.length;

      setState(() {
        _items = items;
        _total = total;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Listed error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  int get _pages => (_total == 0) ? 1 : ((_total + _perPage - 1) ~/ _perPage);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover Jobs')),
      body: Column(
        children: [
          // Arama
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) {
                      setState(() => _page = 1);
                      _fetch();
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search (title / description)',
                      suffixIcon: IconButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _page = 1);
                          _fetch();
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (_busy)
                  const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator()),
              ],
            ),
          ),

          const Divider(height: 1),

          // Liste
          Expanded(
            child: _busy && _items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('No results'))
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final it = _items[i] as Map;
                          final title = (it['title'] ?? '').toString();
                          final description =
                              (it['description'] ?? '').toString();
                          final companyId = it['company_id']?.toString() ?? '-';
                          final createdAt = (it['created_at'] ?? '').toString();

                          return ListTile(
                            title: Text(title,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              'Company: $companyId • Created: $createdAt\n${description.isEmpty ? '' : description}',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              // TODO: İlan detay sayfasına gidebilirsin (post_detail ile)
                            },
                          );
                        },
                      ),
          ),

          // Sayfalama
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Previous',
                    onPressed: (_page > 1 && !_busy)
                        ? () {
                            setState(() => _page--);
                            _fetch();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('$_page / $_pages (Total: $_total)'),
                  IconButton(
                    tooltip: 'Next',
                    onPressed: (_page < _pages && !_busy)
                        ? () {
                            setState(() => _page++);
                            _fetch();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
