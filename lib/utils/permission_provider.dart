import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';

class PermissionProvider with ChangeNotifier {
  final V1ApiManager _api = V1ApiManager();

  /// Sözlük: tüm permission kodları (opsiyonel kullanılır)
  List<Map<String, dynamic>> _dictionary = [];

  /// Kullanıcının etkin izin seti (grant + role - revoke)
  final Set<String> _effective = {};

  bool _loading = false;
  String? _error;

  bool get isLoading => _loading;
  String? get error => _error;
  Set<String> get effective => _effective;
  List<Map<String, dynamic>> get dictionary => _dictionary;

  /// UI tarafında görünürlük kontrolü
  bool can(String code) => _effective.contains(code);

  /// Uygulama açılışı / login sonrası çağır
  Future<void> fetchUserPermissions({int? userId, int? companyId}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // 1) opsiyon: sözlük
      final dictRes = await _api.call(
        module: 'permission',
        action: 'getAll',
        params: {'scope': 'global'},
      );
      if (dictRes['success'] == true) {
        _dictionary = (dictRes['data']?['permissions'] ??
                dictRes['permissions'] ??
                []) // router/response farkları için esnek
            .cast<Map<String, dynamic>>();
      }

      // 2) etkin set
      final effRes = await _api.call(
        module: 'permission',
        action: 'effective',
        params: {
          if (userId != null) 'user_id': userId,
          if (companyId != null) 'company_id': companyId,
        },
      );
      if (effRes['success'] == true) {
        final list =
            (effRes['data']?['effective'] ?? effRes['effective'] ?? []) as List;
        _effective
          ..clear()
          ..addAll(list.map((e) => e.toString()));
      } else {
        _error = effRes['message'] ?? 'Failed to load effective permissions';
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode)
        print('PermissionProvider.fetchUserPermissions error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Anlık kontrol (backend check)
  Future<bool> check(String code, {int? companyId}) async {
    try {
      final res = await _api.call(
        module: 'permission',
        action: 'check',
        params: {
          'permission_code': code,
          if (companyId != null) 'company_id': companyId,
        },
      );
      final allowed = (res['data']?['allowed'] ?? res['allowed']) == true;
      // İstersen optimistic olarak local cache'e de yazabilirsin:
      if (allowed) _effective.add(code);
      notifyListeners();
      return allowed;
    } catch (_) {
      return false;
    }
  }

  /// Grant (admin tarafından)
  Future<bool> assign({
    required int userId,
    required String code,
    int? companyId,
    String? note,
    DateTime? expiresAt,
  }) async {
    final res = await _api.call(
      module: 'permission',
      action: 'assign',
      params: {
        'user_id': userId,
        'permission_code': code,
        if (companyId != null) 'company_id': companyId,
        if (note != null) 'note': note,
        if (expiresAt != null)
          'expires_at': expiresAt
              .toIso8601String()
              .replaceFirst('T', ' ')
              .split('.')
              .first,
      },
    );
    return res['success'] == true;
  }

  /// Revoke (admin tarafından)
  Future<bool> revoke({
    required int userId,
    required String code,
    int? companyId,
    String? note,
  }) async {
    final res = await _api.call(
      module: 'permission',
      action: 'revoke',
      params: {
        'user_id': userId,
        'permission_code': code,
        if (companyId != null) 'company_id': companyId,
        if (note != null) 'note': note,
      },
    );
    return res['success'] == true;
  }

  static PermissionProvider of(BuildContext context, {bool listen = false}) =>
      Provider.of<PermissionProvider>(context, listen: listen);

  static PermissionProvider? maybeOf(BuildContext context,
      {bool listen = false}) {
    try {
      return Provider.of<PermissionProvider>(context, listen: listen);
    } catch (_) {
      return null;
    }
  }
}
