// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class EditUserPermissionsPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final int companyId;

  const EditUserPermissionsPage({
    super.key,
    required this.userData,
    required this.companyId,
  });

  @override
  State<EditUserPermissionsPage> createState() =>
      _EditUserPermissionsPageState();
}

class _EditUserPermissionsPageState extends State<EditUserPermissionsPage> {
  List<Map<String, dynamic>> allPermissions = [];
  List<String> userPermissions = [];

  bool isLoading = true;
  int userRole = 3;
  int currentUserRole = 3;

  final Map<int, String> roleIdToName = {
    1: 'admin',
    2: 'editor',
    3: 'viewer',
    4: 'employee',
    5: 'suspended',
  };

  final Map<String, int> roleNameToId = {
    'admin': 1,
    'editor': 2,
    'viewer': 3,
    'employee': 4,
    'suspended': 5,
  };

  @override
  void initState() {
    super.initState();
    userRole = roleNameToId[widget.userData['role']] ?? 3;

    currentUserRole = roleNameToId[
            Provider.of<AuthProvider>(context, listen: false)
                .userInfo?['role']] ??
        3;

    _fetchPermissions();
  }

  Widget _buildUserHeader() {
    final image = widget.userData['user_image'];
    final email = widget.userData['email'] ?? '';

    return Column(
      children: [
        const Divider(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                backgroundImage: image != null
                    ? NetworkImage('http://localhost/images/user/user/$image')
                    : null,
                child:
                    image == null ? const Icon(Icons.person, size: 20) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  email,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const Spacer(),
              Expanded(
                child: DropdownButtonFormField<dynamic>(
                  value: userRole,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  onChanged: (newRole) {
                    if (currentUserRole != 1 && newRole == 1) return;
                    setState(() {
                      userRole = newRole ?? 3;
                    });
                  },
                  items: roleIdToName.entries.map((entry) {
                    final disabled = currentUserRole != 1 && entry.key == 1;
                    return DropdownMenuItem(
                      value: entry.key,
                      enabled: !disabled,
                      child: Text(
                        entry.value[0].toUpperCase() + entry.value.substring(1),
                        style: TextStyle(
                          color: disabled ? Colors.grey : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Future<void> _fetchPermissions() async {
    setState(() => isLoading = true);

    final all = await ApiManager.empty().post(context, 'get_all_permissions', {
      'scope': 'company',
    });
    if (all['success'] == true && all['data']?['permissions'] is List) {
      final raw = all['data']['permissions'];
      allPermissions = List<Map<String, dynamic>>.from(raw);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load all permissions.')),
      );
      setState(() => isLoading = false);
      return;
    }

    final user =
        await ApiManager.empty().post(context, 'get_user_permissions', {
      'user_id': widget.userData['id'],
      'company_id': widget.companyId,
    });

    if (user['success'] == true &&
        user['data'] != null &&
        user['data']['permissions'] is List) {
      userPermissions = List<String>.from(user['data']['permissions']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load user permissions.')),
      );
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = false);
  }

  void _togglePermission(String code) {
    setState(() {
      if (userPermissions.contains(code)) {
        userPermissions.remove(code);
      } else {
        userPermissions.add(code);
      }
    });
  }

  Future<void> _savePermissions() async {
    final result =
        await ApiManager.empty().post(context, 'update_user_permissions', {
      'user_id': widget.userData['id'],
      'company_id': widget.companyId,
      'permission_codes': userPermissions,
      'role_id': userRole, // 👈 rol güncellemesi için eklendi
    });

    if (result['success'] == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelf = widget.userData['id'] ==
        Provider.of<AuthProvider>(context, listen: false).userInfo?['id'];

    final isAdmin =
        Provider.of<AuthProvider>(context, listen: false).userInfo?['role'] ==
            'admin';

    final canEdit = !isSelf || isAdmin;

    return CustomScaffold(
      title: 'Permissions: ${widget.userData['name']}',
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildUserHeader(),
                const Divider(height: 24),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Text(
                        'Company Permissions',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      const Spacer(),
                      const Text(
                        'Select All / Deselect All',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0, left: 8.0),
                        child: Checkbox(
                          value:
                              userPermissions.length == allPermissions.length,
                          onChanged: canEdit
                              ? (value) {
                                  setState(() {
                                    if (value == true) {
                                      userPermissions = allPermissions
                                          .map(
                                              (perm) => perm['code'].toString())
                                          .toList();
                                    } else {
                                      userPermissions.clear();
                                    }
                                  });
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: allPermissions.length,
                    itemBuilder: (context, index) {
                      final permission = allPermissions[index];
                      final code = permission['code'];
                      final label = permission['description'] ?? code;
                      final selected = userPermissions.contains(code);

                      return CheckboxListTile(
                        title: Text(label),
                        value: selected,
                        onChanged:
                            canEdit ? (_) => _togglePermission(code) : null,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ElevatedButton.icon(
                    onPressed: _savePermissions,
                    icon: const Icon(Icons.save),
                    label: const Text("Save"),
                  ),
                )
              ],
            ),
    );
  }
}
