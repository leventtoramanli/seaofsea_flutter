import 'package:flutter/foundation.dart';

/// Başvuru durumları
enum ApplicationStatus {
  pending,
  preApproved,
  approved,
  rejected,
  waitingManagerApproval,
}

/// Dashboard ekranının tekil state modeli (immutable)
@immutable
class DashboardState {
  final bool loading;
  final String? error;

  /// backend'in döndürdüğü rol bilgisi (bilgi amaçlı)
  final String role; // admin|editor|viewer|follower|none

  /// Şirket detayı (company.detail payload)
  final Map<String, dynamic>? detail;

  /// Başvuru bucket sayıları
  final Map<ApplicationStatus, int>? applicationCounts;

  /// Onaylı üye sayısı
  final int membersApproved;

  /// Açık ilan sayısı
  final int openJobs;

  /// Takipçi sayısı
  final int followers;

  /// Sağ kolon "People" listesi (ilk 3)
  final List<Map<String, dynamic>> topPeople;

  /// İletişim özet (phones/emails/websites/addresses)
  final Map<String, List<Map<String, String>>> contactSummary;

  const DashboardState({
    required this.loading,
    required this.error,
    required this.role,
    required this.detail,
    required this.applicationCounts,
    required this.membersApproved,
    required this.openJobs,
    required this.followers,
    required this.topPeople,
    required this.contactSummary,
  });

  factory DashboardState.initial() => const DashboardState(
        loading: false,
        error: null,
        role: 'none',
        detail: null,
        applicationCounts: null,
        membersApproved: 0,
        openJobs: 0,
        followers: 0,
        topPeople: <Map<String, dynamic>>[],
        contactSummary: <String, List<Map<String, String>>>{},
      );

  DashboardState copyWith({
    bool? loading,
    String? error,
    String? role,
    Map<String, dynamic>? detail,
    Map<ApplicationStatus, int>? applicationCounts,
    int? membersApproved,
    int? openJobs,
    int? followers,
    List<Map<String, dynamic>>? topPeople,
    Map<String, List<Map<String, String>>>? contactSummary,
  }) {
    return DashboardState(
      loading: loading ?? this.loading,
      error: error,
      role: role ?? this.role,
      detail: detail ?? this.detail,
      applicationCounts: applicationCounts ?? this.applicationCounts,
      membersApproved: membersApproved ?? this.membersApproved,
      openJobs: openJobs ?? this.openJobs,
      followers: followers ?? this.followers,
      topPeople: topPeople ?? this.topPeople,
      contactSummary: contactSummary ?? this.contactSummary,
    );
  }
}
