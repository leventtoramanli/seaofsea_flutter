// lib/views/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/permission_provider.dart';
import 'package:seaofsea/views/admin_tool_panel.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final canAdmin = context.select<PermissionProvider, bool>((p) => p.can('admin.access'));

    return CustomScaffold(
      title: 'Admin Dashboard',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: canAdmin
            ? const AdminToolsPanel()
            : const Center(
                child: Text('403 • Admin access required'),
              ),
      ),
    );
  }
}
