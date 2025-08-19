// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/services/v1/v1_config.dart';
import 'package:seaofsea/views/companies/pages/edit_user_permissions_page.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class ManageCompanyUsersPage extends StatefulWidget {
  final Map<String, dynamic> companyData;

  const ManageCompanyUsersPage({super.key, required this.companyData});

  @override
  State<ManageCompanyUsersPage> createState() => _ManageCompanyUsersPageState();
}

class _ManageCompanyUsersPageState extends State<ManageCompanyUsersPage> {
  final V1ApiManager v1 = V1ApiManager();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

  int get companyId {
    final data = widget.companyData;
    return (data['id'] ?? data['company_id']) as int;
  }

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filter);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      // V1 endpoint: company.members_list
      final res = await v1.call(
        module: 'company',
        action: 'members_list',
        params: {'company_id': companyId, 'perPage': 200},
        context: context,
      );

      final data = res['data'];
      List items = [];
      if (res['success'] == true && data != null) {
        items = (data is Map && data['items'] is List)
            ? data['items'] as List
            : (data is List ? data : []);
      }

      final safe = items
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      setState(() {
        _users = safe;
        _filtered = safe;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = List.from(_users));
      return;
    }
    setState(() {
      _filtered = _users.where((u) {
        final full = ('${u['name'] ?? ''} ${u['surname'] ?? ''}').toLowerCase();
        final role = (u['role'] ?? '').toString().toLowerCase();
        final posName = (u['position_name'] ?? '').toString().toLowerCase();
        final custom =
            (u['custom_position_name'] ?? '').toString().toLowerCase();
        return full.contains(q) ||
            role.contains(q) ||
            posName.contains(q) ||
            custom.contains(q);
      }).toList();
    });
  }

  String _userAvatarUrl(String? file) {
    if (file == null || file.isEmpty) return '';
    // V1’de doğru yol: uploads/images/user/user/...
    return '${V1Config.baseUrl}uploads/user/user/$file';
  }

  String _displayPosition(Map<String, dynamic> u) {
    final custom = (u['custom_position_name'] ?? '').toString().trim();
    if (custom.isNotEmpty) return custom;
    final pos = (u['position_name'] ?? '').toString().trim();
    return pos.isNotEmpty ? pos : '-';
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Manage Users - ${widget.companyData['name'] ?? ''}',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by name, role or position',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filter();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('No matching users found.'))
                    : RefreshIndicator(
                        onRefresh: _fetch,
                        child: ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final u = _filtered[index];
                            final name =
                                ('${u['name'] ?? ''} ${u['surname'] ?? ''}')
                                    .trim();
                            final role = (u['role'] ?? '-').toString();
                            final status = (u['status'] ?? '-').toString();
                            final img = _userAvatarUrl(
                                (u['user_image'] ?? '').toString());
                            final pos = _displayPosition(u);

                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundImage:
                                      img.isNotEmpty ? NetworkImage(img) : null,
                                  child: img.isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                        child: Text(
                                            name.isEmpty ? 'Unnamed' : name,
                                            overflow: TextOverflow.ellipsis)),
                                    const SizedBox(width: 8),
                                    Text(
                                      role,
                                      style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey),
                                    ),
                                  ],
                                ),
                                subtitle:
                                    Text('Position: $pos • Status: $status'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit),
                                  tooltip: 'Edit User Permissions',
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditUserPermissionsPage(
                                          userData: u,
                                          companyId: companyId,
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      _fetch();
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
