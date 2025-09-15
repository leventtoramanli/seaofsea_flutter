import 'package:flutter/foundation.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';

/// Recruitment (Job Post + Application) tek servis.
/// Backend: module="recruitment", action="post_*" / "app_*"
class RecruitmentServiceV1 {
  static final V1ApiManager api = V1ApiManager();
  static Future<dynamic> _call(String action, Map<String, dynamic> params) {
    return api.call(module: 'recruitment', action: action, params: params);
  }

  // ------------------------
  // POSTS (İLAN)
  // ------------------------

  /*static Future<int> countPublished({required int companyId}) async {
    final res = await api.call(
      module: 'recruitment',
      action: 'post_public_published_count',
      params: {'company_id': companyId},
      // public endpoint → auth zorunlu olmasın
      requiresAuth: false,
    );
    dynamic data = res['data'];
    debugPrint('countPublished: ${data['total']}');
    return data['total'];
  }*/
  // lib/services/v1/recruitment_service.dart
  static dynamic _unwrap(dynamic res) {
    var d = res;
    if (d is Map && d.containsKey('data')) d = d['data'];
    if (d is Map && d.containsKey('data')) d = d['data']; // ikinci kat
    return d;
  }

  static Map<String, dynamic> _normalizeList(dynamic res) {
    final d = _unwrap(res);
    List<Map<String, dynamic>> items = const [];
    int total = 0;

    if (d is Map) {
      final rawItems = d['items'];
      if (rawItems is List) {
        items = rawItems
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      final t = d['total'];
      if (t is int) total = t;
      if (t is String) total = int.tryParse(t) ?? items.length;
      if (t == null) total = items.length;
    } else if (d is List) {
      items =
          d.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      total = items.length;
    }

    return {'items': items, 'total': total};
  }

  static Future<int> countPublished({required int companyId}) async {
    final res = await _call('post_public_published_count', {
      'company_id': companyId,
    });

    // Şekil A: {success, data:{success, data:{total}, code}, code}
    if (res is Map) {
      final d1 = res['data'];
      if (d1 is Map) {
        final d2 = d1['data'];
        if (d2 is Map && d2.containsKey('total')) {
          final v = d2['total'];
          return v is int ? v : int.tryParse('$v') ?? 0;
        }
        // Şekil B: {success, data:{total}, code}
        if (d1.containsKey('total')) {
          final v = d1['total'];
          return v is int ? v : int.tryParse('$v') ?? 0;
        }
      }
      // Şekil C: normalize edilmiş: { total: N }
      if (res.containsKey('total')) {
        final v = res['total'];
        return v is int ? v : int.tryParse('$v') ?? 0;
      }
    }

    // Bazı backend’ler direkt int döndürebilir
    if (res is int) return res;

    return 0;
  }

  /// İlan oluştur (draft) — yeni alanlar opsiyonel
  static Future<dynamic> postCreate({
    required int companyId,
    required String title,
    String? description,
    int? positionId,
    String? area,
    String? location,

    // 🆕 ek alanlar:
    String?
        employmentType, // full_time|part_time|contract|seasonal|internship|temporary|other
    int? ageMin,
    int? ageMax,
    num? salaryMin,
    num? salaryMax,
    String? salaryCurrency, // ISO-4217: TRY, USD, EUR...
    String? salaryRateUnit, // hour|day|month|year|contract|trip
    int? contractDurationMonths,
    int? probationMonths,
    int? rotationOnMonths,
    int? rotationOffMonths,
    String? rotationBonusType, // none|fixed|one_salary|percent
    num? rotationBonusValue,
    int? cityId,
    dynamic benefitsJson,
    dynamic obligationsJson,
    List<dynamic>? requirementsJson,
  }) {
    final params = <String, dynamic>{
      'company_id': companyId,
      'title': title,
      if (description != null) 'description': description,
      if (positionId != null) 'position_id': positionId,
      if (area != null) 'area': area,
      if (location != null) 'location': location,

      // 🆕
      if (employmentType != null) 'employment_type': employmentType,
      if (ageMin != null) 'age_min': ageMin,
      if (ageMax != null) 'age_max': ageMax,
      if (salaryMin != null) 'salary_min': salaryMin,
      if (salaryMax != null) 'salary_max': salaryMax,
      if (salaryCurrency != null) 'salary_currency': salaryCurrency,
      if (salaryRateUnit != null) 'salary_rate_unit': salaryRateUnit,
      if (contractDurationMonths != null)
        'contract_duration_months': contractDurationMonths,
      if (probationMonths != null) 'probation_months': probationMonths,
      if (rotationOnMonths != null) 'rotation_on_months': rotationOnMonths,
      if (rotationOffMonths != null) 'rotation_off_months': rotationOffMonths,
      if (rotationBonusType != null) 'rotation_bonus_type': rotationBonusType,
      if (rotationBonusValue != null)
        'rotation_bonus_value': rotationBonusValue,
      if (cityId != null) 'city_id': cityId,
      if (benefitsJson != null) 'benefits_json': benefitsJson,
      if (obligationsJson != null) 'obligations_json': obligationsJson,

      if (requirementsJson != null) 'requirements_json': requirementsJson,
    };
    return _call('post_create', params);
  }

  /// İlan güncelle — sadece verilen alanlar güncellenir
  static Future<dynamic> postUpdate({
    required int id,
    String? title,
    String? description,
    int? positionId,
    String? area,
    String? location,

    // 🆕 ek alanlar:
    String? employmentType,
    int? ageMin,
    int? ageMax,
    num? salaryMin,
    num? salaryMax,
    String? salaryCurrency,
    String? salaryRateUnit,
    int? contractDurationMonths,
    int? probationMonths,
    int? rotationOnMonths,
    int? rotationOffMonths,
    String? rotationBonusType,
    num? rotationBonusValue,
    int? cityId,
    dynamic benefitsJson,
    dynamic obligationsJson,
    List<dynamic>? requirementsJson,
  }) {
    final params = <String, dynamic>{
      'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (positionId != null) 'position_id': positionId,
      if (area != null) 'area': area,
      if (location != null) 'location': location,

      // 🆕
      if (employmentType != null) 'employment_type': employmentType,
      if (ageMin != null) 'age_min': ageMin,
      if (ageMax != null) 'age_max': ageMax,
      if (salaryMin != null) 'salary_min': salaryMin,
      if (salaryMax != null) 'salary_max': salaryMax,
      if (salaryCurrency != null) 'salary_currency': salaryCurrency,
      if (salaryRateUnit != null) 'salary_rate_unit': salaryRateUnit,
      if (contractDurationMonths != null)
        'contract_duration_months': contractDurationMonths,
      if (probationMonths != null) 'probation_months': probationMonths,
      if (rotationOnMonths != null) 'rotation_on_months': rotationOnMonths,
      if (rotationOffMonths != null) 'rotation_off_months': rotationOffMonths,
      if (rotationBonusType != null) 'rotation_bonus_type': rotationBonusType,
      if (rotationBonusValue != null)
        'rotation_bonus_value': rotationBonusValue,
      if (cityId != null) 'city_id': cityId,
      if (benefitsJson != null) 'benefits_json': benefitsJson,
      if (obligationsJson != null) 'obligations_json': obligationsJson,

      if (requirementsJson != null) 'requirements_json': requirementsJson,
    };
    return _call('post_update', params);
  }

  static String unitShort(String? unit) {
    switch (unit) {
      case 'hour':
        return 'hr';
      case 'day':
        return 'day';
      case 'month':
        return 'mo';
      case 'year':
        return 'yr';
      case 'contract':
        return 'contract';
      case 'trip':
        return 'trip';
    }
    return '';
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

  /// İlan listele (izin yoksa yalnız 'published' gelir)
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

  static Future<dynamic> postArchive({required int id}) {
    return _call('post_archive', {'id': id});
  }

  static Future<dynamic> postStats({required int companyId}) {
    return _call('post_stats', {'company_id': companyId});
  }

  static Future<dynamic> postOverview({required int id, int recent = 5}) {
    return _call('post_overview', {'id': id, 'recent': recent});
  }

  // ------------------------
  // APPLICATIONS (BAŞVURU)
  // ------------------------

  /// (Aday) Başvuru gönderir.
  /// Not: actor kendi adına başvurur; userId gerekmez.
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

  /// (Admin/HR) Bir aday adına başvuru oluşturur. userId opsiyonel;
  /// boş ise actor (admin) kendi adına bırakır (backend politikasına göre).
  static Future<dynamic> appCreate({
    required int companyId,
    required int jobPostId,
    int? userId,
    String? coverLetter,
    dynamic cvSnapshot,
    dynamic attachments,
  }) {
    return _call('app_create', {
      'company_id': companyId,
      'job_post_id': jobPostId,
      if (userId != null) 'user_id': userId,
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
    String?
        status, // submitted|under_review|shortlisted|interview|offered|hired|rejected|withdrawn
    int page = 1,
    int perPage = 25,
    int? jobPostId,
  }) {
    return _call('app_list_for_company', {
      'company_id': companyId,
      if (status != null) 'status': status,
      if (jobPostId != null) 'job_post_id': jobPostId,
      'page': page,
      'per_page': perPage,
    });
  }

  /// Kullanıcının başvuruları (userId verilmezse actor’un kendi)
  static Future<dynamic> appListForUser({
    int? userId,
    int? companyIdIfViewingOthers,
  }) {
    return _call('app_list_for_user', {
      if (userId != null) 'user_id': userId,
      if (companyIdIfViewingOthers != null)
        'company_id': companyIdIfViewingOthers,
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

  static Future<dynamic> appNotes({required int applicationId}) {
    return _call('app_notes', {'application_id': applicationId});
  }

  static Future<dynamic> appStats({required int companyId, int? jobPostId}) {
    return _call('app_stats', {
      'company_id': companyId,
      if (jobPostId != null) 'job_post_id': jobPostId,
    });
  }

  // RecruitmentServiceV1 içine EKLE
  /// Public "Open Jobs" — updated_at DESC, default 10
  static Future<dynamic> postPublicOpenList({int limit = 10, String? q}) {
    return _call('post_public_open_list', {
      'limit': limit,
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
    });
  }

  /// Aynı çağrının normalize edilmiş hali (UI için pratik)
  static Future<Map<String, dynamic>> postPublicOpenListNormalized(
      {int limit = 10, String? q}) async {
    final res = await postPublicOpenList(limit: limit, q: q);
    return _normalizeList(res);
  }

  // RecruitmentServiceV1 içine ekle:
  static Future<dynamic> postPublicDetail({required int id}) {
    return _call('post_public_detail', {'id': id});
  }
}
