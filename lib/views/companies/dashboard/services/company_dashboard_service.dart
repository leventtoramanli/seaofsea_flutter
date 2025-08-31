import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/views/companies/dashboard/models/announcement.dart';
import 'package:seaofsea/views/companies/dashboard/models/dashboard_models.dart';

/// Company Dashboard için tüm API çağrıları ve veri normalize işlemleri.
class CompanyDashboardService {
  final V1ApiManager api;

  CompanyDashboardService(this.api);

  // ---- Backend param eşlemeleri
  static const Map<ApplicationStatus, String> statusParam = {
    ApplicationStatus.pending: 'pending',
    ApplicationStatus.preApproved: 'pre_approved',
    ApplicationStatus.approved: 'approved',
    ApplicationStatus.rejected: 'rejected',
    ApplicationStatus.waitingManagerApproval: 'waiting_manager_approval',
  };

  Future<String?> fetchRole(int companyId, {BuildContext? context}) async {
    final res = await api.call(
      module: 'company',
      action: 'my_role',
      params: {'company_id': companyId},
      context: context,
    );
    if (res is Map) {
      if (res['success'] == true && res['data'] is Map) {
        return (res['data']['role'] as String?) ?? 'none';
      }
      if (res['role'] != null) return res['role'].toString();
    }
    return 'none';
  }

  Future<Map<String, dynamic>?> fetchDetail(int companyId,
      {BuildContext? context}) async {
    final res = await api.call(
      module: 'company',
      action: 'detail',
      params: {'id': companyId},
      context: context,
    );
    if (res is Map) {
      if (res['success'] == true && res['data'] is Map) {
        return Map<String, dynamic>.from(res['data']);
      }
      if (res['id'] != null) {
        return Map<String, dynamic>.from(res);
      }
    }
    return null;
  }

  Future<int> fetchMembersTotal(
    int companyId, {
    String? status,
    BuildContext? context,
  }) async {
    final res = await api.call(
      module: 'company',
      action: 'members_list',
      params: {
        'company_id': companyId,
        if (status != null) 'status': status,
        'perPage': 1,
        'page': 1,
      },
      context: context,
    );
    return _parseTotal(res['data']);
  }

  Future<void> follow(int companyId, {BuildContext? context}) async {
    await api.call(
      module: 'company',
      action: 'follow',
      params: {'company_id': companyId},
      context: context,
    );
  }

  Future<void> unfollow(int companyId, {BuildContext? context}) async {
    await api.call(
      module: 'company',
      action: 'unfollow',
      params: {'company_id': companyId},
      context: context,
    );
  }

  Future<({bool isFollower, int count})> followStatus(
    int companyId, {
    BuildContext? context,
  }) async {
    final res = await api.call(
      module: 'company',
      action: 'follow_status',
      params: {'company_id': companyId},
      context: context,
    );

    // 👇 asıl payload 'data' içindedir
    final payload = (res is Map && res['data'] is Map)
        ? (res['data'] as Map)
        : (res as Map? ?? const {});

    bool isFollower = false;
    int count = 0;

    final f = payload['is_follower'];
    final c = payload['follower_count'];

    if (f != null) {
      final s = f.toString().toLowerCase();
      isFollower = (s == '1' || s == 'true');
    }
    if (c != null) {
      final t = int.tryParse(c.toString());
      if (t != null) count = t;
    }
    return (isFollower: isFollower, count: count);
  }

  Future<AnnouncementListResult> fetchAnnouncements(
    int companyId, {
    int page = 1,
    int perPage = 10,
    bool includeHidden = false,
    BuildContext? context,
  }) async {
    final res = await api.call(
      module: 'company_announcement',
      action: 'list',
      params: {
        'company_id': companyId,
        'page': page,
        'perPage': perPage,
        if (includeHidden) 'include_hidden': 1,
      },
      context: context,
    );

    final data = res['data'];
    if (data is! Map) return AnnouncementListResult([], 0);

    final items = <Announcement>[];
    final raw = data['items'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map)
          items.add(Announcement.fromMap(Map<String, dynamic>.from(e)));
      }
    }
    final total =
        int.tryParse('${data['total'] ?? items.length}') ?? items.length;
    return AnnouncementListResult(items, total);
  }

  Future<Map<ApplicationStatus, int>> fetchApplicationBuckets(
    int companyId, {
    BuildContext? context,
  }) async {
    Future<int> total(String? st) =>
        fetchMembersTotal(companyId, status: st, context: context);

    final r = await Future.wait<int>([
      total(statusParam[ApplicationStatus.pending]),
      total(statusParam[ApplicationStatus.preApproved]),
      total(statusParam[ApplicationStatus.approved]),
      total(statusParam[ApplicationStatus.rejected]),
      total(statusParam[ApplicationStatus.waitingManagerApproval]),
    ]);

    return {
      ApplicationStatus.pending: r[0],
      ApplicationStatus.preApproved: r[1],
      ApplicationStatus.approved: r[2],
      ApplicationStatus.rejected: r[3],
      ApplicationStatus.waitingManagerApproval: r[4],
    };
  }

  Future<int> fetchOpenJobs(int companyId, {BuildContext? context}) async {
    // Önce company_job modülü (varsa)
    try {
      final res1 = await api.call(
        module: 'companyjob',
        action: 'list',
        params: {
          'company_id': companyId,
          'status': 'open',
          'perPage': 1,
          'page': 1,
        },
        context: context,
      );
      final data1 = res1['data'];
      final t1 = _parseTotal(data1);
      if (t1 > 0 || _hasTotalKey(data1)) return t1;
    } catch (_) {}

    // Fallback: job modülü
    try {
      final res2 = await api.call(
        module: 'job',
        action: 'list',
        params: {
          'company_id': companyId,
          'status': 'open',
          'perPage': 1,
          'page': 1,
        },
        context: context,
      );
      return _parseTotal(res2['data']);
    } catch (_) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> fetchTopPeople(
    int companyId, {
    BuildContext? context,
  }) async {
    try {
      final res = await api.call(
        module: 'company',
        action: 'members_list',
        params: {
          'company_id': companyId,
          'status': 'approved',
          'perPage': 3,
          'page': 1,
        },
        context: context,
      );

      final data = res['data'];
      List list;
      if (data is Map && data['items'] is List) {
        list = data['items'] as List;
      } else if (data is List) {
        list = data;
      } else {
        return [];
      }

      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Map<String, List<Map<String, String>>> extractContact(dynamic raw) {
    Map<String, dynamic>? obj;
    try {
      if (raw == null) return {};
      if (raw is String && raw.trim().isNotEmpty) {
        obj = jsonDecode(raw) as Map<String, dynamic>?;
      } else if (raw is Map) {
        obj = Map<String, dynamic>.from(raw);
      }
    } catch (_) {}
    if (obj == null) return {};

    List<Map<String, String>> norm(dynamic v) {
      if (v is List) {
        return v
            .map<Map<String, String>>((e) {
              if (e is Map) {
                final m = Map<String, dynamic>.from(e);
                return {
                  'label': (m['label'] ?? '').toString(),
                  'value': (m['value'] ?? '').toString(),
                };
              }
              return {'label': '', 'value': e.toString()};
            })
            .where((m) => m['value']!.trim().isNotEmpty)
            .toList();
      }
      return const <Map<String, String>>[];
    }

    return {
      'phones': norm(obj['phones']),
      'emails': norm(obj['emails']),
      'websites': norm(obj['websites']),
      'addresses': norm(obj['addresses']),
    };
  }

  // ---- helpers
  int _parseTotal(dynamic data) {
    if (data is Map) {
      final total = data['total'];
      if (total is int) return total;
      if (total != null) {
        final t = int.tryParse(total.toString());
        if (t != null) return t;
      }
      if (data['items'] is List) {
        return (data['items'] as List).length;
      }
    } else if (data is List) {
      return data.length;
    }
    return 0;
  }

  bool _hasTotalKey(dynamic data) {
    if (data is Map && data.containsKey('total')) return true;
    return false;
  }
}
