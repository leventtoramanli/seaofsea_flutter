import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/services/v1/v1_config.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class CompanyListPage extends StatefulWidget {
  const CompanyListPage({super.key});

  @override
  State<CompanyListPage> createState() => _CompanyListPageState();
}

class _CompanyListPageState extends State<CompanyListPage> {
  // UI state
  bool _myExpanded = true;
  bool _allExpanded = false;

  // Data
  List<Map<String, dynamic>> _myCompanies = [];
  List<Map<String, dynamic>> _allCompanies = [];
  int _page = 1;
  int _totalCompanies = 0;
  final int _limit = 25;
  bool _isLoading = false;
  bool _hasMore = true;

  // Search & scroll
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtl = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  // Initial fetch guard
  bool _initialFetchDone = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  // ---- SAFE PARSERS ----
  List<Map<String, dynamic>> _parseItems(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map && data['items'] is List) {
      final items = data['items'] as List;
      return items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  int _parseTotal(dynamic data, int fallback) {
    if (data is Map) {
      final t = data['total'];
      if (t is int) return t;
      if (t is String) return int.tryParse(t) ?? fallback;
    }
    return fallback;
  }

  Future<void> _fetchMyCompanies() async {
    final v1 = context.read<V1ApiManager>();
    try {
      final res =
          await v1.call(module: 'company', action: 'my_list', params: {});
      final items = _parseItems(res['data']);
      if (!mounted) return;
      setState(() => _myCompanies = items);
    } catch (e) {
      debugPrint('❌ _fetchMyCompanies error: $e');
    }
  }

  Future<void> _fetchAllCompanies({bool reset = false}) async {
    if (_isLoading) return;
    if (!reset && !_hasMore) return;

    if (reset) {
      _page = 1;
      _hasMore = true;
    }

    setState(() => _isLoading = true);

    final v1 = context.read<V1ApiManager>();
    try {
      final res = await v1.call(
        module: 'company',
        action: 'list',
        params: {
          'page': _page,
          'perPage': _limit,
          if (_searchQuery.trim().isNotEmpty) 'q': _searchQuery.trim(),
        },
      );

      final data = res['data'];
      if (res['success'] == true && data != null) {
        final items = _parseItems(data);
        final total = _parseTotal(data, items.length);

        if (!mounted) return;
        setState(() {
          if (reset) {
            _allCompanies = items;
            _page = 2;
          } else {
            _allCompanies.addAll(items);
            _page++;
          }
          _totalCompanies = total;

          // hasMore: total varsa ona göre, yoksa sayfaya göre
          if (total > 0) {
            _hasMore = _allCompanies.length < total;
          } else {
            _hasMore = items.length >= _limit;
          }
        });
      } else {
        debugPrint('⚠️ company.list unexpected: $res');
      }
    } catch (e) {
      debugPrint('❌ _fetchAllCompanies error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchAllCompanies();
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _fetchMyCompanies(),
      _fetchAllCompanies(reset: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // Build içinde future üretmiyoruz. Login'i provider'dan izliyoruz.
    final isLoggedIn = context.select<AuthProvider, bool>((a) => a.isLoggedIn);

    // İlk kez login görünür olduğunda verileri çek
    if (isLoggedIn && !_initialFetchDone) {
      _initialFetchDone = true;
      // Fire-and-forget; await etmeye gerek yok.
      _fetchMyCompanies();
      _fetchAllCompanies(reset: true);
    }

    if (!isLoggedIn) {
      return const Center(
        child: Text('Please login to view your companies.'),
      );
    }

    return buildBody(context);
  }

  Widget buildBody(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScaffold(
      title: 'Companies',
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Header actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/create_company'),
                        icon: const Icon(Icons.add_business),
                        label: const Text('Create Company'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/join_company'),
                        icon: const Icon(Icons.group_add),
                        label: const Text('Join Company'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search field (debounce + controller, state kaybı yok)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _searchCtl,
                  decoration: InputDecoration(
                    hintText: 'Search companies…',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: (_searchQuery.isNotEmpty)
                        ? IconButton(
                            tooltip: 'Clear',
                            onPressed: () {
                              _searchCtl.clear();
                              _searchQuery = '';
                              _debounce?.cancel();
                              _fetchAllCompanies(reset: true);
                            },
                            icon: const Icon(Icons.close),
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    _searchQuery = value.trim();
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      final len = _searchQuery.replaceAll(' ', '').length;
                      if (len >= 2 || _searchQuery.isEmpty) {
                        _fetchAllCompanies(reset: true);
                      }
                    });
                  },
                ),
              ),
            ),

            // My Companies
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _SectionCard(
                  title: 'Your Companies',
                  count: _myCompanies.length,
                  initiallyExpanded: _myExpanded,
                  onChanged: (v) => setState(() => _myExpanded = v),
                  child: _myCompanies.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("You don't have any companies"),
                        )
                      : Column(
                          children: _myCompanies
                              .map((c) => _CompanyTile(
                                    data: c,
                                    isMyCompany: true,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/company_detail',
                                      arguments: c,
                                    ),
                                  ))
                              .toList(),
                        ),
                ),
              ),
            ),

            // All Companies
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: _SectionCard(
                  title: 'All Companies',
                  count: _totalCompanies,
                  initiallyExpanded: _allExpanded,
                  onChanged: (v) => setState(() => _allExpanded = v),
                  child: Column(
                    children: [
                      if (_allCompanies.isEmpty && _isLoading)
                        const _SkeletonList(count: 6)
                      else if (_allCompanies.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No companies found.'),
                        )
                      else
                        ..._allCompanies
                            .map((c) => _CompanyTile(
                                  data: c,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/company_detail',
                                    arguments: c,
                                  ),
                                ))
                            .toList(),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtl.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ============================== UI PARTIALS ===============================

class _SectionCard extends StatelessWidget {
  final String title;
  final int count;
  final bool initiallyExpanded;
  final ValueChanged<bool> onChanged;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.count,
    required this.initiallyExpanded,
    required this.onChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          onExpansionChanged: onChanged,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Row(
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: color.onPrimary),
                ),
              )
            ],
          ),
          children: [child],
        ),
      ),
    );
  }
}

class _CompanyTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMyCompany;
  final VoidCallback? onTap;

  const _CompanyTile({
    required this.data,
    this.isMyCompany = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final String name = (data['name'] ?? 'Unnamed').toString();
    final String createdAt = (data['created_at'] ?? '—').toString();
    final String? role = data['role']?.toString();
    final String? logoFile = data['logo']?.toString();

    final List<String> typeNames = () {
      final src = data['type_names'];
      if (src is List) return src.map((e) => e.toString()).toList();
      if (src is String) {
        return src
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return <String>[];
    }();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor.withAlpha(38)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Logo(logoFile: logoFile, name: name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: theme.textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMyCompany && role != null)
                            _RolePill(role: role),
                          const Icon(Icons.chevron_right, size: 20),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Created: $createdAt',
                          style: theme.textTheme.bodySmall),
                      if (typeNames.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: -6,
                          children: typeNames
                              .take(5)
                              .map(
                                (t) => Chip(
                                  label: Text(
                                    t,
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final String? logoFile;
  final String name;
  const _Logo({required this.logoFile, required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    final radius = 22.0;

    if (logoFile == null || logoFile!.isEmpty) {
      return CircleAvatar(radius: radius, child: Text(initials));
    }
    final url = '${V1Config.baseUrl}uploads/images/companies/logo/$logoFile';
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            CircleAvatar(radius: radius, child: Text(initials)),
      ),
    );
  }

  String _initials(String s) {
    final parts =
        s.trim().split(RegExp(r"\s+")).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.take(1).toString() +
            parts.last.characters.take(1).toString())
        .toUpperCase();
  }
}

class _RolePill extends StatelessWidget {
  final String role;
  const _RolePill({required this.role});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = switch (role) {
      'admin' => (Icons.shield, Colors.blue),
      'editor' => (Icons.edit, Colors.orange),
      'viewer' => (Icons.remove_red_eye, Colors.green),
      _ => (Icons.person, theme.colorScheme.secondary),
    };

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(102)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(role, style: theme.textTheme.labelSmall?.copyWith(color: color))
        ],
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  final int count;
  const _SkeletonList({this.count = 5});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: List.generate(count, (i) => _SkeletonTile(theme: theme)),
    );
  }
}

class _SkeletonTile extends StatefulWidget {
  final ThemeData theme;
  const _SkeletonTile({required this.theme});
  @override
  State<_SkeletonTile> createState() => _SkeletonTileState();
}

class _SkeletonTileState extends State<_SkeletonTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.theme.colorScheme.surfaceContainerHighest.withAlpha(89);
    final highlight =
        widget.theme.colorScheme.surfaceContainerHighest.withAlpha(38);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: AnimatedBuilder(
        animation: _ac,
        builder: (_, __) {
          final t = Curves.easeInOut.transform(_ac.value);
          final bg = Color.lerp(base, highlight, t)!;
          return Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: 140,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
