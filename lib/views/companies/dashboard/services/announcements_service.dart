import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';

class AnnouncementItem {
  final int id;
  final String title;
  final String? body;
  final bool pinned;
  final String status; // active/hidden/archived
  final DateTime? createdAt;

  AnnouncementItem({
    required this.id,
    required this.title,
    this.body,
    required this.pinned,
    required this.status,
    this.createdAt,
  });

  factory AnnouncementItem.fromMap(Map m) {
    DateTime? ts;
    final raw = (m['created_at'] ?? m['createdAt'])?.toString();
    if (raw != null && raw.isNotEmpty) {
      final norm = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
      ts = DateTime.tryParse(norm);
    }
    return AnnouncementItem(
      id: int.tryParse('${m['id'] ?? 0}') ?? 0,
      title: (m['title'] ?? '').toString(),
      body: (m['body'] ?? m['content'])?.toString(),
      pinned: (m['pinned'] == 1 || '${m['pinned']}'.toLowerCase() == 'true'),
      status: (m['status'] ?? 'active').toString(),
      createdAt: ts,
    );
  }
}

class AnnouncementsService {
  final V1ApiManager api;
  AnnouncementsService(this.api);

  Future<bool> create({
    required int companyId,
    required String title,
    String? body,
    String visibility = 'public', // 'public' | 'followers' | 'internal'
    bool pinned = false,
    BuildContext? context,
  }) async {
    final res = await api.call(
      module: 'Company_announcement',
      action: 'create',
      params: {
        'company_id': companyId,
        'title': title,
        if (body != null) 'body': body,
        'visibility': visibility,
        'pinned': pinned ? 1 : 0,
      },
      context: context,
    );
    // V1ApiManager success:true döndürüyorsa yeterli
    return res['success'] == true;
  }

  /// Kullanıcının bu şirkette yeni anons oluşturup oluşturamayacağını döndürür.
  /// Şimdilik admin/editor kontrolü ile yapılır (ileride backend 'can_manage' eklenirse ona geçilebilir).
  Future<bool> canCreate({
    required int companyId,
    BuildContext? context,
  }) async {
    final res = await api.call(
      module: 'company',
      action: 'my_role',
      params: {'company_id': companyId},
      context: context,
    );

    String role = 'none';
    final data = res['data'];
    if (data is Map && data['role'] != null) {
      role = data['role'].toString();
    } else if (res['role'] != null) {
      role = res['role'].toString();
    }

    return role == 'admin' || role == 'editor';
  }

  Future<List<AnnouncementItem>> fetchLatest({
    required int companyId,
    int limit = 10,
    bool includeHidden = false, // çalışanlar için gizlileri de görmek istersen
    BuildContext? context,
  }) async {
    final res = await api.call(
      module: 'Company_announcement', // Company_announcementHandler
      action: 'list',
      params: {
        'company_id': companyId,
        'perPage': limit,
        'page': 1,
        if (includeHidden) 'include_hidden': 1,
        // status paramı backend'de zorunlu değil; list default active döndürür
      },
      context: context,
    );

    final data = res['data'];
    List items;
    if (data is Map && data['items'] is List) {
      items = data['items'];
    } else if (data is List) {
      items = data;
    } else {
      return [];
    }

    return items
        .whereType<Map>()
        .map((e) => AnnouncementItem.fromMap(e))
        .toList();
  }

  Future<bool> update({
    required int id,
    String? title,
    String? body,
    String? visibility, // public|followers|internal
    bool? pinned,
    DateTime? startsAt,
    DateTime? endsAt,
    BuildContext? context,
  }) async {
    final params = <String, dynamic>{'id': id};
    if (title != null) params['title'] = title;
    if (body != null) params['body'] = body;
    if (visibility != null) params['visibility'] = visibility;
    if (pinned != null) params['pinned'] = pinned ? 1 : 0;
    if (startsAt != null) {
      params['starts_at'] =
          startsAt.toIso8601String().replaceFirst('T', ' ').split('.').first;
    }
    if (endsAt != null) {
      params['ends_at'] =
          endsAt.toIso8601String().replaceFirst('T', ' ').split('.').first;
    }

    final res = await api.call(
      module: 'company_announcement',
      action: 'update',
      params: params,
      context: context,
    );
    return res['success'] == true || res['data']?['updated'] == true;
  }

  Future<bool> setPinned({
    required int id,
    required bool pinned,
    BuildContext? context,
  }) async {
    final res = await api.call(
      module: 'company_announcement',
      action: pinned ? 'pin' : 'unpin',
      params: {'id': id},
      context: context,
    );
    return res['success'] == true || res['data']?['success'] == true;
  }

  Future<bool> setStatus({
    required int id,
    required String status, // 'hidden' | 'active' | 'archived'
    BuildContext? context,
  }) async {
    final action = switch (status) {
      'hidden' => 'hide',
      'active' => 'unhide', // gizliyse aktive eder, archived değilse
      'archived' => 'archive',
      _ => 'unhide',
    };
    final res = await api.call(
      module: 'company_announcement',
      action: action,
      params: {'id': id},
      context: context,
    );
    return res['success'] == true || res['data']?['success'] == true;
  }
}

extension AnnouncementsServiceX on BuildContext {
  AnnouncementsService announcementsService() =>
      AnnouncementsService(read<V1ApiManager>());
}
