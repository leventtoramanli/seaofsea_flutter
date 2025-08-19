import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:seaofsea/services/v1/company_service.dart';

class CompanyDetailController extends ChangeNotifier {
  final CompanyService service;
  CompanyDetailController({required this.service});

  // UI state
  bool loading = true;
  String? error;

  // data
  String role = 'none'; // admin|editor|viewer|follower|none
  Map<String, dynamic> company = {};
  Map<String, List<Map<String, String>>> contactInfo = {};
  List<Map<String, dynamic>> allTypes = [];
  List<int> selectedTypeIds = [];
  int currentPageIndex = 0;

  bool get isAdmin => role == 'admin';
  bool get isEditor => role == 'editor';
  bool get isViewer => role == 'viewer';
  bool get isFollower => role == 'follower';
  bool get isEmployee => isAdmin || isEditor || isViewer;

  Future<void> init(int companyId, {List<int>? initialTypeIds}) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      role = await service.getMyRole(companyId);

      final detail = await service.getCompanyDetail(companyId);
      if (detail != null) {
        company = detail;

        // contact_info parse
        final ciRaw = detail['contact_info'];
        contactInfo = _safeParseContactInfo(ciRaw);

        // type ids parse
        final t = detail['type_ids'] ??
            detail['company_type_ids'] ??
            initialTypeIds ??
            [];
        selectedTypeIds = _parseIdList(t);
      }

      allTypes = await service.getCompanyTypes(
          filterIds: selectedTypeIds, perPage: 500);
      loading = false;
      notifyListeners();
    } catch (e) {
      error = 'Load error: $e';
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll(int companyId) async {
    await init(companyId, initialTypeIds: selectedTypeIds);
  }

  void setPage(int index) {
    currentPageIndex = index;
    notifyListeners();
  }

  Future<bool> saveTypes(int companyId, List<int> ids) async {
    final ok =
        await service.updateCompanyTypes(companyId: companyId, typeIds: ids);
    if (ok) {
      selectedTypeIds = ids;
      // filtre bazlı dar listeyi yeniden getir
      allTypes = await service.getCompanyTypes(
          filterIds: selectedTypeIds, perPage: 500);
      notifyListeners();
    }
    return ok;
  }

  Future<bool> saveContactInfo(
      int companyId, Map<String, List<Map<String, String>>> info) async {
    final ok = await service.updateContactInfo(
        companyId: companyId, contactInfo: info);
    if (ok) {
      contactInfo = info;
      notifyListeners();
    }
    return ok;
  }

  // --- helpers ---
  List<int> _parseIdList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e > 0)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final dec = _tryJsonDecode(raw);
        if (dec is List) {
          return dec
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((e) => e > 0)
              .toList();
        }
      } catch (_) {}
    }
    return <int>[];
  }

  Map<String, List<Map<String, String>>> _safeParseContactInfo(dynamic raw) {
    if (raw == null) return {};
    try {
      final obj = (raw is String) ? _tryJsonDecode(raw) : raw;
      if (obj is! Map) return {};
      final Map<String, List<Map<String, String>>> parsed = {};
      for (final entry in obj.entries) {
        final key = entry.key.toString();
        final list = entry.value;
        if (list is List) {
          parsed[key] = list.map<Map<String, String>>((it) {
            return {
              'label': it['label']?.toString() ?? '',
              'value': it['value']?.toString() ?? '',
            };
          }).toList();
        }
      }
      return parsed;
    } catch (_) {
      return {};
    }
  }

  dynamic _tryJsonDecode(String s) {
    return s.isEmpty ? null : (const JsonDecoder()).convert(s);
  }
}
