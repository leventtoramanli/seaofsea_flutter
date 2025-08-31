import 'package:flutter/foundation.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';

/// V1 Position API wrapper
///
/// Backend: PositionHandler (module: 'position')
/// - get_position_areas()
/// - get_positions_by_area(area)
/// - get_permissions(position_id)
/// - update_permissions(position_id, permission_codes)
class PositionsServiceV1 {
  final V1ApiManager api;
  PositionsServiceV1({required this.api});

  /// Helper: API dönüşündeki 'data' katmanını esnekçe ayıklar
  T? _dataOf<T>(Map<String, dynamic> res) {
    final d = res['data'];
    if (d is T) return d;
    if (res is T) return res as T;
    return null;
  }

  /// Bölge/alan haritasını getirir.
  /// Örnek dönüş: { "Ship": ["Deck","Engine","Catering"], "Office":["HR","Operations",...] }
  Future<Map<String, List<String>>> getAreas() async {
    try {
      final res = await api.call(
        module: 'position',
        action: 'get_position_areas',
        params: const {},
        requiresAuth: true,
      );
      if (kDebugMode) debugPrint('[PositionsServiceV1] getAreas raw: $res');

      if (res['success'] != true) return {};
      final data = _dataOf<Map<String, dynamic>>(res) ??
          res['data'] as Map<String, dynamic>?;

      if (data == null) return {};
      final out = <String, List<String>>{};
      data.forEach((key, value) {
        if (value is List) {
          out[key.toString()] = value.map((e) => e.toString()).toList();
        }
      });
      return out;
    } catch (e) {
      debugPrint('getAreas error: $e');
      return {};
    }
  }

  /// Verilen area için pozisyon adlarını döndürür.
  /// Şimdilik backend örneği: [{name:"Captain"}, {name:"Chief Officer"}, ...]
  Future<List<String>> getPositionsByArea(String area) async {
    try {
      final res = await api.call(
        module: 'position',
        action: 'get_positions_by_area',
        params: {'area': area},
        requiresAuth: true,
      );
        debugPrint(
            '[PositionsServiceV1] getPositionsByArea("$area") raw: $res');

      if (res['success'] != true) return [];
      final data = _dataOf<Map<String, dynamic>>(res) ??
          res['data'] as Map<String, dynamic>?;
      // Router bazı durumlarda listeyi direkt data yerine döndürebilir:
      final maybeList = (data?['items'] ?? data ?? res['data']);
      if (maybeList is List) {
        return maybeList
            .map((e) => (e is Map && e['name'] != null)
                ? e['name'].toString()
                : e.toString())
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('getPositionsByArea error: $e');
      return [];
    }
  }

  /// Pozisyonun izin kodlarını getirir.
  Future<PositionPermissions?> getPermissions(int positionId) async {
    try {
      final res = await api.call(
        module: 'position',
        action: 'get_permissions',
        params: {'position_id': positionId},
        requiresAuth: true,
      );
        debugPrint(
            '[PositionsServiceV1] getPermissions($positionId) raw: $res');

      if (res['success'] != true) return null;
      final data = res['data'] as Map<String, dynamic>? ?? const {};

      final id = (data['id'] ?? data['position_id']);
      final name = (data['name'] ?? '').toString();
      final codesDyn = data['permission_codes'];
      final codes = (codesDyn is List)
          ? codesDyn.map((e) => e.toString()).toList()
          : <String>[];

      final pid = (id is int) ? id : int.tryParse(id?.toString() ?? '');
      if (pid == null) return null;

      return PositionPermissions(id: pid, name: name, codes: codes);
    } catch (e) {
      if (kDebugMode) debugPrint('getPermissions error: $e');
      return null;
    }
  }

  /// Pozisyonun izin kodlarını günceller.
  /// Backend başarılıysa güncel kod listesini geri döndürür.
  Future<List<String>> updatePermissions({
    required int positionId,
    required List<String> codes,
  }) async {
    try {
      final res = await api.call(
        module: 'position',
        action: 'update_permissions',
        params: {
          'position_id': positionId,
          'permission_codes': codes,
        },
        requiresAuth: true,
      );
        debugPrint(
            '[PositionsServiceV1] updatePermissions($positionId) raw: $res');

      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>? ?? const {};
        final updated = data['permission_codes'];
        if (updated is List) {
          return updated.map((e) => e.toString()).toList();
        }
        // Bazı routerlarda data sarmalanmadan dönebilir:
        if (res['permission_codes'] is List) {
          return (res['permission_codes'] as List)
              .map((e) => e.toString())
              .toList();
        }
        return codes; // en azından yerel gönderdiğimizi dön
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('updatePermissions error: $e');
      return [];
    }
  }
}

/// Basit DTO
class PositionPermissions {
  final int id;
  final String name;
  final List<String> codes;

  PositionPermissions({
    required this.id,
    required this.name,
    required this.codes,
  });
}
