// views/companies/company_user_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/date_time_service.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/services/v1/v1_config.dart';
import 'package:seaofsea/views/companies/pages/company_user_detail_page.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';
import 'package:seaofsea/widgets/online_images.dart';

class CompanyUsersPage extends StatefulWidget {
  final int companyId;
  const CompanyUsersPage({super.key, required this.companyId});

  @override
  State<CompanyUsersPage> createState() => _CompanyUsersPageState();
}

class _CompanyUsersPageState extends State<CompanyUsersPage> {
  // ---- Remote data
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;

  // ---- UI state
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';
  _StatusFilter _filter = _StatusFilter.all;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final v1 = context.read<V1ApiManager>();
      final res = await v1.call(
        module: 'company',
        action: 'members_list',
        params: {
          'company_id': widget.companyId,
          'perPage': 30,
          // İleride istersen server-side filtre/arama:
          // if (_filter != _StatusFilter.all) 'status': _filter.param,
          // if (_query.isNotEmpty) 'query': _query,
        },
        context: context,
      );

      final data = (res['data'] is Map) ? res['data'] : null;
      final list = (data != null && data['items'] is List)
          ? List<Map<String, dynamic>>.from(data['items'])
          : <Map<String, dynamic>>[];

      // Öncelik: bekleyenler → approved → diğerleri
      int prio(String? s) {
        final n = _normStatus(s);
        if (n == 'pending' ||
            n == 'preapproved' ||
            n == 'waiting_manager_approval') return 0;
        if (n == 'approved') return 1;
        return 2;
      }

      list.sort((a, b) => prio(a['status']).compareTo(prio(b['status'])));

      setState(() {
        _users = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Users could not be fetched: $e';
        _isLoading = false;
      });
    }
  }

  // ---- Helpers
  String _normStatus(dynamic raw) {
    final v =
        (raw ?? '').toString().toLowerCase().replaceAll(RegExp(r'[_\-\s]'), '');
    if (v == 'waitingmanagerapproval' || v == 'wmapproval')
      return 'waiting_manager_approval';
    if (v == 'preapproved') return 'preapproved';
    if (v == 'approved') return 'approved';
    if (v == 'rejected') return 'rejected';
    if (v == 'pending') return 'pending';
    return v; // fallback
  }

  String _cap(String? s) {
    final v = (s ?? '').trim();
    if (v.isEmpty) return '-';
    return v[0].toUpperCase() + v.substring(1);
  }

  String _pickRole(Map<String, dynamic> u) {
    // Backend bazen role_name de dönebilir; sırayla dene
    return (u['role'] ?? u['role_name'] ?? '').toString();
  }

  String _pickPosition(Map<String, dynamic> u) {
    // position_name yoksa custom_position_name'e düş
    return (u['position_name'] ?? u['custom_position_name'] ?? '').toString();
  }

  String _pickRank(Map<String, dynamic> u) {
    return (u['rank'] ?? '').toString();
  }

  bool _matchesQuery(Map<String, dynamic> u) {
    if (_query.isEmpty) return true;
    String pick(String k) => (u[k] ?? '').toString().toLowerCase();
    final hay = [
      pick('name'),
      pick('surname'),
      pick('email'),
      _pickRole(u).toLowerCase(),
      _pickPosition(u).toLowerCase(),
      _pickRank(u).toLowerCase(),
      _normStatus(u['status']).toLowerCase(),
    ].join(' ');
    return hay.contains(_query);
  }

  List<Map<String, dynamic>> get _filtered {
    // Arama filtresi
    final q = _users.where(_matchesQuery).toList();

    // Durum filtresi
    if (_filter == _StatusFilter.all) return q;

    return q.where((u) {
      final s = _normStatus(u['status']);
      switch (_filter) {
        case _StatusFilter.pending:
          return s == 'pending' ||
              s == 'preapproved' ||
              s == 'waiting_manager_approval';
        case _StatusFilter.approved:
          return s == 'approved';
        case _StatusFilter.rejected:
          return s == 'rejected';
        case _StatusFilter.all:
          return true;
      }
    }).toList();
  }

  void _openUserDetail(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserDetailPage(user: user, companyId: widget.companyId)),
    );
  }

  // ---- Build
  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? _ErrorBanner(message: _error!, onRetry: _fetchUsers)
            : _buildList(context);

    return CustomScaffold(
      title: 'Company Users',
      body: RefreshIndicator(
        onRefresh: _fetchUsers,
        child: body,
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    // Gruplar
    final pendingStatuses = {
      'pending',
      'preapproved',
      'waiting_manager_approval'
    };
    final all = _filtered;

    final pendingUsers = all
        .where((u) => pendingStatuses.contains(_normStatus(u['status'])))
        .toList();
    final approvedUsers =
        all.where((u) => _normStatus(u['status']) == 'approved').toList();
    final rejectedUsers =
        all.where((u) => _normStatus(u['status']) == 'rejected').toList();
    final others = all.where((u) {
      final s = _normStatus(u['status']);
      return !pendingStatuses.contains(s) && s != 'approved' && s != 'rejected';
    }).toList();

    // Üst şerit: arama + filtre
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SearchField(
          controller: _searchCtrl,
          onClear: () {
            _searchCtrl.clear();
            setState(() => _query = '');
          },
        ),
        const SizedBox(height: 8),
        _FilterChips(
          value: _filter,
          onChanged: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: 'Refresh',
            onPressed: _fetchUsers,
            icon: const Icon(Icons.refresh),
          ),
        ),
      ],
    );

    final tiles = <Widget>[
      header,
      if (_filter == _StatusFilter.all || _filter == _StatusFilter.pending) ...[
        if (pendingUsers.isNotEmpty)
          ExpansionTile(
            initiallyExpanded: true,
            title: Text('Waiting Approval (${pendingUsers.length})'),
            children: pendingUsers
                .map((u) => _UserRowCard(
                      user: u,
                      normStatus: _normStatus(u['status']),
                      onTap: () => _openUserDetail(u),
                    ))
                .toList(),
          ),
      ],
      if (_filter == _StatusFilter.all ||
          _filter == _StatusFilter.approved) ...[
        ExpansionTile(
          initiallyExpanded: true,
          title: Text('Approved (${approvedUsers.length + others.length})'),
          children: [...approvedUsers, ...others]
              .map((u) => _UserRowCard(
                    user: u,
                    normStatus: _normStatus(u['status']),
                    onTap: () => _openUserDetail(u),
                  ))
              .toList(),
        ),
      ],
      if ((_filter == _StatusFilter.all || _filter == _StatusFilter.rejected) &&
          rejectedUsers.isNotEmpty) ...[
        ExpansionTile(
          initiallyExpanded: true,
          title: Text('Rejected (${rejectedUsers.length})'),
          children: rejectedUsers
              .map((u) => _UserRowCard(
                    user: u,
                    normStatus: _normStatus(u['status']),
                    onTap: () => _openUserDetail(u),
                  ))
              .toList(),
        ),
      ],
      if (all.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text('No users found',
                style: Theme.of(context).textTheme.bodyLarge),
          ),
        ),
    ];

    return ListView(padding: const EdgeInsets.all(12), children: tiles);
  }
}

// ---- User row card (label-over-value + responsive)
class _UserRowCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final String normStatus; // already normalized
  final VoidCallback onTap;

  const _UserRowCard({
    required this.user,
    required this.normStatus,
    required this.onTap,
  });

  String _cap(String? s) {
    final v = (s ?? '').trim();
    if (v.isEmpty) return '-';
    return v[0].toUpperCase() + v.substring(1);
  }

  String _pickRole(Map<String, dynamic> u) =>
      (u['role'] ?? u['role_name'] ?? '').toString();
  String _pickPosition(Map<String, dynamic> u) =>
      (u['position_name'] ?? u['custom_position_name'] ?? '').toString();
  String _pickRank(Map<String, dynamic> u) => (u['rank'] ?? '').toString();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final displayName = '${user['name'] ?? ''} ${user['surname'] ?? ''}'.trim();
    final email = (user['email'] ?? '').toString();
    final roleName = _cap(_pickRole(user));
    final positionName =
        _pickPosition(user).isEmpty ? '-' : _pickPosition(user);
    final rank = _pickRank(user).isEmpty ? '-' : _pickRank(user);

    final imgFile = (user['user_image'] ?? '').toString().trim();

    final created = user['created_at'];
    final joined =
        created != null ? DateTimeService.formatFromISO(created, context) : '-';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              // Breakpoints: sütun sayısını belirle
              final w = constraints.maxWidth;
              int cols;
              if (w >= 1000) {
                cols = 5; // Role, Position, Rank, Status, Joined
              } else if (w >= 760) {
                cols = 4;
              } else if (w >= 560) {
                cols = 3;
              } else {
                cols = 2;
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sol: Avatar + İsim + küçük alt satır
                  _AvatarBlock(
                    imageName: imgFile.isEmpty ? null : imgFile,
                    name: displayName.isEmpty ? 'Unnamed' : displayName,
                    subtitle: positionName != '-'
                        ? positionName
                        : (email.isEmpty ? null : email),
                  ),
                  const SizedBox(width: 12),
                  // Orta: Label-over-value hücreleri (wrap)
                  Expanded(
                    child: _CellsWrap(
                      columns: cols,
                      children: [
                        _InfoCell(label: 'ROLE', valueText: roleName),
                        _InfoCell(label: 'POSITION', valueText: positionName),
                        _InfoCell(label: 'RANK', valueText: rank),
                        _InfoCell(
                          label: 'STATUS',
                          valueWidget: _StatusPill(status: normStatus),
                        ),
                        _InfoCell(label: 'JOINED', valueText: joined),
                      ],
                    ),
                  ),
                  // Sağ: kebab menü (opsiyonel aksiyonlar) + chevron
                  const SizedBox(width: 8),
                  _RowActions(onOpen: onTap),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AvatarBlock extends StatelessWidget {
  final String? imageName;
  final String name;
  final String? subtitle;
  const _AvatarBlock(
      {required this.imageName, required this.name, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 240),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageName != null && imageName!.isNotEmpty)
            OnlineImage(
              imagePath: 'user/user/', // uploads/ sonrası relative path
              imageName: imageName!, // örn: "12345.webp"
              sizeW: 44,
              sizeH: 44,
              rounded: true,
              fallbackAsset: 'assets/avatar.png',
            )
          else
            const CircleAvatar(radius: 22, child: Icon(Icons.person)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                if (subtitle != null && subtitle!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CellsWrap extends StatelessWidget {
  final int columns;
  final List<Widget> children;
  const _CellsWrap({required this.columns, required this.children});

  @override
  Widget build(BuildContext context) {
    // Basit grid: fixed column genişliği yaklaşımı
    final spacing = 12.0;
    return LayoutBuilder(builder: (ctx, c) {
      final totalW = c.maxWidth;
      final itemW = (totalW - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: 10,
        children: children
            .map((w) => SizedBox(
                  width: itemW.clamp(140.0, double.infinity),
                  child: w,
                ))
            .toList(),
      );
    });
  }
}

class _InfoCell extends StatelessWidget {
  final String label;
  final String? valueText;
  final Widget? valueWidget;

  const _InfoCell({
    required this.label,
    this.valueText,
    this.valueWidget,
  }) : assert((valueText != null) ^ (valueWidget != null),
            'Provide either valueText or valueWidget');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.hintColor,
      letterSpacing: 0.6,
    );
    final valueStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      overflow: TextOverflow.ellipsis,
    );

    Widget value = valueWidget ??
        Text(
          (valueText ?? '-'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: valueStyle,
        );

    // Uzun basınca kopyala (valueText varsa)
    if (valueText != null && (valueText ?? '').trim().isNotEmpty) {
      value = GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: valueText!));
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Copied')));
        },
        child: value,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: labelStyle),
        const SizedBox(height: 4),
        value,
      ],
    );
  }
}

class _RowActions extends StatelessWidget {
  final VoidCallback onOpen;
  const _RowActions({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: iconColor),
          onSelected: (v) {
            if (v == 'open') onOpen();
            // TODO: permission'lara göre "Change Role", "Permissions", "Remove" eklenebilir
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'open', child: Text('View details')),
          ],
        ),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right, color: iconColor),
      ],
    );
  }
}

// ---- Status pill

class _StatusPill extends StatelessWidget {
  final String status; // normalized
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color c;
    switch (status) {
      case 'approved':
        c = Colors.green;
        break;
      case 'pending':
      case 'preapproved':
      case 'waiting_manager_approval':
        c = Colors.orange;
        break;
      case 'rejected':
        c = Colors.red;
        break;
      default:
        c = Theme.of(context).colorScheme.secondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withAlpha(30),
        border: Border.all(color: c.withAlpha(90)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: c, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ---- UI bits

enum _StatusFilter { all, pending, approved, rejected }

extension on _StatusFilter {
  String get label {
    switch (this) {
      case _StatusFilter.all:
        return 'All';
      case _StatusFilter.pending:
        return 'Pending';
      case _StatusFilter.approved:
        return 'Approved';
      case _StatusFilter.rejected:
        return 'Rejected';
    }
  }

  String? get param {
    switch (this) {
      case _StatusFilter.all:
        return null;
      case _StatusFilter.pending:
        return 'pending'; // server-side filtre eklemek istersek
      case _StatusFilter.approved:
        return 'approved';
      case _StatusFilter.rejected:
        return 'rejected';
    }
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;
  const _SearchField({required this.controller, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search users',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.clear),
                onPressed: onClear,
              ),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final _StatusFilter value;
  final ValueChanged<_StatusFilter> onChanged;
  const _FilterChips({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget chip(_StatusFilter v) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(v.label),
            selected: value == v,
            onSelected: (_) => onChanged(v),
          ),
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        chip(_StatusFilter.all),
        chip(_StatusFilter.pending),
        chip(_StatusFilter.approved),
        chip(_StatusFilter.rejected),
      ]),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: ListTile(
            leading: const Icon(Icons.error_outline),
            title:
                Text('Error', style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(message),
            trailing: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ),
      ],
    );
  }
}
