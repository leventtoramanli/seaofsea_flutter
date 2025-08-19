// lib/services/v1/company_service.dart
import 'dart:io';

import 'package:seaofsea/services/v1/v1_api_manager.dart';

class CompanyService {
  final V1ApiManager api;
  CompanyService(this.api);

  // ---- READS ----

  Future<Map<String, dynamic>?> getCompanyDetail(int companyId) async {
    final res = await api.call(
      module: 'company',
      action: 'detail',
      params: {'id': companyId}, // helpers ile uyumlu
      requiresAuth: false,
    );
    return res['success'] == true && res['data'] is Map
        ? Map<String, dynamic>.from(res['data'])
        : null;
  }

  Future<String> getMyRole(int companyId) async {
    final res = await api.call(
      module: 'company',
      action: 'my_role',
      params: {'company_id': companyId},
      requiresAuth: true,
    );
    if (res['success'] == true && res['data'] is Map) {
      final role = (res['data']['role'] ?? '').toString();
      return role.isEmpty ? 'none' : role; // admin|editor|viewer|follower|none
    }
    return 'none';
  }

  Future<List<Map<String, dynamic>>> getCompanyTypes(
      {List<int>? filterIds, int perPage = 500}) async {
    final res = await api.call(
      module: 'company',
      action: 'types',
      params: {
        if (filterIds != null && filterIds.isNotEmpty) 'filter_ids': filterIds,
        'perPage': perPage, // helpers ile uyumlu
      },
      requiresAuth: false,
    );

    final data = res['success'] == true ? res['data'] : null;
    List items;
    if (data is List) {
      items = data;
    } else if (data is Map && data['items'] is List) {
      items = data['items'];
    } else {
      items = const [];
    }

    return items
        .where((e) => e is Map && e['id'] != null && e['name'] != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  Future<List<Map<String, dynamic>>> getCompanyFollowers(int companyId) async {
    final res = await api.call(
      module: 'company',
      action: 'get_company_followers',
      params: {'company_id': companyId},
      requiresAuth: true,
    );
    final data = res['success'] == true ? res['data'] : null;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else if (data is Map && data['items'] is List) {
      return (data['items'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> getCompanyMembers(int companyId) async {
    final res = await api.call(
      module: 'company',
      action: 'members_list',
      params: {'company_id': companyId},
      requiresAuth: true,
    );
    final data = res['success'] == true ? res['data'] : null;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else if (data is Map && data['items'] is List) {
      return (data['items'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  // ---- WRITES ----
  // helpers'ta tüm güncellemeler tek 'company.update' üzerinden: id ile gider.

  Future<bool> updateCompanyTypes({
    required int companyId,
    required List<int> typeIds,
  }) async {
    final res = await api.call(
      module: 'company',
      action: 'update',
      params: {
        'id': companyId,
        'type_ids': typeIds,
      },
      requiresAuth: true,
    );
    return res['success'] == true;
  }

  Future<bool> updateContactInfo({
    required int companyId,
    required Map<String, List<Map<String, String>>> contactInfo,
  }) async {
    final res = await api.call(
      module: 'company',
      action: 'update',
      params: {
        'id': companyId,
        'contact_info': contactInfo,
      },
      requiresAuth: true,
    );
    return res['success'] == true;
  }

  Future<void> uploadLogo({
    required int companyId,
    required File file,
    String? mime, // image/png vs
    void Function(double p)? onProgress,
  }) async {
    await api.call(
      module: 'company',
      action: 'upload_logo',
      params: {'company_id': companyId},
      file: file,
      fileType: mime,
      onProgress: onProgress,
    );
  }

  // admin popup aksiyonları
  Future<bool> hideCompany(int companyId) async {
    final res = await api.call(
      module: 'company',
      action: 'hide',
      params: {'company_id': companyId},
      requiresAuth: true,
    );
    return res['success'] == true;
  }

  Future<bool> unhideCompany(int companyId) async {
    final res = await api.call(
      module: 'company',
      action: 'unhide',
      params: {'company_id': companyId},
      requiresAuth: true,
    );
    return res['success'] == true;
  }

  Future<bool> archiveCompany(int companyId) async {
    final res = await api.call(
      module: 'company',
      action: 'archive',
      params: {'company_id': companyId},
      requiresAuth: true,
    );
    final ok = (res['success'] == true) || (res['data']?['deleted'] == true);
    return ok == true;
  }

  Future<bool> deleteCompanyHard({
    required int companyId,
    required String confirmPhrase,
    required String password,
  }) async {
    final res = await api.call(
      module: 'company',
      action: 'delete',
      params: {
        'company_id': companyId,
        'confirm_phrase': confirmPhrase,
        'password': password,
      },
      requiresAuth: true,
    );
    return res['success'] == true;
  }

  Future<void> follow(int companyId) async => api.call(
      module: 'company', action: 'follow', params: {'company_id': companyId});

  Future<void> unfollow(int companyId) async => api.call(
      module: 'company', action: 'unfollow', params: {'company_id': companyId});

  Future<Map<String, dynamic>> followStatus(int companyId) async {
    final res = await api.call(
        module: 'company',
        action: 'follow_status',
        params: {'company_id': companyId});
    return Map<String, dynamic>.from(res['data'] ?? {});
  }
}
