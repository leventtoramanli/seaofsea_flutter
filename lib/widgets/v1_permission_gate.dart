import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';

/// V1 permission kontrolü için hafif bir gate.
/// Backend: module=permission, action=check
/// Param adları: permission_code, company_id (opsiyonel)
class V1PermissionGate extends StatelessWidget {
  final String code;
  final int? companyId;
  final Widget child;
  final bool wait;

  const V1PermissionGate({
    super.key,
    required this.code,
    required this.child,
    this.companyId,
    this.wait = false,
  });

  static bool _extractAllowed(Map<String, dynamic> res) {
    final d = res['data'];
    if (d is Map && d['allowed'] != null) {
      final v = d['allowed'];
      return v == true || v == 1 || v == '1';
    }
    if (res['allowed'] != null) {
      final v = res['allowed'];
      return v == true || v == 1 || v == '1';
    }
    return false;
  }

  static Future<bool> check({
    required BuildContext context,
    required String code,
    int? companyId,
  }) async {
    final v1 = context.read<V1ApiManager>();
    final res = await v1.call(
      module: 'permission',
      action: 'check',
      params: {
        'permission_code': code,
        if (companyId != null) 'company_id': companyId,
      },
    );
    if (res['success'] == true) {
      return _extractAllowed(res);
    }
    return false;
  }

  Future<bool> _check(BuildContext context) async {
    final v1 = context.read<V1ApiManager>();
    final res = await v1.call(
      module: 'permission',
      action: 'check',
      params: {
        'permission_code': code,
        if (companyId != null) 'company_id': companyId,
      },
    );
    if (res['success'] == true) {
      return _extractAllowed(res);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _check(context),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return wait
              ? const Center(child: CircularProgressIndicator())
              : const SizedBox.shrink();
        }
        return (snap.data == true) ? child : const SizedBox.shrink();
      },
    );
  }
}
