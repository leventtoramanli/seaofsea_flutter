// lib/services/v1/applications_service.dart
//
// SeaOfSea - Applications Service (v1)  |  uses V1ApiManager.call(...)
// Backend module: "application"
//
// Sağladığı metodlar:
// - create, getMyApplications, getCompanyApplications, getApplicationDetail,
//   updateApplication, moveStatus, withdraw, assignReviewer,
//   addNote, getNotes, getTimeline
//
// Not: V1ApiManager zaten device_* paramlarını ekliyor ve
//      {success,message,data,code} şeklinde dönüyor.

import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, {this.status});
  @override
  String toString() => 'ApiException($status): $message';
}

T _unwrap<T>(Map<String, dynamic> raw, {T Function(dynamic data)? map}) {
  final ok = raw['success'] == true;
  final data = raw['data'];
  if (!ok) {
    final msg = (raw['message'] ?? 'Request failed').toString();
    final code = raw['code'] is int ? raw['code'] as int : null;
    throw ApiException(msg, status: code);
  }
  if (map != null) return map(data);
  return data as T;
}

String _fmtYmd(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

class ApplicationsServiceV1 {
  final V1ApiManager api;
  ApplicationsServiceV1(this.api);

  /* ================== CREATE ================== */
  Future<ApplicationCreateResult> create({
    required int companyId,
    required int jobPostId,
    String? coverLetter,
    List<Map<String, dynamic>>? attachments, // JSON'e çevrilir
    String status = 'submitted',
    String source = 'internal',
    BuildContext? context,
  }) async {
    final res = await api.call(
      module: 'application',
      action: 'create',
      context: context,
      params: {
        'company_id': companyId,
        'job_post_id': jobPostId,
        if (coverLetter != null) 'cover_letter': coverLetter,
        if (attachments != null) 'attachments': jsonEncode(attachments),
        'status': status,
        'source': source,
      },
    );
    return _unwrap<ApplicationCreateResult>(res, map: (d) {
      return ApplicationCreateResult(
        id: d['id'] is int ? d['id'] as int : int.parse('${d['id']}'),
        status: (d['status'] ?? '').toString(),
      );
    });
  }

  /* ================== LIST (User) ================== */
  Future<PagedApplications> getMyApplications({
    int? companyId,
    String? status,
    int limit = 25,
    int offset = 0,
    BuildContext? context,
  }) async {
    final res = await api.call(
      module: 'application',
      action: 'list_by_user',
      context: context,
      params: {
        if (companyId != null) 'company_id': companyId,
        if (status != null) 'status': status,
        'limit': limit,
        'offset': offset,
      },
    );
    return _unwrap<PagedApplications>(res,
        map: (d) => PagedApplications.fromJson(d));
  }

  /* ================== LIST (Company) ================== */
  Future<PagedApplications> getCompanyApplications({
    required int companyId,
    int? jobPostId,
    String? status,
    String? q,
    DateTime? dateFrom,
    DateTime? dateTo,
    int limit = 25,
    int offset = 0,
    BuildContext? context,
  }) async {
    final res = await api.call(
      module: 'application',
      action: 'list_by_company',
      context: context,
      params: {
        'company_id': companyId,
        if (jobPostId != null) 'job_post_id': jobPostId,
        if (status != null) 'status': status,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (dateFrom != null) 'date_from': _fmtYmd(dateFrom),
        if (dateTo != null) 'date_to': _fmtYmd(dateTo),
        'limit': limit,
        'offset': offset,
      },
    );
    return _unwrap<PagedApplications>(res,
        map: (d) => PagedApplications.fromJson(d));
  }

  /* ================== DETAIL ================== */
  Future<Application> getApplicationDetail({
    required int id,
    BuildContext? context,
  }) async {
    final res = await api.call(
      module: 'application',
      action: 'detail',
      context: context,
      params: {'id': id},
    );
    return _unwrap<Application>(res, map: (d) {
      final app =
          d is Map<String, dynamic> && d['application'] is Map<String, dynamic>
              ? d['application'] as Map<String, dynamic>
              : d as Map<String, dynamic>;
      return Application.fromJson(app);
    });
  }

  /* ================== UPDATE ================== */
  Future<bool> updateApplication({
    required int id,
    String? coverLetter,
    List<Map<String, dynamic>>? attachments, // JSON'e çevrilir
    String? tags,
    BuildContext? context,
  }) async {
    final res = await api.call(
      module: 'application',
      action: 'update',
      context: context,
      params: {
        'id': id,
        if (coverLetter != null) 'cover_letter': coverLetter,
        if (attachments != null) 'attachments': jsonEncode(attachments),
        if (tags != null) 'tags': tags,
      },
    );
    return _unwrap<bool>(res, map: (d) => (d['updated'] ?? false) == true);
  }

  /* ================== MOVE STATUS ================== */
  Future<MoveStatusResult> moveStatus({
    required int id,
    required String to,
    String? note,
    BuildContext? context,
  }) async {
    final res = await api.call(
      module: 'application',
      action: 'move_status',
      context: context,
      params: {
        'id': id,
        'to': to,
        if (note != null) 'note': note,
      },
    );
    return _unwrap<MoveStatusResult>(res, map: (d) {
      return MoveStatusResult(
        moved: (d['moved'] ?? false) == true,
        from: (d['from'] ?? '').toString(),
        to: (d['to'] ?? '').toString(),
      );
    });
  }

  /* ================== WITHDRAW ================== */
  Future<bool> withdraw({
    required int id,
    BuildContext? context,
  }) async {
    final res = await api.call(
      module: 'application',
      action: 'withdraw',
      context: context,
      params: {'id': id},
    );
    return _unwrap<bool>(res, map: (d) => (d['withdrawn'] ?? false) == true);
  }

  /* ================== ASSIGN REVIEWER ================== */
  Future<bool> assignReviewer({
    required int id,
    required int assignedTo,
    BuildContext? context,
  }) async {
    final res = await api.call(
      module: 'application',
      action: 'assign_reviewer',
      context: context,
      params: {'id': id, 'assigned_to': assignedTo},
    );
    return _unwrap<bool>(res, map: (d) => (d['assigned'] ?? false) == true);
  }

  /* ================== NOTES ================== */
  Future<int> addNote({
    required int applicationId,
    required String note,
    BuildContext? context,
  }) async {
    final res = await api.call(
      module: 'application',
      action: 'add_note',
      context: context,
      params: {'application_id': applicationId, 'note': note},
    );
    return _unwrap<int>(res, map: (d) {
      final id = d['id'];
      return id is int ? id : int.parse('$id');
    });
  }

  Future<List<ApplicationNote>> getNotes({
    required int applicationId,
    BuildContext? context,
  }) async {
    final res = await api.call(
      module: 'application',
      action: 'list_notes',
      context: context,
      params: {'application_id': applicationId},
    );
    return _unwrap<List<ApplicationNote>>(res, map: (d) {
      final items = (d['items'] as List<dynamic>? ?? const []);
      return items
          .map((e) => ApplicationNote.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /* ================== TIMELINE ================== */
  Future<List<TimelineItem>> getTimeline({
    required int applicationId,
    BuildContext? context,
  }) async {
    final res = await api.call(
      module: 'application',
      action: 'timeline',
      context: context,
      params: {'application_id': applicationId},
    );
    return _unwrap<List<TimelineItem>>(res, map: (d) {
      final items = (d['items'] as List<dynamic>? ?? const []);
      return items
          .map((e) => TimelineItem.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }
}

/* ================== MODELLER ================== */

class ApplicationCreateResult {
  final int id;
  final String status;
  ApplicationCreateResult({required this.id, required this.status});
}

class PagedApplications {
  final List<Application> items;
  final int total;
  final int limit;
  final int offset;

  PagedApplications({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory PagedApplications.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>? ?? const [])
        .map((e) => Application.fromJson(e as Map<String, dynamic>))
        .toList();
    int _asInt(dynamic v, int def) => v is int ? v : int.tryParse('$v') ?? def;
    return PagedApplications(
      items: list,
      total: _asInt(json['total'], 0),
      limit: _asInt(json['limit'] ?? json['perPage'], 25),
      offset: _asInt(json['offset'], 0),
    );
  }
}

class Application {
  final int id;
  final int userId;
  final int companyId;
  final int? jobPostId;
  final String status;
  final String? coverLetter;
  final String? tags;
  final int? assignedTo;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? attachmentsJson;
  final String? source;

  Application({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.status,
    required this.createdAt,
    this.jobPostId,
    this.coverLetter,
    this.tags,
    this.assignedTo,
    this.updatedAt,
    this.attachmentsJson,
    this.source,
  });

  factory Application.fromJson(Map<String, dynamic> j) {
    DateTime? _dt(v) {
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    int? _i(v) => v == null ? null : (v is int ? v : int.tryParse('$v'));

    return Application(
      id: j['id'] is int ? j['id'] : int.parse('${j['id']}'),
      userId: j['user_id'] is int ? j['user_id'] : int.parse('${j['user_id']}'),
      companyId: j['company_id'] is int
          ? j['company_id']
          : int.parse('${j['company_id']}'),
      jobPostId: _i(j['job_post_id']),
      status: (j['status'] ?? '').toString(),
      coverLetter: j['cover_letter']?.toString(),
      tags: j['tags']?.toString(),
      assignedTo: _i(j['assigned_to']),
      createdAt: _dt(j['created_at']) ?? DateTime.now(),
      updatedAt: _dt(j['updated_at']),
      attachmentsJson: j['attachments']?.toString(),
      source: j['source']?.toString(),
    );
  }
}

class ApplicationNote {
  final int id;
  final int applicationId;
  final int? authorUserId;
  final String note;
  final DateTime createdAt;
  final String? authorName;

  ApplicationNote({
    required this.id,
    required this.applicationId,
    required this.note,
    required this.createdAt,
    this.authorUserId,
    this.authorName,
  });

  factory ApplicationNote.fromJson(Map<String, dynamic> j) {
    DateTime _dt(v) {
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    int? _i(v) => v == null ? null : (v is int ? v : int.tryParse('$v'));
    String? _authorFromParts() {
      final n = j['author_name']?.toString();
      final s = j['author_surname']?.toString();
      if ((n == null || n.isEmpty) && (s == null || s.isEmpty)) return null;
      return [n, s].where((e) => e != null && e!.isNotEmpty).join(' ');
    }

    return ApplicationNote(
      id: j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
      applicationId: _i(j['application_id']) ?? 0,
      authorUserId: _i(j['author_user_id']),
      note: (j['note'] ?? '').toString(),
      createdAt: _dt(j['created_at']),
      authorName: j['author']?.toString() ?? _authorFromParts(),
    );
  }
}

class TimelineItem {
  final String type; // 'history' | 'note'
  final DateTime createdAt;
  final String? oldStatus;
  final String? newStatus;
  final int? changedBy;
  final String? note;
  final String? author;

  TimelineItem({
    required this.type,
    required this.createdAt,
    this.oldStatus,
    this.newStatus,
    this.changedBy,
    this.note,
    this.author,
  });

  factory TimelineItem.fromJson(Map<String, dynamic> j) {
    DateTime _dt(v) {
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    int? _i(v) => v == null ? null : (v is int ? v : int.tryParse('$v'));
    return TimelineItem(
      type: (j['type'] ?? '').toString(),
      createdAt: _dt(j['created_at']),
      oldStatus: j['old_status']?.toString(),
      newStatus: j['new_status']?.toString(),
      changedBy: _i(j['changed_by']),
      note: j['note']?.toString(),
      author: j['author']?.toString(),
    );
  }
}

class MoveStatusResult {
  final bool moved;
  final String from;
  final String to;
  MoveStatusResult({required this.moved, required this.from, required this.to});
}
