import 'package:flutter/foundation.dart';
import 'package:seaofsea/services/v1/recruitment_service.dart';

/// Adayın kendi başvurularını yöneten provider.
/// Model katmanı yok; Map<String, dynamic> ile çalışır.
class MyApplicationsProvider extends ChangeNotifier {
  // --- State ---
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> _items = const [];
  int _page = 1;
  int _perPage = 25; // 25|50|100
  int _pages = 0;
  int _total = 0;

  // Filtreler
  List<String> _statuses = [];
  String _q = '';
  int? _companyId;
  int? _jobPostId;

  // --- Getters (UI) ---
  bool get loading => _loading;
  String? get error => _error;

  List<Map<String, dynamic>> get items => _items;
  int get page => _page;
  int get perPage => _perPage;
  int get pages => _pages;
  int get total => _total;

  List<String> get statuses => List.unmodifiable(_statuses);
  String get q => _q;
  int? get companyId => _companyId;
  int? get jobPostId => _jobPostId;

  bool get canLoadMore => _page < _pages;

  // --- Internal helpers ---
  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    _error = msg;
    notifyListeners();
  }

  void _applyListPayload(Map<String, dynamic> data) {
    final items = (data['items'] as List?) ?? const [];
    _items = items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    _total = (data['total'] is int)
        ? data['total'] as int
        : int.tryParse('${data['total']}') ?? _items.length;

    _page = (data['page'] is int)
        ? data['page'] as int
        : int.tryParse('${data['page']}') ?? _page;

    _perPage = (data['per_page'] is int)
        ? data['per_page'] as int
        : int.tryParse('${data['per_page']}') ?? _perPage;

    _pages = (data['pages'] is int)
        ? data['pages'] as int
        : int.tryParse('${data['pages']}') ??
            ((_perPage > 0) ? ((_total + _perPage - 1) ~/ _perPage) : 0);

    notifyListeners();
  }

  // --- Public API ---

  /// İlk yükleme ya da filtre değişiminden sonra çağır.
  Future<void> fetch({int? page}) async {
    if (_loading) return;
    _setError(null);
    _setLoading(true);
    try {
      final res = await RecruitmentServiceV1.appListMineNormalized(
        page: page ?? _page,
        perPage: _perPage,
        statuses: _statuses.isEmpty ? null : _statuses,
        q: _q.isEmpty ? null : _q,
        companyId: _companyId,
        jobPostId: _jobPostId,
      );
      _applyListPayload(res);
    } catch (e) {
      _setError('$e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    _page = 1;
    await fetch(page: 1);
  }

  void setPerPage(int v) {
    if (v != 25 && v != 50 && v != 100) return;
    if (_perPage == v) return;
    _perPage = v;
    _page = 1;
    notifyListeners();
  }

  void search(String query) {
    final q = query.trim();
    if (_q == q) return;
    _q = q;
    _page = 1;
    notifyListeners();
  }

  void setStatuses(List<String> newStatuses) {
    final s = newStatuses
        .where((e) => e.trim().isNotEmpty)
        .map((e) => e.trim())
        .toList();
    _statuses = s;
    _page = 1;
    notifyListeners();
  }

  void setCompany(int? companyId) {
    _companyId = companyId;
    _page = 1;
    notifyListeners();
  }

  void setJobPost(int? jobPostId) {
    _jobPostId = jobPostId;
    _page = 1;
    notifyListeners();
  }

  Future<void> goTo(int page) async {
    if (page < 1) page = 1;
    if (_pages > 0 && page > _pages) page = _pages;
    if (_page == page) return;
    _page = page;
    notifyListeners();
    await fetch();
  }

  /// Detay çeker. UI direkt dönen Map'i kullanabilir.
  Future<Map<String, dynamic>?> getDetail(int applicationId) async {
    try {
      final res = await RecruitmentServiceV1.appDetailMine(
          applicationId: applicationId);
      // Beklenen: { application:{...}, status_history:[...], notes:[] }
      if (res is Map && res.containsKey('data'))
        return Map<String, dynamic>.from(res['data']);
      if (res is Map) return Map<String, dynamic>.from(res);
      return null;
    } catch (e) {
      _setError('$e');
      return null;
    }
  }

  /// Optimistic withdraw: listede ilgili öğeyi 'withdrawn' yapar; hata olursa geri alır.
  Future<bool> withdrawOne(int applicationId) async {
    // Optimistic
    final idx = _items.indexWhere((e) => (e['id'] == applicationId));
    Map<String, dynamic>? backup;
    if (idx >= 0) {
      backup = Map<String, dynamic>.from(_items[idx]);
      _items[idx] = {
        ..._items[idx],
        'status': 'withdrawn',
      };
      notifyListeners();
    }

    try {
      await RecruitmentServiceV1.appWithdrawMine(applicationId: applicationId);
      return true;
    } catch (e) {
      // Rollback
      if (idx >= 0 && backup != null) {
        _items[idx] = backup;
        notifyListeners();
      }
      _setError('$e');
      return false;
    }
  }
}
