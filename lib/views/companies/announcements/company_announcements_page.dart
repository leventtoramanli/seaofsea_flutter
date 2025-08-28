import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/views/companies/dashboard/models/announcement.dart';
import 'package:seaofsea/views/companies/dashboard/services/company_dashboard_service.dart';
import 'package:seaofsea/views/companies/dashboard/widgets/announcement_card.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/views/companies/dashboard/widgets/announcement_form.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class CompanyAnnouncementsPage extends StatefulWidget {
  final int companyId;
  const CompanyAnnouncementsPage({super.key, required this.companyId});

  @override
  State<CompanyAnnouncementsPage> createState() =>
      _CompanyAnnouncementsPageState();
}

class _CompanyAnnouncementsPageState extends State<CompanyAnnouncementsPage> {
  late final CompanyDashboardService _service;
  final _items = <Announcement>[];
  bool _loading = false;
  int _page = 1;
  int _total = 0;
  final _perPage = 20;

  // izinler
  bool _canAnnView = false;
  bool _canAnnCreate = false;
  bool _canAnnUpdate = false;
  bool _canAnnHide = false;
  bool _canAnnArchive = false;
  bool _canAnnPin = false;
  bool _canAnnDelete = false;

  bool _busyAction = false;
  bool _includeHidden = false;

  // admin/rol
  bool _isGlobalAdmin = false;
  String _companyRole = 'none';
  bool _isCompanyAdmin = false; // admin|editor => true

  @override
  void initState() {
    super.initState();

    // Global admin tespiti (rol string + flag fallback)
    final u = Provider.of<AuthProvider>(context, listen: false).userInfo;
    final roleStr =
        (u?['role'] ?? u?['global_role'] ?? '').toString().toLowerCase();
    final flagAdmin =
        (u?['is_admin'] == 1 || u?['isAdmin'] == true || u?['role_id'] == 1);
    _isGlobalAdmin = roleStr == 'admin' || flagAdmin;

    final v1 = context.read<V1ApiManager>();
    _service = CompanyDashboardService(v1);

    _init();
  }

  Future<void> _createNew() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: AnnouncementFormCard(
            companyId: widget.companyId,
            onCancel: () => Navigator.of(context).pop(false),
            onCreated: (_) => Navigator.of(context).pop(true),
          ),
        );
      },
    );

    if (!mounted) return;
    if (created == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement published')),
      );
      await _load(first: true); // <-- _load()’u await ederek baştan çek
    }
  }

  Future<void> _init() async {
    await _loadAnnPermissions();
    await _load(first: true);
  }

  Future<void> _loadAnnPermissions() async {
    final v1 = context.read<V1ApiManager>();

    // 1) Şirket rolü
    try {
      final r = await v1.call(
        module: 'company',
        action: 'my_role',
        params: {'company_id': widget.companyId},
        context: context,
      );
      final role =
          (r['data']?['role'] ?? r['role'] ?? '').toString().toLowerCase();
      _companyRole = role;
      _isCompanyAdmin = role == 'admin' || role == 'editor';
    } catch (_) {
      _companyRole = 'none';
      _isCompanyAdmin = false;
    }

    // 2) Eğer global admin veya şirket admin/editor ise tüm aksiyonlar açık
    if (_isGlobalAdmin || _isCompanyAdmin) {
      setState(() {
        _canAnnView = true;
        _canAnnCreate = true;
        _canAnnUpdate = true;
        _canAnnHide = true;
        _canAnnArchive = true;
        _canAnnPin = true;
        _canAnnDelete = true;
      });
      return;
    }

    // 3) Diğerleri için tek tek permission.check
    Future<bool> check(String code) async {
      try {
        final res = await v1.call(
          module: 'permission',
          action: 'check',
          params: {'permission_code': code, 'company_id': widget.companyId},
          context: context,
        );
        final d = res['data'];
        if (d is Map && d['allowed'] == true) return true;
        if (res['allowed'] == true) return true;
      } catch (_) {}
      return false;
    }

    final r = await Future.wait<bool>([
      check('company.ann.view'),
      check('company.ann.create'),
      check('company.ann.update'),
      check('company.ann.hide'),
      check('company.ann.archive'),
      check('company.ann.pin'),
      check('company.ann.delete'),
    ]);

    if (!mounted) return;
    setState(() {
      _canAnnView = r[0];
      _canAnnCreate = r[1];
      _canAnnUpdate = r[2];
      _canAnnHide = r[3];
      _canAnnArchive = r[4];
      _canAnnPin = r[5];
      _canAnnDelete = r[6];

      // hide yetkisi yoksa toggle kapalı
      if (!(_canAnnHide || _isGlobalAdmin || _isCompanyAdmin)) {
        _includeHidden = false;
      }
    });
  }

  Future<void> _load({bool first = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      if (first) {
        _page = 1;
        _items.clear();
      }
      final r = await _service.fetchAnnouncements(
        widget.companyId,
        page: _page,
        perPage: _perPage,
        includeHidden: _includeHidden,
        context: context,
      );
      if (first) {
        _items
          ..clear()
          ..addAll(r.items);
      } else {
        _items.addAll(r.items);
      }
      _total = r.total;
      _page++;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---- Actions ----
  Future<void> _togglePin(Announcement a, bool toPinned) async {
    if (_busyAction || !(_canAnnPin || _isGlobalAdmin || _isCompanyAdmin))
      return;
    setState(() => _busyAction = true);
    try {
      final v1 = context.read<V1ApiManager>();
      await v1.call(
        module: 'company_announcement',
        action: toPinned ? 'pin' : 'unpin',
        params: {'id': a.id},
        context: context,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(toPinned ? 'Pinned' : 'Unpinned')),
      );
      await _load(first: true);
    } finally {
      if (mounted) setState(() => _busyAction = false);
    }
  }

  Future<void> _toggleHidden(Announcement a, bool toHidden) async {
    if (_busyAction || !(_canAnnHide || _isGlobalAdmin || _isCompanyAdmin))
      return;
    setState(() => _busyAction = true);
    try {
      final v1 = context.read<V1ApiManager>();
      await v1.call(
        module: 'company_announcement',
        action: toHidden ? 'hide' : 'unhide',
        params: {'id': a.id},
        context: context,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(toHidden ? 'Hidden' : 'Unhidden')),
      );
      await _load(first: true);
    } finally {
      if (mounted) setState(() => _busyAction = false);
    }
  }

  Future<void> _toggleArchive(Announcement a, bool toArchived) async {
    if (_busyAction || !(_canAnnArchive || _isGlobalAdmin || _isCompanyAdmin))
      return;
    setState(() => _busyAction = true);
    try {
      final v1 = context.read<V1ApiManager>();
      await v1.call(
        module: 'company_announcement',
        action: toArchived ? 'archive' : 'unarchive',
        params: {'id': a.id},
        context: context,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(toArchived ? 'Archived' : 'Unarchived')),
      );
      await _load(first: true);
    } finally {
      if (mounted) setState(() => _busyAction = false);
    }
  }

  Future<void> _openEdit(Announcement a) async {
    if (!(_canAnnUpdate || _isGlobalAdmin || _isCompanyAdmin)) return;

    final titleCtrl = TextEditingController(text: a.title);
    final bodyCtrl = TextEditingController(text: a.body ?? '');
    String visibility = a.visibility;
    bool pinned = a.pinned;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit announcement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Body (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Visibility:'),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: visibility,
                    items: const [
                      DropdownMenuItem(value: 'public', child: Text('Public')),
                      DropdownMenuItem(
                          value: 'followers', child: Text('Followers')),
                      DropdownMenuItem(
                          value: 'internal', child: Text('Internal')),
                    ],
                    onChanged: (v) {
                      if (v != null) visibility = v;
                    },
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Text('Pinned'),
                      Switch(value: pinned, onChanged: (v) => pinned = v),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );

    if (saved != true) return;

    final v1 = context.read<V1ApiManager>();
    try {
      await v1.call(
        module: 'company_announcement',
        action: 'update',
        params: {
          'id': a.id,
          'title': titleCtrl.text.trim(),
          'body': bodyCtrl.text.trim(),
          'visibility': visibility,
          'pinned': pinned ? 1 : 0,
        },
        context: context,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Updated')));
      await _load(first: true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Update failed')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showIncludeHidden = _canAnnHide || _isGlobalAdmin || _isCompanyAdmin;

    return CustomScaffold(
      title: 'Announcements', // <-- başlık ekle
      // actions: [...]  // İstersen switch’i AppBar actions içine de taşıyabilirsin
      body: RefreshIndicator(
        onRefresh: () => _load(first: true),
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          physics: const AlwaysScrollableScrollPhysics(),
          // 0: header (switch) + 1..N: items + son: footer
          itemCount: 1 + _items.length + 1,
          itemBuilder: (ctx, i) {
            // Header (Include hidden)
            if (i == 0) {
              if (!showIncludeHidden) return const SizedBox(height: 8);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Text('Include hidden'),
                    const SizedBox(width: 8),
                    Switch(
                      value: _includeHidden,
                      onChanged: (v) async {
                        setState(() => _includeHidden = v);
                        await _load(first: true);
                      },
                    ),
                  ],
                ),
              );
            }

            // Items
            final idx = i - 1;
            if (idx < _items.length) {
              final a = _items[idx];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AnnouncementCard(
                  a: a,
                  compact: false,
                  onEdit: (_canAnnUpdate || _isGlobalAdmin || _isCompanyAdmin)
                      ? _openEdit
                      : null,
                  onTogglePinned:
                      (_canAnnPin || _isGlobalAdmin || _isCompanyAdmin)
                          ? _togglePin
                          : null,
                  onToggleHidden:
                      (_canAnnHide || _isGlobalAdmin || _isCompanyAdmin)
                          ? _toggleHidden
                          : null,
                  onToggleArchived:
                      (_canAnnArchive || _isGlobalAdmin || _isCompanyAdmin)
                          ? _toggleArchive
                          : null,
                  // onDelete: ...
                ),
              );
            }

            // Footer
            if (_items.length >= _total) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('No more items ($_total total)'),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator()
                    : OutlinedButton(
                        onPressed: () => _load(),
                        child: const Text('Load more'),
                      ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: (_canAnnCreate || _isGlobalAdmin || _isCompanyAdmin)
          ? FloatingActionButton.extended(
              onPressed: _canAnnCreate ? _createNew : null,
              icon: const Icon(Icons.add),
              label: const Text('New'),
            )
          : null,
    );
  }
}
