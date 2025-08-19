// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/services/v1/v1_config.dart';
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
  final v1 = V1ApiManager();

  List<Map<String, dynamic>> allPermissions = [];
  List<String> userPermissions = [];

  bool isLoading = true;

  // Varsayılan rol eşlemesi (gerçek id'ler DB'de farklı olabilir)
  int userRole = 3; // viewer
  int currentUserRole = 3; // viewer

  final Map<int, String> roleIdToName = const {
    1: 'admin',
    2: 'editor',
    3: 'viewer',
    4: 'employee',
    5: 'suspended',
  };

  final Map<String, int> roleNameToId = const {
    'admin': 1,
    'editor': 2,
    'viewer': 3,
    'employee': 4,
    'suspended': 5,
  };

  @override
  void initState() {
    super.initState();
    // Gelen userData['role'] string ise ID'ye çevir
    userRole = roleNameToId[
            (widget.userData['role'] ?? '').toString().toLowerCase()] ??
        3;

    // Editorün (siz) global rolü; ideal olan şirket-özel rolü kontrol etmektir
    currentUserRole = roleNameToId[
            (Provider.of<AuthProvider>(context, listen: false)
                        .userInfo?['role'] ??
                    '')
                .toString()
                .toLowerCase()] ??
        3;

    _fetchPermissions();
  }

  /// Üst başlık (avatar + email + rol dropdown)
  Widget _buildUserHeader() {
    final image = widget.userData['user_image']?.toString();
    final email = (widget.userData['email'] ?? '').toString();

    final imgUrl = (image != null && image.isNotEmpty)
        ? '${V1Config.baseUrl}uploads/user/user/$image'
        : null;

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
                backgroundImage: imgUrl != null ? NetworkImage(imgUrl) : null,
                child:
                    imgUrl == null ? const Icon(Icons.person, size: 20) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(email, style: const TextStyle(fontSize: 14)),
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
                    // Admin olmayan biri admin atayamasın
                    if (currentUserRole != 1 && newRole == 1) return;
                    setState(() => userRole = (newRole as int?) ?? 3);
                  },
                  items: roleIdToName.entries.map((entry) {
                    final disabled = currentUserRole != 1 && entry.key == 1;
                    return DropdownMenuItem(
                      value: entry.key,
                      enabled: !disabled,
                      child: Text(
                        entry.value[0].toUpperCase() + entry.value.substring(1),
                        style: TextStyle(color: disabled ? Colors.grey : null),
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

    // 1) Tüm izinler (v1: permission.getAll)
    final all = await v1.call(
      module: 'permission',
      action: 'getAll',
      params: {'scope': 'company'},
      context: context,
    );

    // Beklenen format: data: List<Map>  veya data: { permissions: List }
    List perms = [];
    if (all['success'] == true) {
      final d = all['data'];
      if (d is List) {
        perms = d;
      } else if (d is Map && d['permissions'] is List) {
        perms = d['permissions'];
      }
    }

    allPermissions = perms
        .where((e) => e is Map)
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();

    if (allPermissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load all permissions.')),
      );
      setState(() => isLoading = false);
      return;
    }

    // 2) Kullanıcının şirket-özel izinleri (v1: permission.getUserForCompany)
    final userRes = await v1.call(
      module: 'permission',
      action: 'getUserForCompany', // <- Backend’de bu aksiyon olmalı
      params: {
        'user_id': widget.userData['id'],
        'company_id': widget.companyId,
      },
      context: context,
    );

    if (userRes['success'] == true && userRes['data'] is Map) {
      final d = userRes['data'] as Map;
      // role -> string de gelebilir; eşle
      final roleName = (d['role'] ?? '').toString().toLowerCase();
      if (roleName.isNotEmpty && roleNameToId.containsKey(roleName)) {
        userRole = roleNameToId[roleName]!;
      } else if (d['role_id'] != null) {
        userRole = int.tryParse(d['role_id'].toString()) ?? userRole;
      }

      final ups = (d['permissions'] is List)
          ? List<String>.from(d['permissions'].map((e) => e.toString()))
          : <String>[];
      userPermissions = ups;
    } else {
      // Eğer backend’de henüz v1 aksiyon yoksa, burada “geçici” hata göster
      // (Eski ApiManager uçlarına dönmek 401 zinciri yaratıyordu)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User permissions endpoint (v1) not available.'),
        ),
      );
      // Varsayılan boş kalsın
      userPermissions = [];
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
    // Hem role_id hem role (string) gönder → backend hangisini isterse onu kullansın
    final roleStr = roleIdToName[userRole] ?? 'viewer';

    final result = await v1.call(
      module: 'permission',
      action: 'updateUserForCompany', // <- Backend’de bu aksiyon olmalı
      params: {
        'user_id': widget.userData['id'],
        'company_id': widget.companyId,
        'permission_codes': userPermissions,
        'role_id': userRole,
        'role': roleStr,
      },
      context: context,
    );

    if (result['success'] == true) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Save failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelf = widget.userData['id'] ==
        Provider.of<AuthProvider>(context, listen: false).userInfo?['id'];

    final isAdmin =
        (Provider.of<AuthProvider>(context, listen: false).userInfo?['role'] ??
                    '')
                .toString()
                .toLowerCase() ==
            'admin';

    final canEdit = !isSelf || isAdmin;

    return CustomScaffold(
      title: 'Permissions: ${widget.userData['name'] ?? ''}',
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
                      const Text('Company Permissions',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                      const Spacer(),
                      const Text('Select All / Deselect All',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0, left: 8.0),
                        child: Checkbox(
                          value:
                              userPermissions.length == allPermissions.length &&
                                  allPermissions.isNotEmpty,
                          onChanged: canEdit
                              ? (value) {
                                  setState(() {
                                    if (value == true) {
                                      userPermissions = allPermissions
                                          .map((perm) =>
                                              (perm['code'] ?? '').toString())
                                          .where((e) => e.isNotEmpty)
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
                      final code = (permission['code'] ?? '').toString();
                      final label =
                          (permission['description'] ?? code).toString();
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
                    onPressed: canEdit ? _savePermissions : null,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                )
              ],
            ),
    );
  }
}
