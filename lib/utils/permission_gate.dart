import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';

class PermissionGate extends StatelessWidget {
  final String permissionCode;
  final int entityId;
  final String entityType;
  final Widget child;
  final bool wait;

  const PermissionGate({
    Key? key,
    required this.permissionCode,
    required this.entityId,
    required this.child,
    this.entityType = 'company',
    this.wait = false,
  }) : super(key: key);

  Future<bool> _checkPermission(BuildContext context) async {
    final api = Provider.of<ApiManager>(context, listen: false);
    final response = await api.post(context, 'check_permission', {
      'permission_code': permissionCode,
      'entity_type': entityType,
      'entity_id': entityId,
    });

    return response['success'] == true;
  }

  static Future<bool> check({
    required BuildContext context,
    required String permissionCode,
    required int entityId,
    String entityType = 'company',
  }) async {
    final api = Provider.of<ApiManager>(context, listen: false);
    final response = await api.post(context, 'check_permission', {
      'permission_code': permissionCode,
      'entity_type': entityType,
      'entity_id': entityId,
    });

    return response['success'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkPermission(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return wait
              ? const Center(child: CircularProgressIndicator())
              : const SizedBox.shrink();
        }

        if (snapshot.data == true) {
          return child;
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
