// views/companies/company_user_detail_page.dart
import 'package:flutter/material.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/services/v1/v1_config.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class UserDetailPage extends StatelessWidget {
  final Map<String, dynamic> user;
  final int companyId; // <-- eklendi

  const UserDetailPage({
    super.key,
    required this.user,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = '${user['name'] ?? ''} ${user['surname'] ?? ''}'.trim();
    final approvalF = user['approvalF_name'] != null
        ? '${user['approvalF_name']} ${user['approvalF_surname'] ?? ''}'
        : '-';
    final approvalS = user['approvalS_name'] != null
        ? '${user['approvalS_name']} ${user['approvalS_surname'] ?? ''}'
        : '-';

    final img = user['user_image']?.toString();
    final imgUrl = (img != null && img.isNotEmpty)
        ? '${V1Config.baseUrl}uploads/user/user/$img'
        : null;

    return DefaultTabController(
      length: 2,
      child: CustomScaffold(
        title: 'User',
        body: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  imgUrl != null
                      ? CircleAvatar(
                          radius: 28, backgroundImage: NetworkImage(imgUrl))
                      : const CircleAvatar(
                          radius: 28, child: Icon(Icons.person)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName.isEmpty ? '-' : displayName,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text(user['email']?.toString() ?? '-',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Employee Detail'),
                Tab(text: 'Permissions'),
              ],
            ),

            // Content
            Expanded(
              child: TabBarView(
                children: [
                  _EmployeeDetailTab(
                      user: user, approvalF: approvalF, approvalS: approvalS),
                  _PermissionsTab(
                    companyId: companyId,
                    targetUserId: (user['user_id'] ?? user['id'] ?? 0) is int
                        ? (user['user_id'] ?? user['id'] ?? 0) as int
                        : int.tryParse((user['user_id'] ?? user['id'] ?? '0')
                                .toString()) ??
                            0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeDetailTab extends StatelessWidget {
  final Map<String, dynamic> user;
  final String approvalF;
  final String approvalS;

  const _EmployeeDetailTab({
    required this.user,
    required this.approvalF,
    required this.approvalS,
  });

  @override
  Widget build(BuildContext context) {
    final role = (user['role'] ?? '-').toString();
    final rank = (user['rank'] ?? '-').toString();
    final status = (user['status'] ?? '-').toString();
    final position =
        (user['position_name'] ?? user['custom_position_name'] ?? '-')
            .toString();

    // Üstte başlıklar, altta değerler (Stack benzeri dikey yerleşim)
    Widget line(String title, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).hintColor,
                      letterSpacing: 0.3,
                    )),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              line('Role', role),
              line('Rank', rank),
              line('Position', position),
              line('Status', status),
              const Divider(height: 24),
              line('First Approval', approvalF),
              line('Second Approval', approvalS),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionsTab extends StatefulWidget {
  final int companyId;
  final int targetUserId;

  const _PermissionsTab({
    required this.companyId,
    required this.targetUserId,
  });

  @override
  State<_PermissionsTab> createState() => _PermissionsTabState();
}

class _PermissionsTabState extends State<_PermissionsTab> {
  final V1ApiManager _api = V1ApiManager();

  bool _loading = true;
  String? _error;

  // Katalog (company scope permissions)
  List<Map<String, dynamic>> _items = [];

  // Etkin (efektif) ve UI seçimi
  Set<String> _effective = {};
  Set<String> _selected = {};

  // Kaynaklar (rozetler için)
  Set<String> _roleCompany = {};
  Set<String> _roleGlobal = {};
  Set<String> _posCompany = {};
  Set<String> _grantCompany = {};
  Set<String> _grantGlobal = {};
  Set<String> _revokeCompany = {};
  Set<String> _revokeGlobal = {};

  // Arama
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMatrix();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchMatrix() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.call(
        module: 'permission',
        action: 'matrix',
        params: {
          'company_id': widget.companyId,
          'user_id': widget.targetUserId,
        },
      );

      // ✅ Router sarmalamasıyla uyumlu oku
      final payload = (res['data'] is Map<String, dynamic>)
          ? (res['data'] as Map<String, dynamic>)
          : (res as Map<String, dynamic>);

      if (payload['success'] == false) {
        throw Exception(payload['message'] ?? 'Request failed');
      }

      // hem data altında hem kökte gelebilirse hepsine toleranslı ol
      final dataItems = (payload['items'] as List?) ??
          ((payload['data']?['items']) as List?) ??
          [];
      final eff = (payload['effective'] as List?) ??
          ((payload['data']?['effective']) as List?) ??
          [];
      final sources = (payload['sources'] as Map?) ??
          ((payload['data']?['sources']) as Map?) ??
          {};

      setState(() {
        _items = List<Map<String, dynamic>>.from(dataItems);
        _effective = eff.map((e) => e.toString()).toSet();
        _selected = Set<String>.from(_effective);

        _roleCompany = _toSet(sources['role_company']);
        _roleGlobal = _toSet(sources['role_global']);
        _posCompany = _toSet(sources['position_company']);
        _grantCompany = _toSet(sources['grants_company']);
        _grantGlobal = _toSet(sources['grants_global']);
        _revokeCompany = _toSet(sources['revokes_company']);
        _revokeGlobal = _toSet(sources['revokes_global']);

        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Set<String> _toSet(dynamic v) {
    if (v is List) {
      return v.map((e) => e.toString()).toSet();
    }
    return {};
  }

  bool get _hasChanges {
    // Seçili set ile efektif set farklı mı?
    if (_selected.length != _effective.length) return true;
    for (final c in _selected) {
      if (!_effective.contains(c)) return true;
    }
    return false;
  }

  Future<void> _save() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final res = await _api.call(
        module: 'permission',
        action: 'update_user_permissions',
        params: {
          'company_id': widget.companyId,
          'user_id': widget.targetUserId,
          'permission_codes': _selected.toList(),
        },
      );

      if (res['success'] != true) {
        throw Exception(res['message'] ?? 'Save failed');
      }

      // Kaydetmeden sonra tekrar matrix çek (sunucudaki diff/grant-revoke doğru mu kontrol)
      await _fetchMatrix();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissions saved')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _fetchMatrix,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: const Text('Error'),
                subtitle: Text(_error!),
                trailing: TextButton.icon(
                  onPressed: _fetchMatrix,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Arama filtresi
    final q = _searchCtrl.text.trim().toLowerCase();
    bool matches(Map<String, dynamic> it) {
      if (q.isEmpty) return true;
      final hay = [
        it['code']?.toString() ?? '',
        it['category']?.toString() ?? '',
        it['description']?.toString() ?? '',
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }

    // Kategoriye göre gruplama
    final filtered = _items.where(matches).toList();
    final byCat = <String, List<Map<String, dynamic>>>{};
    for (final it in filtered) {
      final cat = (it['category']?.toString() ?? '').isEmpty
          ? 'General'
          : it['category'].toString();
      byCat.putIfAbsent(cat, () => []).add(it);
    }
    final cats = byCat.keys.toList()..sort();

    final list = <Widget>[
      // Arama + bilgi
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search permissions...',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: q.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () => _searchCtrl.clear(),
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear',
                        ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _fetchMatrix,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: const [
            _LegendChip(label: 'Grant', color: Colors.blue),
            _LegendChip(label: 'Revoke', color: Colors.red),
            _LegendChip(label: 'Role', color: Colors.grey),
            _LegendChip(label: 'Position', color: Colors.teal),
            _LegendChip(label: 'Global', color: Colors.purple),
          ],
        ),
      ),
      const SizedBox(height: 4),
    ];

    for (final cat in cats) {
      final items = byCat[cat]!
        ..sort((a, b) => (a['code'] ?? '')
            .toString()
            .compareTo((b['code'] ?? '').toString()));

      list.add(
        ExpansionTile(
          initiallyExpanded: true,
          title: Text(cat),
          children: [
            for (final it in items!) _permTile(it),
          ],
        ),
      );
    }

    // Alt kaydet barı
    final bottom = _hasChanges
        ? Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            padding:
                const EdgeInsets.fromLTRB(12, 10, 12, 10 + 8), // 8: SafeArea
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'You have unsaved changes',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _fetchMatrix,
          child: ListView(
            children: list,
          ),
        ),
        // bottom save bar
        Positioned.fill(
          child: Align(alignment: Alignment.bottomCenter, child: bottom),
        ),
      ],
    );
  }

  Widget _permTile(Map<String, dynamic> it) {
    final code = (it['code'] ?? '').toString();
    final desc = (it['description'] ?? '').toString();
    final isChecked = _selected.contains(code);

    // kaynak rozetleri
    final chips = <Widget>[];
    // revoke > grant > role/position precedence UI’da da gösterelim
    if (_revokeCompany.contains(code)) {
      chips.add(const _SourceChip(label: 'Revoke', color: Colors.red));
    } else if (_revokeGlobal.contains(code)) {
      chips.add(const _SourceChip(label: 'Revoke (Global)', color: Colors.red));
    } else {
      if (_grantCompany.contains(code)) {
        chips.add(const _SourceChip(label: 'Grant', color: Colors.blue));
      }
      if (_grantGlobal.contains(code)) {
        chips.add(
            const _SourceChip(label: 'Grant (Global)', color: Colors.blue));
      }
      if (_roleCompany.contains(code)) {
        chips.add(const _SourceChip(label: 'Role', color: Colors.grey));
      }
      if (_posCompany.contains(code)) {
        chips.add(const _SourceChip(label: 'Position', color: Colors.teal));
      }
      if (_roleGlobal.contains(code)) {
        chips.add(
            const _SourceChip(label: 'Role (Global)', color: Colors.purple));
      }
    }

    return CheckboxListTile(
      value: isChecked,
      onChanged: (v) {
        setState(() {
          if (v == true) {
            _selected.add(code);
          } else {
            _selected.remove(code);
          }
        });
      },
      title: Text(code, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (desc.isNotEmpty) Text(desc),
          if (chips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(spacing: 6, runSpacing: 6, children: chips),
            ),
        ],
      ),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendChip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        border: Border.all(color: color.withAlpha(100)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String label;
  final Color color;
  const _SourceChip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        border: Border.all(color: color.withAlpha(100)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}
