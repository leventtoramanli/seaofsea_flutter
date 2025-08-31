import 'dart:convert';

class Application {
  final int id;
  final int companyId;
  final int userId;
  final int? jobPostId;
  final String status;
  final String? message; // cover_letter/message
  final Map<String, dynamic>? cvSnapshot;
  final List<dynamic>? attachments;
  final int? assignedTo;
  final String? tags;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // opsiyonel alanlar (listeleme join'lerinden gelebilir)
  final String? jobTitle;
  final String? candidateName;
  final String? candidateSurname;
  final String? candidateEmail;

  Application({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.status,
    required this.createdAt,
    this.jobPostId,
    this.message,
    this.cvSnapshot,
    this.attachments,
    this.assignedTo,
    this.tags,
    this.updatedAt,
    this.jobTitle,
    this.candidateName,
    this.candidateSurname,
    this.candidateEmail,
  });

  factory Application.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic>? _cv;
    if (j['cv_snapshot'] is String) {
      try {
        _cv = json.decode(j['cv_snapshot']);
      } catch (_) {}
    } else if (j['cv_snapshot'] is Map) {
      _cv = Map<String, dynamic>.from(j['cv_snapshot']);
    }
    List<dynamic>? _att;
    if (j['attachments'] is String) {
      try {
        _att = json.decode(j['attachments']);
      } catch (_) {}
    } else if (j['attachments'] is List) {
      _att = List<dynamic>.from(j['attachments']);
    }
    DateTime _dt(String s) {
      // 'YYYY-MM-DD HH:mm:ss' veya ISO her ikisini de yut
      return DateTime.tryParse(s.replaceFirst(' ', 'T')) ?? DateTime.now();
    }

    return Application(
      id: int.tryParse('${j['id']}') ?? 0,
      companyId: int.tryParse('${j['company_id']}') ?? 0,
      userId: int.tryParse('${j['user_id']}') ?? 0,
      jobPostId:
          j['job_post_id'] != null ? int.tryParse('${j['job_post_id']}') : null,
      status: (j['status'] ?? '').toString(),
      message: (j['cover_letter'] ?? j['message'])?.toString(),
      cvSnapshot: _cv,
      attachments: _att,
      assignedTo:
          j['assigned_to'] != null ? int.tryParse('${j['assigned_to']}') : null,
      tags: j['tags']?.toString(),
      createdAt:
          _dt((j['created_at'] ?? DateTime.now().toIso8601String()).toString()),
      updatedAt:
          (j['updated_at'] != null) ? _dt(j['updated_at'].toString()) : null,
      jobTitle: j['job_title']?.toString(),
      candidateName: j['name']?.toString(),
      candidateSurname: j['surname']?.toString(),
      candidateEmail: j['email']?.toString(),
    );
  }
}

class ApplicationNote {
  final int id;
  final int authorUserId;
  final String note;
  final DateTime createdAt;
  final String? authorName;

  ApplicationNote({
    required this.id,
    required this.authorUserId,
    required this.note,
    required this.createdAt,
    this.authorName,
  });

  factory ApplicationNote.fromJson(Map<String, dynamic> j) {
    DateTime _dt(String s) =>
        DateTime.tryParse(s.replaceFirst(' ', 'T')) ?? DateTime.now();
    return ApplicationNote(
      id: int.tryParse('${j['id'] ?? 0}') ?? 0,
      authorUserId:
          int.tryParse('${j['author_user_id'] ?? j['actor_id'] ?? 0}') ?? 0,
      note: (j['note'] ?? '').toString(),
      createdAt:
          _dt((j['created_at'] ?? DateTime.now().toIso8601String()).toString()),
      authorName: j['author']?.toString(),
    );
  }
}

class TimelineItem {
  final String type; // 'note' | 'history'
  final DateTime createdAt;
  final String? note;
  final String? author;
  final String? oldStatus;
  final String? newStatus;

  TimelineItem({
    required this.type,
    required this.createdAt,
    this.note,
    this.author,
    this.oldStatus,
    this.newStatus,
  });

  factory TimelineItem.fromJson(Map<String, dynamic> j) {
    DateTime _dt(String s) =>
        DateTime.tryParse(s.replaceFirst(' ', 'T')) ?? DateTime.now();
    return TimelineItem(
      type: (j['type'] ?? '').toString(),
      createdAt:
          _dt((j['created_at'] ?? DateTime.now().toIso8601String()).toString()),
      note: j['note']?.toString(),
      author: j['author']?.toString(),
      oldStatus: j['old_status']?.toString(),
      newStatus: j['new_status']?.toString(),
    );
  }
}
