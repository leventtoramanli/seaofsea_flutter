import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';

class PermissionGate extends StatelessWidget {
  final String permissionCode;
  final int? companyId; // company scope; globals için null
  final Widget child;
  final bool wait;

  const PermissionGate({
    super.key,
    required this.permissionCode,
    required this.child,
    this.companyId,
    this.wait = false,
  });

  static bool _extractAllowed(Map<String, dynamic> res) {
    // Router "data" içine sarmış olabilir:
    final d = res['data'];
    if (d is Map && d['allowed'] != null) {
      final v = d['allowed'];
      return v == true || v == 1 || v == '1';
    }
    // Bazı durumlarda handler direkt dönmüş olabilir:
    if (res['allowed'] != null) {
      final v = res['allowed'];
      return v == true || v == 1 || v == '1';
    }
    return false;
  }

  static Future<bool> check({
    required BuildContext context,
    required String permissionCode,
    int? companyId,
  }) async {
    final v1 = context.read<V1ApiManager>();
    debugPrint(
        '[PermGate.check] -> code=$permissionCode, companyId=$companyId');
    final res = await v1.call(
      module: 'permission',
      action: 'check',
      params: {
        'permission_code': permissionCode,
        if (companyId != null) 'company_id': companyId,
      },
    );
    final ok = res['success'] == true;
    final allowed = ok ? _extractAllowed(res) : false;
    debugPrint(
        '[PermGate.check] <- success=$ok, allowed=$allowed, msg=${res['message']}');
    return allowed;
  }

  Future<bool> _checkPermission(BuildContext context) async {
    final v1 = context.read<V1ApiManager>();
    debugPrint(
        '[PermGate] call start: code=$permissionCode, companyId=$companyId');
    final res = await v1.call(
      module: 'permission',
      action: 'check',
      params: {
        'permission_code': permissionCode,
        if (companyId != null) 'company_id': companyId,
      },
    );
    final ok = res['success'] == true;
    final allowed = ok ? _extractAllowed(res) : false;
    debugPrint(
        '[PermGate] call done: success=$ok, allowed=$allowed, msg=${res['message']}, raw=$res');
    return allowed;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[PermGate.build] building for code=$permissionCode companyId=$companyId wait=$wait');
    return FutureBuilder<bool>(
      future: _checkPermission(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('[PermGate.build] waiting... code=$permissionCode');
          return wait
              ? const Center(child: CircularProgressIndicator())
              : const SizedBox.shrink();
        }
        final allowed = snapshot.data == true;
          debugPrint('[PermGate.build] done. code=$permissionCode allowed=$allowed');
        return allowed ? child : const SizedBox.shrink();
      },
    );
  }
}
