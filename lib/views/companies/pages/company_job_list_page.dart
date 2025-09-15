// lib/views/companies/pages/company_job_list_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:seaofsea/services/custom_text_editor.dart'; // QuillTextViewer
import 'package:seaofsea/services/v1/recruitment_service.dart';
import 'package:seaofsea/views/companies/pages/job_post_detail_page.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';
import 'package:seaofsea/utils/permission_gate.dart';

class CompanyJobListPage extends StatefulWidget {
  final int companyId;
  final String? initialStatus; // draft|published|closed|archived|null

  const CompanyJobListPage({
    super.key,
    required this.companyId,
    this.initialStatus,
  });

  @override
  State<CompanyJobListPage> createState() => _CompanyJobListPageState();
}

class _CompanyJobListPageState extends State<CompanyJobListPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  bool _busy = false;
  bool _permChecked = false;
  bool _canViewAll = false;
  bool _canCreate = false;
  bool _canUpdate = false;
  bool _canPublish = false;
  bool _canClose = false;
  bool _canArchive = false;

  String? _statusFilter;
  int _page = 1;
  int _perPage = 25;
  int _total = 0;
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatus;
    _initPermsThenFetch();
  }

  Future<void> _initPermsThenFetch() async {
    try {
      // Tüm gerekli izinleri preflight olarak çek
      final results = await Future.wait<bool>([
        PermissionGate.check(
          context: context,
          permissionCode: 'recruitment.post.view',
          companyId: widget.companyId,
        ),
        PermissionGate.check(
          context: context,
          permissionCode: 'recruitment.post.create',
          companyId: widget.companyId,
        ),
        PermissionGate.check(
          context: context,
          permissionCode: 'recruitment.post.update',
          companyId: widget.companyId,
        ),
        PermissionGate.check(
          context: context,
          permissionCode: 'recruitment.post.publish',
          companyId: widget.companyId,
        ),
        PermissionGate.check(
          context: context,
          permissionCode: 'recruitment.post.close',
          companyId: widget.companyId,
        ),
        PermissionGate.check(
          context: context,
          permissionCode: 'recruitment.post.archive',
          companyId: widget.companyId,
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _canViewAll = results[0];
        _canCreate = results[1];
        _canUpdate = results[2];
        _canPublish = results[3];
        _canClose = results[4];
        _canArchive = results[5];
        _permChecked = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _permChecked = true; // hata olsa da UI kilitlenmesin
      });
    }

    await _fetch();
  }

  int get _pages => (_total == 0) ? 1 : ((_total + _perPage - 1) ~/ _perPage);

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() => _busy = true);

    try {
      final res = await RecruitmentServiceV1.postList(
        companyId: widget.companyId,
        status:
            _canViewAll ? _statusFilter : null, // iç görünümde statü filtresi
        page: _page,
        perPage: _perPage,
        q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );

      // router/data sarmalarını esnek çöz
      Map<String, dynamic>? data;
      if (res is Map) {
        var body = Map<String, dynamic>.from(res);
        if (body['data'] is Map) {
          var d1 = Map<String, dynamic>.from(body['data']);
          if (d1.containsKey('items') || d1.containsKey('total')) {
            data = d1;
          } else if (d1['data'] is Map) {
            data = Map<String, dynamic>.from(d1['data']);
          } else {
            data = d1;
          }
        } else {
          data = body;
        }
      }

      final List<Map<String, dynamic>> items = (data?['items'] is List)
          ? List<Map<String, dynamic>>.from(
              (data!['items'] as List)
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e)),
            )
          : const <Map<String, dynamic>>[];

      int total = items.length;
      final t = data?['total'];
      if (t is int) {
        total = t;
      } else if (t is String) {
        total = int.tryParse(t) ?? items.length;
      }

      if (!mounted) return;
      setState(() {
        _items = items;
        _total = total;
      });
    } catch (e) {
      if (!mounted) return;
      _snack('Failed to load job posts');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _page = 1);
      _fetch();
    });
  }

  Future<void> _publish(int id) async {
    setState(() => _busy = true);
    try {
      await RecruitmentServiceV1.postPublish(id: id);
      await _fetch();
      _snack('Post published.');
    } catch (e) {
      _snack('Publish failed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close(int id) async {
    setState(() => _busy = true);
    try {
      await RecruitmentServiceV1.postClose(id: id);
      await _fetch();
      _snack('Post closed.');
    } catch (e) {
      _snack('Close failed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _archive(int id) async {
    setState(() => _busy = true);
    try {
      await RecruitmentServiceV1.postArchive(id: id);
      await _fetch();
      _snack('Post archived.');
    } catch (e) {
      _snack('Archive failed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openEditor({int? id}) {
    Navigator.of(context).pushNamed('/job_editor', arguments: {
      'company_id': widget.companyId,
      'job_id': id
    }).then((_) => _fetch());
  }

  void _openDetail(int id) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => JobPostDetailPage(postId: id)),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final statuses = <String?>[
      null,
      'draft',
      'published',
      'closed',
      'archived'
    ];
    final perPageOptions = const [10, 25, 50, 100];

    final filterBar = Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Status filter → sadece iç görünüm izni varsa
          if (_permChecked && _canViewAll)
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String?>(
                value: _statusFilter,
                items: statuses
                    .map(
                      (e) => DropdownMenuItem<String?>(
                        value: e,
                        child:
                            Text(e == null || e.isEmpty ? 'All statuses' : e),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _statusFilter = v;
                    _page = 1;
                  });
                  _fetch();
                },
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),

          // Search
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              onSubmitted: (_) {
                setState(() => _page = 1);
                _fetch();
              },
              decoration: InputDecoration(
                labelText: 'Search (title, description)',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: (_searchCtrl.text.isEmpty)
                    ? const Icon(Icons.search)
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _page = 1);
                          _fetch();
                        },
                      ),
              ),
            ),
          ),

          // Per page
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<int>(
              value: _perPage,
              items: perPageOptions
                  .map((n) =>
                      DropdownMenuItem(value: n, child: Text('$n / page')))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _perPage = v;
                  _page = 1;
                });
                _fetch();
              },
              decoration: const InputDecoration(
                labelText: 'Page size',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),

          // New Post
          if (_permChecked && _canCreate)
            FilledButton.icon(
              onPressed: _busy ? null : () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('New Post'),
            ),

          if (_busy)
            const SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator()),
        ],
      ),
    );

    final progressBar = _busy
        ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: LinearProgressIndicator(minHeight: 2),
          )
        : const SizedBox.shrink();

    final content = RefreshIndicator(
      onRefresh: _fetch,
      child: _items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 24),
                _EmptyState(),
                SizedBox(height: 120),
              ],
            )
          : LayoutBuilder(
              builder: (ctx, bc) {
                final isWide = bc.maxWidth >= 900;
                final crossCount = isWide ? 2 : 1;
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: isWide ? 3.6 : 2.9,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (ctx, i) {
                    final it = _items[i];
                    final id = (it['id'] as int?) ?? 0;
                    final title = (it['title'] ?? 'Untitled').toString();
                    final status = (it['status'] ?? '').toString();
                    final createdAt = (it['created_at'] ?? '').toString();
                    final descJson = (it['description'] ?? '')
                        .toString(); // Quill JSON olabilir

                    return _JobCard(
                      index: id,
                      title: title,
                      descriptionDeltaJson: descJson, // ⬅️ Quill JSON
                      status: status,
                      createdAt: createdAt,
                      onOpen: () => _openDetail(id),
                      onEdit: _canUpdate ? () => _openEditor(id: id) : null,
                      onPublish: (_canPublish && status == 'draft')
                          ? () => _publish(id)
                          : null,
                      onClose: (_canClose && status == 'published')
                          ? () => _close(id)
                          : null,
                      onArchive: (_canArchive && status == 'closed')
                          ? () => _archive(id)
                          : null,
                    );
                  },
                );
              },
            ),
    );

    final pager = (_items.isNotEmpty)
        ? Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
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
                Text('$_page / $_pages • Total: $_total'),
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
          )
        : const SizedBox.shrink();

    return CustomScaffold(
      title: 'Company Job Posts',
      body: Column(
        children: [
          filterBar,
          progressBar,
          const Divider(height: 1),
          Expanded(child: content),
          pager,
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final int index;
  final String title;
  final String descriptionDeltaJson; // Quill JSON (veya düz metin fallback)
  final String status;
  final String createdAt;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onPublish;
  final VoidCallback? onClose;
  final VoidCallback? onArchive;

  const _JobCard({
    required this.index,
    required this.title,
    required this.descriptionDeltaJson,
    required this.status,
    required this.createdAt,
    required this.onOpen,
    this.onEdit,
    this.onPublish,
    this.onClose,
    this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    String sIndex = index.toString();
    int ilen = sIndex.length;
    String s = '';
    if (ilen < 6) {
      for (int i = ilen; i < 6; i++) {
        s += '0';
      }
    }
    s = '$s$index';
    final hasAdminActions =
    (onEdit != null) || (onPublish != null) || (onClose != null) || (onArchive != null);

    return Material(
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onLongPress: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Expanded(
                      child: Badge(
                        label: Text('#$s',
                            style: TextStyle(
                                color: colorScheme.onSecondaryContainer)),
                        backgroundColor: colorScheme.onSecondary,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    Expanded(child: Container()),
                    _StatusPill(status: status),
                  ],
                ),
                const SizedBox(height: 8),

                // Description (Quill JSON → read-only, 2 satır önizleme)
                if (descriptionDeltaJson.trim().isNotEmpty)
                  QuillTextViewer(
                    deltaJson: descriptionDeltaJson,
                  ),

                const Spacer(),

                // Meta + Actions
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: colorScheme.outline),
                    const SizedBox(width: 6),
                    Text(
                      createdAt,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colorScheme.outline),
                    ),
                    const Spacer(),
                    if (onEdit != null)
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    if (onPublish != null)
                      IconButton(
                        tooltip: 'Publish',
                        onPressed: onPublish,
                        icon: const Icon(Icons.campaign_outlined),
                      ),
                    if (onClose != null)
                      IconButton(
                        tooltip: 'Close',
                        onPressed: onClose,
                        icon: const Icon(Icons.lock_outline),
                      ),
                    if (onArchive != null)
                      IconButton(
                        tooltip: 'Send to archive',
                        onPressed: onArchive,
                        icon: const Icon(Icons.archive_outlined),
                      ),
                    if (!hasAdminActions)
                      FilledButton.icon(
                        onPressed: onOpen,
                        icon: const Icon(Icons
                            .open_in_new), // istersen Icons.check_circle_outlined
                        label: const Text('Open'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color bg;
    Color fg;
    switch (s) {
      case 'draft':
        bg = Colors.grey.withAlpha(30);
        fg = Colors.grey.shade800;
        break;
      case 'published':
        bg = Colors.green.withAlpha(30);
        fg = Colors.green.shade800;
        break;
      case 'closed':
        bg = Colors.orange.withAlpha(30);
        fg = Colors.orange.shade800;
        break;
      case 'archived':
        bg = Colors.blueGrey.withAlpha(30);
        fg = Colors.blueGrey.shade800;
        break;
      default:
        bg = Theme.of(context).colorScheme.surfaceContainerHighest;
        fg = Theme.of(context).colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        s.isEmpty ? 'unknown' : s,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          children: [
            const Icon(Icons.work_outline, size: 48),
            const SizedBox(height: 8),
            Text(
              'No job posts found.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Try changing filters or create a new post.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.outline),
            ),
          ],
        ),
      ),
    );
  }
}
