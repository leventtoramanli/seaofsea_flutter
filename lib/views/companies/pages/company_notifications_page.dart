import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';

class CompanyNotificationsPage extends StatefulWidget {
  const CompanyNotificationsPage({super.key});

  @override
  State<CompanyNotificationsPage> createState() =>
      _CompanyNotificationsPageState();
}

class _CompanyNotificationsPageState extends State<CompanyNotificationsPage> {
  final _api = V1ApiManager();

  final _items = <Map<String, dynamic>>[];
  int _page = 1;
  final int _perPage = 25;
  int _total = 0;
  bool _loading = false;
  bool _onlyUnread = false;
  bool _initialized = false;
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetch(reset: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetch({bool reset = false}) async {
    if (_loading) return;
    setState(() => _loading = true);

    if (reset) {
      _page = 1;
      _items.clear();
    }

    final res = await _api.call(
      module: 'company_notification',
      action: 'list',
      context: context,
      params: {
        'only_unread': _onlyUnread ? 1 : 0,
        'page': _page,
        'perPage': _perPage,
      },
    );

    if (mounted) {
      if (res['success'] == true) {
        final data = (res['data'] ?? {}) as Map<String, dynamic>;
        final list =
            (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _total = (data['total'] ?? 0) as int;
        _items.addAll(list);
        _page++;
        _initialized = true;
      } else if (!_initialized) {
        _initialized = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']?.toString() ?? 'Error')),
        );
      }
      setState(() => _loading = false);
    }
  }

  void _onScroll() {
    if (_controller.position.pixels >=
        _controller.position.maxScrollExtent - 200) {
      if (_items.length < _total) {
        _fetch();
      }
    }
  }

  Future<void> _refresh() async {
    await _fetch(reset: true);
  }

  Future<void> _markAllRead() async {
    final res = await _api.call(
      module: 'company_notification',
      action: 'mark_all_read',
      context: context,
    );
    if (res['success'] == true) {
      setState(() {
        for (final it in _items) {
          it['is_read'] = 1;
          it['read_at'] = DateTime.now().toIso8601String();
        }
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']?.toString() ?? 'Failed')),
      );
    }
  }

  Future<void> _markOneRead(int id) async {
    final res = await _api.call(
      module: 'company_notification',
      action: 'mark_read',
      context: context,
      params: {'id': id},
    );
    if (res['success'] == true) {
      final ix = _items.indexWhere((e) => e['id'] == id);
      if (ix >= 0) {
        setState(() {
          _items[ix]['is_read'] = 1;
          _items[ix]['read_at'] = DateTime.now().toIso8601String();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Notifications'),
        actions: [
          IconButton(
            tooltip: _onlyUnread ? 'Show all' : 'Only unread',
            onPressed: () {
              setState(() => _onlyUnread = !_onlyUnread);
              _fetch(reset: true);
            },
            icon: Icon(_onlyUnread ? Icons.mark_chat_read : Icons.markunread),
          ),
          IconButton(
            tooltip: 'Mark all as read',
            onPressed: _items.isEmpty ? null : _markAllRead,
            icon: const Icon(Icons.done_all),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _initialized && _items.isEmpty && !_loading
            ? _EmptyState(onReload: _refresh, onlyUnread: _onlyUnread)
            : ListView.separated(
                controller: _controller,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _items.length + (_loading ? 1 : 0),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  if (i >= _items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final it = _items[i];
                  final id = it['id'] as int? ?? 0;
                  final type = (it['type'] ?? '').toString();
                  final title = (it['title'] ?? '').toString();
                  final body = (it['body'] ?? '').toString();
                  final isRead = (it['is_read'] ?? 0) == 1;
                  final createdAt = _safeParseDate(it['created_at']);
                  final meta = _parseMeta(it['meta']);

                  final icon = _iconForType(type, meta?['kind']);
                  final subtitle = [
                    if (body.isNotEmpty) body,
                    if (createdAt != null) _humanTime(createdAt),
                  ].where((e) => e.isNotEmpty).join(' • ');

                  return Dismissible(
                    key: ValueKey('notif_$id'),
                    background: Container(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 16),
                      child: const Icon(Icons.mark_email_read),
                    ),
                    secondaryBackground: Container(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.mark_email_read),
                    ),
                    onDismissed: (_) => _markOneRead(id),
                    child: ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            child: icon,
                          ),
                          if (!isRead)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        title.isEmpty ? '(untitled)' : title,
                        style: isRead
                            ? null
                            : theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: subtitle.isEmpty ? null : Text(subtitle),
                      onTap: () async {
                        // örnek: job_post ise job detayına gidebilirsin
                        if (meta?['kind'] == 'job_post' &&
                            meta?['job_id'] is int) {
                          // TODO: kendi job detay rotana yönlendir
                          // Navigator.pushNamed(context, Routes.jobDetail(meta!['job_id']));
                        }
                        if (!isRead) await _markOneRead(id);
                      },
                      trailing: isRead
                          ? null
                          : IconButton(
                              tooltip: 'Mark read',
                              icon: const Icon(Icons.done),
                              onPressed: () => _markOneRead(id),
                            ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  static DateTime? _safeParseDate(dynamic v) {
    if (v == null) return null;
    try {
      final s = v.toString();
      // Backend genelde "YYYY-MM-DD HH:mm:ss" veriyor
      return DateTime.tryParse(s) ??
          DateTime.tryParse(s.replaceFirst(' ', 'T'));
    } catch (_) {
      return null;
    }
  }

  static String _humanTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  static Map<String, dynamic>? _parseMeta(dynamic meta) {
    if (meta == null) return null;
    if (meta is Map<String, dynamic>) return meta;
    try {
      return json.decode(meta.toString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Icon _iconForType(String type, String? kind) {
    switch (kind ?? type) {
      case 'job_post':
        return const Icon(Icons.work);
      case 'system':
        return const Icon(Icons.notifications);
      default:
        return const Icon(Icons.circle_notifications);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onReload, required this.onlyUnread});
  final bool onlyUnread;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(
          onlyUnread ? Icons.mark_chat_read : Icons.notifications_none,
          size: 72,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          onlyUnread ? 'No unread notifications' : 'No notifications yet',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: onReload,
            icon: const Icon(Icons.refresh),
            label: const Text('Reload'),
          ),
        ),
      ],
    );
  }
}
