// views/company/manage_company_page.dart
import 'package:flutter/material.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/services/v1/v1_config.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class ManageCompanyPage extends StatefulWidget {
  const ManageCompanyPage({super.key});

  @override
  State<ManageCompanyPage> createState() => _ManageCompanyPageState();
}

class _ManageCompanyPageState extends State<ManageCompanyPage> {
  final V1ApiManager v1 = V1ApiManager();
  final TextEditingController _search = TextEditingController();

  bool _loading = false;
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _fetch();
    _search.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _search.removeListener(_applyFilter);
    _search.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await v1.call(
          module: 'company', action: 'my_list', params: {}, context: context);
      final data = res['data'];
      List items = [];
      if (res['success'] == true && data != null) {
        items = (data is Map && data['items'] is List)
            ? data['items'] as List
            : (data is List ? data : []);
      }
      // only admin/editor
      final mapped = items.map<Map<String, dynamic>>((e) {
        final m = Map<String, dynamic>.from(e as Map);
        // normalize id
        m['id'] = m['company_id'] ?? m['id'];
        return m;
      }).where((m) {
        final role = (m['role'] ?? '').toString().toLowerCase();
        return role == 'admin' || role == 'editor';
      }).toList();

      setState(() {
        _all = mapped;
        _filtered = mapped;
      });
    } catch (e) {
      // optionally show a snackbar
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = List.from(_all));
      return;
    }
    setState(() {
      _filtered = _all.where((c) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        final role = (c['role'] ?? '').toString().toLowerCase();
        return name.contains(q) || role.contains(q);
      }).toList();
    });
  }

  String _logoUrl(String? file) {
    if (file == null || file.isEmpty) return '';
    return '${V1Config.baseUrl}uploads/images/companies/logo/$file';
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Manage Company',
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/create_company'),
                    icon: const Icon(Icons.add_business),
                    label: const Text('Create New Company'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                labelText: 'Search my companies',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              )),
            if (!_loading && _filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: Text('You have no manageable companies.')),
              ),
            ..._filtered.map((c) {
              final id = (c['id'] ?? c['company_id']) as int?;
              final name = (c['name'] ?? 'Unnamed').toString();
              final role = (c['role'] ?? '-').toString();
              final status = (c['status'] ?? '-').toString();
              final logo = (c['logo'] ?? '').toString();
              final url = _logoUrl(logo);

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
                    child: url.isEmpty ? const Icon(Icons.apartment) : null,
                  ),
                  title: Text(name, overflow: TextOverflow.ellipsis),
                  subtitle: Text('Role: $role • Status: $status'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: id == null
                            ? null
                            : () {
                                Navigator.pushNamed(
                                  context,
                                  '/company_detail',
                                  arguments: c,
                                );
                              },
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Open'),
                      ),
                      ElevatedButton.icon(
                        onPressed: id == null
                            ? null
                            : () {
                                Navigator.pushNamed(
                                  context,
                                  '/manage_company_users',
                                  arguments: c,
                                );
                              },
                        icon: const Icon(Icons.group),
                        label: const Text('Users'),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
