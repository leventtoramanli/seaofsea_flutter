import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:seaofsea/views/companies/dashboard/models/announcement.dart';
import 'package:seaofsea/views/companies/dashboard/models/dashboard_models.dart';
import 'package:seaofsea/views/companies/dashboard/services/company_dashboard_service.dart';

/// UI'ın dinleyeceği controller; servis üzerinden veriyi çeker ve state üretir.
class DashboardController extends ChangeNotifier {
  final CompanyDashboardService service;
  final int companyId;

  DashboardState _state = DashboardState.initial();
  DashboardState get state => _state;

  /// Eşzamanlı çağrılarda "son gelen kazanır" problemi için sırayla kimlik.
  int _loadSeq = 0;

  DashboardController({
    required this.service,
    required this.companyId,
  });

  // ---- Türev getter
  int get totalPendingLike {
    final m = _state.applicationCounts;
    if (m == null) return 0;
    return (m[ApplicationStatus.pending] ?? 0) +
        (m[ApplicationStatus.preApproved] ?? 0) +
        (m[ApplicationStatus.waitingManagerApproval] ?? 0);
  }

  bool get isLoading => _state.loading;
  bool get hasError => _state.error != null && _state.error!.isNotEmpty;

  // ---- State yardımcıları
  void _setState(DashboardState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setLoading() => _setState(_state.copyWith(loading: true, error: null));
  void _setError(String message) =>
      _setState(_state.copyWith(loading: false, error: message));
  void _setData({
    required String role,
    required Map<String, dynamic>? detail,
    required Map<ApplicationStatus, int>? applicationCounts,
    required int membersApproved,
    required int openJobs,
    required int followers,
    required List<Map<String, dynamic>> topPeople,
    required Map<String, List<Map<String, String>>> contactSummary,
  }) {
    _setState(_state.copyWith(
      loading: false,
      error: null,
      role: role,
      detail: detail,
      applicationCounts: applicationCounts,
      membersApproved: membersApproved,
      openJobs: openJobs,
      followers: followers,
      topPeople: topPeople,
      contactSummary: contactSummary,
    ));
  }

  // ---- Public API
  bool _followBusy = false;
  bool get followBusy => _followBusy;
  bool get isFollowing => _state.role == 'follower';
  bool get _isEmployee =>
      _state.role == 'admin' ||
      _state.role == 'editor' ||
      _state.role == 'viewer';

  List<Announcement> _announcements = [];
  int _annTotal = 0;
  bool _annLoading = false;

  List<Announcement> get announcements => _announcements;
  int get announcementsTotal => _annTotal;
  bool get announcementsLoading => _annLoading;

  Future<void> loadAnnouncements({BuildContext? context}) async {
    _annLoading = true;
    notifyListeners();
    try {
      // çalışanlar gizliyi de görür
      final includeHidden = _isEmployee;
      final r = await service.fetchAnnouncements(
        companyId,
        page: 1,
        perPage: 10,
        includeHidden: includeHidden,
        context: context,
      );
      _announcements = r.items;
      _annTotal = r.total;
    } catch (_) {
      _announcements = [];
      _annTotal = 0;
    } finally {
      _annLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleFollow({BuildContext? context}) async {
    if (_followBusy) return false;
    if (_isEmployee) return false; // çalışanlara follow göstermiyoruz

    final wasFollowing = isFollowing;
    final wantFollow = !wasFollowing;
    final prevCount = _state.followers;

    // optimistic: role + sayacı anında yansıt
    _followBusy = true;
    notifyListeners();
    _setState(_state.copyWith(
      role: wantFollow ? 'follower' : 'none',
      followers: (prevCount + (wantFollow ? 1 : -1)).clamp(0, 1 << 30),
    ));

    try {
      if (wantFollow) {
        await service.follow(companyId, context: context);
      } else {
        await service.unfollow(companyId, context: context);
      }

      // gerçek durum: follow_status ile kesinleştir
      final s = await service.followStatus(companyId, context: context);
      _setState(_state.copyWith(
        role: s.isFollower ? 'follower' : 'none',
        followers: s.count,
      ));
      return true;
    } catch (_) {
      // geri al
      _setState(_state.copyWith(
        role: wasFollowing ? 'follower' : 'none',
        followers: prevCount,
      ));
      return false;
    } finally {
      _followBusy = false;
      notifyListeners();
    }
  }

  Future<void> loadAll({BuildContext? context}) async {
    final seq = ++_loadSeq;
    _setLoading();

    try {
      // openJobs'u beklet → önce role'u öğrenelim
      final results = await Future.wait([
        service.fetchRole(companyId, context: context),
        service.fetchDetail(companyId, context: context),
        service.fetchApplicationBuckets(companyId, context: context),
        service.fetchMembersTotal(companyId,
            status: 'approved', context: context),
        service.fetchTopPeople(companyId, context: context),
      ]);

      if (seq != _loadSeq) return;

      final role = results[0] as String? ?? 'none';
      final detail = results[1] as Map<String, dynamic>?;
      final buckets = results[2] as Map<ApplicationStatus, int>;
      final membersApproved = results[3] as int;
      final topPeople = results[4] as List<Map<String, dynamic>>;

      final followers = int.tryParse('${detail?['follower_count'] ?? 0}') ?? 0;
      final contact = service.extractContact(detail?['contact_info']);

      // 🔑 openJobs’u role’a göre çek
      int openJobs = 0;
      try {
        final isEmployee =
            role == 'admin' || role == 'editor' || role == 'viewer';
        openJobs = isEmployee
            ? await service.fetchOpenJobs(companyId, context: context)
            : await service.fetchPublishedCount(companyId, context: context);
      } catch (_) {
        openJobs = 0;
      }

      if (seq != _loadSeq) return;

      _setData(
        role: role,
        detail: detail,
        applicationCounts: buckets,
        membersApproved: membersApproved,
        openJobs: openJobs,
        followers: followers,
        topPeople: topPeople,
        contactSummary: contact,
      );

      await loadAnnouncements(context: context);
    } catch (_) {
      if (seq != _loadSeq) return;
      _setError('Failed to load dashboard');
    }
  }

  Future<void> refreshRole({BuildContext? context}) async {
    try {
      final role =
          await service.fetchRole(companyId, context: context) ?? 'none';
      _setState(_state.copyWith(role: role, error: null));
    } catch (_) {}
  }

  Future<void> refreshOpenJobsPublic({BuildContext? context}) async {
    try {
      final role = _state.role;
      final isEmployee =
          role == 'admin' || role == 'editor' || role == 'viewer';
      final n = isEmployee
          ? await service.fetchOpenJobs(companyId, context: context)
          : await service.fetchPublishedCount(companyId, context: context);
      _setState(_state.copyWith(openJobs: n, error: null));
    } catch (_) {}
  }

  Future<void> refreshOpenJobs({BuildContext? context}) async {
    try {
      final open = await service.fetchOpenJobs(companyId, context: context);
      _setState(_state.copyWith(openJobs: open, error: null));
    } catch (_) {}
  }

  Future<void> refreshApplications({BuildContext? context}) async {
    try {
      final buckets =
          await service.fetchApplicationBuckets(companyId, context: context);
      _setState(_state.copyWith(applicationCounts: buckets, error: null));
    } catch (_) {}
  }

  Future<void> refreshJobs({BuildContext? context}) async {
    try {
      final open = await service.fetchOpenJobs(companyId, context: context);
      _setState(_state.copyWith(openJobs: open, error: null));
    } catch (_) {}
  }

  Future<void> refreshPeople({BuildContext? context}) async {
    try {
      final people = await service.fetchTopPeople(companyId, context: context);
      _setState(_state.copyWith(topPeople: people, error: null));
    } catch (_) {}
  }
}
