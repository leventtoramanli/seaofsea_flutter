import 'dart:convert';
import 'package:seaofsea/services/v1/v1_api_manager.dart';

/// Recruitment (Job Post + Application) tek servis altında toplanır.
/// Backend: module = "recruitment", action = "post_*" / "app_*"
///
/// Notlar:
/// - V1ApiManager.call zarfı normalize eder: success, message, data.
/// - Sayfalama: page, per_page (backend ile uyumlu).
/// - attachments/cv_snapshot JSON gönderilir (gerekirse ileride multipart ekleriz).
class RecruitmentServiceV1 {
  static final V1ApiManager api = V1ApiManager();
  static Future<dynamic> _call(String action, Map<String, dynamic> params) {
    return api.call(module: 'recruitment', action: action, params: params);
  }

  // ------------------------
  // POSTS (İLAN)
  // ------------------------

  /// İlan oluştur (draft)
  static Future<dynamic> postCreate({
    required int companyId,
    required String title,
    String? description,
    int? positionId,
    String? location,
    String? employmentType,
  }) {
    return _call('post_create', {
      'company_id': companyId,
      'title': title,
      if (description != null) 'description': description,
      if (positionId != null) 'position_id': positionId,
      if (location != null) 'location': location,
      if (employmentType != null) 'employment_type': employmentType,
    });
  }

  /// İlan güncelle
  static Future<dynamic> postUpdate({
    required int id,
    String? title,
    String? description,
    int? positionId,
    String? location,
    String? employmentType,
  }) {
    return _call('post_update', {
      'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (positionId != null) 'position_id': positionId,
      if (location != null) 'location': location,
      if (employmentType != null) 'employment_type': employmentType,
    });
  }

  static Future<dynamic> postPublish({required int id}) {
    return _call('post_publish', {'id': id});
  }

  static Future<dynamic> postClose({required int id}) {
    return _call('post_close', {'id': id});
  }

  static Future<dynamic> postDetail({required int id}) {
    return _call('post_detail', {'id': id});
  }

  /// İlan listele (company içi tüm statüler için izin gerektirir; yoksa yalnız published gelir)
  static Future<dynamic> postList({
    int? companyId,
    String? status, // draft|published|closed|archived
    String? q,
    int page = 1,
    int perPage = 25,
  }) {
    return _call('post_list', {
      if (companyId != null) 'company_id': companyId,
      if (status != null) 'status': status,
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      'page': page,
      'per_page': perPage,
    });
  }

  // ------------------------
  // APPLICATIONS (BAŞVURU)
  // ------------------------

  /// Başvuru gönder (pozisyona ya da genel şirkete)
  /// attachments & cvSnapshot JSON-serializable olmalı (Map/List)
  static Future<dynamic> appSubmit({
    required int companyId,
    int? jobPostId,
    String? coverLetter,
    dynamic cvSnapshot,
    dynamic attachments,
  }) {
    return _call('app_submit', {
      'company_id': companyId,
      if (jobPostId != null) 'job_post_id': jobPostId,
      if (coverLetter != null) 'cover_letter': coverLetter,
      if (cvSnapshot != null) 'cv_snapshot': cvSnapshot,
      if (attachments != null) 'attachments': attachments,
    });
  }

  static Future<dynamic> appWithdraw({required int applicationId}) {
    return _call('app_withdraw', {'application_id': applicationId});
  }

  /// Şirket başvuruları
  static Future<dynamic> appListForCompany({
    required int companyId,
    String? status, // submitted|under_review|shortlisted|interview|offered|hired|rejected|withdrawn
    int page = 1,
    int perPage = 25,
    int? jobPostId, // ileride backend filtresi eklenecek; şimdilik göndersek de sorun olmaz
  }) {
    return _call('app_list_for_company', {
      'company_id': companyId,
      if (status != null) 'status': status,
      if (jobPostId != null) 'job_post_id': jobPostId,
      'page': page,
      'per_page': perPage,
    });
  }

  /// Kullanıcının başvuruları (userId verilmezse kendi başvuruları)
  static Future<dynamic> appListForUser({
    int? userId,
    int? companyIdIfViewingOthers, // başkasını görüyorsak zorunlu (permission check)
  }) {
    return _call('app_list_for_user', {
      if (userId != null) 'user_id': userId,
      if (companyIdIfViewingOthers != null) 'company_id': companyIdIfViewingOthers,
    });
  }

  static Future<dynamic> appUpdateStatus({
    required int applicationId,
    required String newStatus,
    String? note,
  }) {
    return _call('app_update_status', {
      'application_id': applicationId,
      'new_status': newStatus,
      if (note != null) 'note': note,
    });
  }

  static Future<dynamic> appAssignReviewer({
    required int applicationId,
    required int reviewerUserId,
  }) {
    return _call('app_assign_reviewer', {
      'application_id': applicationId,
      'reviewer_user_id': reviewerUserId,
    });
  }

  static Future<dynamic> appAddNote({
    required int applicationId,
    required String note,
  }) {
    return _call('app_add_note', {
      'application_id': applicationId,
      'note': note,
    });
  }

  static Future<dynamic> appNotes({
    required int applicationId,
  }) {
    return _call('app_notes', {
      'application_id': applicationId,
    });
  }

  static Future<dynamic> postArchive({required int id}) {
    return _call('post_archive', {'id': id});
  }
  static Future<dynamic> postStats({required int companyId}) {
    return _call('post_stats', {'company_id': companyId});
  }

  static Future<dynamic> appStats({required int companyId, int? jobPostId}) {
    return _call('app_stats', {
      'company_id': companyId,
      if (jobPostId != null) 'job_post_id': jobPostId,
    });
  }
  static Future<dynamic> postOverview({required int id, int recent = 5}) {
    return _call('post_overview', {'id': id, 'recent': recent});
  }
}
