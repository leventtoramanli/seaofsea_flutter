// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/views/companies/edit_user_permissions_page.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';
import 'package:seaofsea/widgets/online_images.dart';

class ManageCompanyUsersPage extends StatefulWidget {
  final Map<String, dynamic> companyData;

  const ManageCompanyUsersPage({super.key, required this.companyData});

  @override
  State<ManageCompanyUsersPage> createState() => _ManageCompanyUsersPageState();
}

class _ManageCompanyUsersPageState extends State<ManageCompanyUsersPage> {
  List<dynamic> _companyUsers = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final api = context.read<ApiManager>();
    final response = await api.post(context, 'get_company_employees', {
      'company_id': widget.companyData['id'],
    });

    if (response['success'] == true && response['data'] is List) {
      setState(() {
        _companyUsers = response['data'];
        _filteredUsers = _companyUsers;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load users')),
      );
    }
  }

  void _filterUsers(String query) {
    final input = query.toLowerCase();
    setState(() {
      _filteredUsers = _companyUsers.where((user) {
        final fullName =
            '${user['name'] ?? ''} ${user['surname'] ?? ''}'.toLowerCase();
        final role = (user['role'] ?? '').toLowerCase();
        final rank = (user['rank'] ?? '').toLowerCase();
        return fullName.contains(input) ||
            role.contains(input) ||
            rank.contains(input);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Manage Users - ${widget.companyData['name'] ?? ''}',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by name, rank or role',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterUsers('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _filterUsers,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(child: Text('No matching users found.'))
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final image = user['user_image']?.toString() ?? '';
                          final rank = user['rank']?.toString() ?? '-';
                          final role = user['role']?.toString() ?? '-';

                          return ListTile(
                            leading: image.isNotEmpty
                                ? OnlineImage(
                                    imagePath: 'images/user/user/',
                                    imageName: image,
                                    sizeW: 40,
                                    rounded: true,
                                    border: true,
                                  )
                                : const Icon(Icons.person, size: 40),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${user['name']} ${user['surname']}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  role,
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(rank),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Edit User Permissions',
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditUserPermissionsPage(
                                      userData: user,
                                      companyId: widget.companyData['id'],
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  _fetchUsers(); // Güncelleme sonrası listeyi yenile
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
