import 'dart:convert';
import 'package:seaofsea/services/v1/v1_api_manager.dart';

class JobService {
  final V1ApiManager api;
  JobService(this.api);

  Future<int> create({
    required int companyId,
    required String title,
    String area = 'crew', // crew | office
    String visibility = 'public', // public | followers | private
    int? positionId,
    String? description,
    dynamic requirements, // String veya List
    String? location,
    bool notifyFollowers = false,
  }) async {
    final res = await api.call(
      module: 'job',
      action: 'create',
      params: {
        'company_id': companyId,
        'title': title,
        'area': area,
        'visibility': visibility,
        if (positionId != null) 'position_id': positionId,
        if (description != null) 'description': description,
        if (requirements != null) 'requirements': requirements,
        if (location != null) 'location': location,
        'notify_followers': notifyFollowers ? 1 : 0,
      },
    );
    final data = (res['data'] ?? {}) as Map;
    if (data['created'] == true && data['id'] != null) {
      return int.parse('${data['id']}');
    }
    throw Exception('Create job failed: ${data['error'] ?? res['message']}');
  }

  Future<void> publish(int jobId) async =>
      api.call(module: 'job', action: 'publish', params: {'id': jobId});

  Future<void> close(int jobId) async =>
      api.call(module: 'job', action: 'close', params: {'id': jobId});

  Future<Map<String, dynamic>> list({
    int? companyId,
    String status = 'open',
    String? visibility,
    int page = 1,
    int perPage = 25,
  }) async {
    final res = await api.call(
      module: 'job',
      action: 'list',
      params: {
        if (companyId != null) 'company_id': companyId,
        if (status.isNotEmpty) 'status': status,
        if (visibility != null) 'visibility': visibility,
        'page': page,
        'perPage': perPage,
      },
    );
    return Map<String, dynamic>.from(res['data'] ?? {});
  }

  Future<Map<String, dynamic>> detail(int id) async {
    final res =
        await api.call(module: 'job', action: 'detail', params: {'id': id});
    final data = Map<String, dynamic>.from(res['data'] ?? {});
    if (data['found'] == false) {
      throw Exception(data['error'] ?? 'not_found');
    }
    return data;
  }

  Future<int> apply({
    required int jobId,
    String? message,
    List<({String name, List<int> bytes})>? attachments,
  }) async {
    final params = <String, dynamic>{'job_id': jobId};
    if (message != null && message.isNotEmpty) params['message'] = message;

    if (attachments != null && attachments.isNotEmpty) {
      params['attachments'] = attachments
          .map((a) => {
                'file_name': a.name,
                'file_data_base64': base64Encode(a.bytes),
              })
          .toList();
    }

    final res = await api.call(module: 'job', action: 'apply', params: params);
    final data = (res['data'] ?? {}) as Map;
    if (data['success'] == true && data['id'] != null) {
      return int.parse('${data['id']}');
    }
    throw Exception('Apply failed: ${data['error'] ?? res['message']}');
  }

  Future<Map<String, dynamic>> myApplications({
    String? status,
    int page = 1,
    int perPage = 25,
  }) async {
    final res = await api.call(
      module: 'job',
      action: 'my_applications',
      params: {
        if (status != null) 'status': status,
        'page': page,
        'perPage': perPage,
      },
    );
    return Map<String, dynamic>.from(res['data'] ?? {});
  }

  Future<Map<String, dynamic>> applications({
    int? companyId,
    int? jobId,
    String? status,
    int page = 1,
    int perPage = 25,
  }) async {
    final res = await api.call(
      module: 'job',
      action: 'applications',
      params: {
        if (companyId != null) 'company_id': companyId,
        if (jobId != null) 'job_id': jobId,
        if (status != null) 'status': status,
        'page': page,
        'perPage': perPage,
      },
    );
    return Map<String, dynamic>.from(res['data'] ?? {});
  }

  Future<void> updateApplicationStatus({
    required int applicationId,
    required String
        status, // submitted|under_review|shortlisted|rejected|withdrawn|hired
  }) async {
    await api.call(
      module: 'job',
      action: 'application_update_status',
      params: {'application_id': applicationId, 'status': status},
    );
  }

  Future<void> withdrawApplication(int applicationId) async {
    await api.call(
      module: 'job',
      action: 'application_withdraw',
      params: {'application_id': applicationId},
    );
  }

  Future<Map<String, dynamic>> search({
    String? q,
    int? companyId,
    int? positionId,
    String? area, // crew|office
    String status = 'open',
    String? visibility, // public|followers|private
    bool followingOnly = false,
    int page = 1,
    int perPage = 25,
  }) async {
    final res = await api.call(
      module: 'job',
      action: 'search',
      params: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (companyId != null) 'company_id': companyId,
        if (positionId != null) 'position_id': positionId,
        if (area != null) 'area': area,
        if (status.isNotEmpty) 'status': status,
        if (visibility != null) 'visibility': visibility,
        'following_only': followingOnly ? 1 : 0,
        'page': page,
        'perPage': perPage,
      },
    );
    return Map<String, dynamic>.from(res['data'] ?? {});
  }

  Future<void> updateJob(int id, Map<String, dynamic> patch) async {
    await api
        .call(module: 'job', action: 'update', params: {'id': id, ...patch});
  }

  Future<void> archive(int id) async =>
      api.call(module: 'job', action: 'archive', params: {'id': id});
  Future<void> reopen(int id) async =>
      api.call(module: 'job', action: 'reopen', params: {'id': id});
  Future<void> deleteSoft(int id) async =>
      api.call(module: 'job', action: 'delete', params: {'id': id});
  Future<void> undelete(int id) async =>
      api.call(module: 'job', action: 'undelete', params: {'id': id});
}
