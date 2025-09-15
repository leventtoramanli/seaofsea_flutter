import 'package:flutter/foundation.dart';

/// Başvuru durumları
enum ApplicationStatus {
  pending,
  preApproved,
  approved,
  rejected,
  waitingManagerApproval,
}

@immutable
class DashboardState {
  final bool loading;
  final String? error;
  final String role; // admin|editor|viewer|follower|none
  final Map<String, dynamic>? detail;
  final Map<ApplicationStatus, int>? applicationCounts;
  final int membersApproved;
  final int openJobs;
  final int followers;
  final List<Map<String, dynamic>> topPeople;
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

  // ---- Sentinel: error alanını “dokunma” ile “bilerek null yap” ayrımı
  static const Object _noUpdate = Object();

  DashboardState copyWith({
    bool? loading,
    Object? error = _noUpdate, // String? bekliyoruz ama sentinel için Object?
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
      error: identical(error, _noUpdate) ? this.error : error as String?,
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
