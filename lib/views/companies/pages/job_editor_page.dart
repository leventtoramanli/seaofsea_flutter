import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:seaofsea/services/custom_text_editor.dart';
import 'package:seaofsea/services/v1/recruitment_service.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/utils/certificate_picker.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class JobEditorPage extends StatefulWidget {
  final int companyId;
  final int? jobId; // null => create, not null => edit

  const JobEditorPage({super.key, required this.companyId, this.jobId});

  @override
  State<JobEditorPage> createState() => _JobEditorPageState();
}

class _JobEditorPageState extends State<JobEditorPage> {
  final _formKey = GlobalKey<FormState>();

  // Base fields
  final _title = TextEditingController();
  final _location = TextEditingController();

  // Global position search
  final _searchCtl = TextEditingController();
  Timer? _searchDebounce;
  bool _searching = false;
  List<Map<String, dynamic>> _searchResults = <Map<String, dynamic>>[];

  bool _busy = false;
  String? _status; // draft|published|closed|archived
  String? _createdAt;
  String? _updatedAt;

  // API
  late V1ApiManager _v1;

  // Area / Department / Position
  bool _loadingAreas = false;
  Map<String, List<String>> _areaMap = {}; // area -> [departments]
  List<String> _areas = <String>[];

  String? _area; // crew|office|port|shipyard|supplier|agency
  bool _loadingDeps = false;
  List<String> _departments = <String>[];
  String? _department;

  bool _loadingPositions = false;
  List<Map<String, dynamic>> _positions =
      <Map<String, dynamic>>[]; // [{id,name,...}]
  int? _positionId;
  String? _positionDescPreview;
  // Quill (description)
  GlobalKey<QuillTextEditorState> _descKey = GlobalKey<QuillTextEditorState>();
  String? _initialDescDeltaJson;
  // --- Offer/Terms state ---
  String?
      _employmentType; // full_time|part_time|contract|seasonal|internship|temporary|other

  final _ageMinCtrl = TextEditingController();
  final _ageMaxCtrl = TextEditingController();

  final _salaryMinCtrl = TextEditingController();
  final _salaryMaxCtrl = TextEditingController();
  final _salaryCurrencyCtrl = TextEditingController(); // TRY/USD/EUR...
  String? _salaryRateUnit; // hour|day|month|year|contract|trip

  final _contractMonthsCtrl = TextEditingController();
  final _probationMonthsCtrl = TextEditingController();

  final _rotOnCtrl = TextEditingController();
  final _rotOffCtrl = TextEditingController();
  String? _bonusType; // none|fixed|one_salary|percent
  final _bonusValueCtrl = TextEditingController();

// City seçimi için numeric id (CityHandler→list ile geliyor)
  int? _cityId;

// Certificates (requirements_json)
  GlobalKey<CertificatePickerState> _certKey =
      GlobalKey<CertificatePickerState>();
  List<int> _initialReqIds = <int>[];

  // Location search (CityHandler)
  bool _locSearching = false;
  Timer? _locDebounce;
  List<Map<String, dynamic>> _locResults = <Map<String, dynamic>>[];
  Map<String, dynamic>? _selectedCity; // seçilen kaydın ham verisi
  final List<Map<String, dynamic>> _recentCities = []; // son 5 seçim

  // ---- Editor'ları remount etmek için (description & certificates) ----
  int _hydrateSeq = 0; // değiştikçe KeyedSubtree remount olur

  final _scrollCtrl = ScrollController();

// FormField key'leri
  final _titleKey = GlobalKey<FormFieldState<String>>();
  final _areaKey = GlobalKey<FormFieldState<String>>();
  final _deptKey = GlobalKey<FormFieldState<String>>();
  final _positionKey = GlobalKey<FormFieldState<int>>();

  @override
  void initState() {
    super.initState();
    _v1 = context.read<V1ApiManager>();
    _loadAreas();
    if (widget.jobId != null) {
      _load();
    }
    _searchCtl.addListener(_onGlobalSearchChanged);
    _location.addListener(_onLocationInputChanged);
  }

  @override
  void dispose() {
    _title.dispose();
    _location.removeListener(_onLocationInputChanged);
    _location.dispose();
    _searchCtl.removeListener(_onGlobalSearchChanged);
    _searchCtl.dispose();
    _searchDebounce?.cancel();
    _locDebounce?.cancel();
    _ageMinCtrl.dispose();
    _ageMaxCtrl.dispose();
    _salaryMinCtrl.dispose();
    _salaryMaxCtrl.dispose();
    _salaryCurrencyCtrl.dispose();
    _contractMonthsCtrl.dispose();
    _probationMonthsCtrl.dispose();
    _rotOnCtrl.dispose();
    _rotOffCtrl.dispose();
    _bonusValueCtrl.dispose();

    super.dispose();
  }

  // --------------------------------
  // Helpers
  // --------------------------------
  String _asDeltaJson(String? src) {
    final raw = (src ?? '').trim();
    if (raw.isEmpty) {
      return jsonEncode([
        {"insert": "\n"}
      ]);
    }
    final lower = raw.toLowerCase();
    if (lower == 'null' || lower == 'undefined' || lower == '[]') {
      return jsonEncode([
        {"insert": "\n"}
      ]);
    }

    // JSON ise ele al
    try {
      final any = jsonDecode(raw);
      if (any is List) {
        // Zaten Quill delta
        return raw;
      }
      if (any == null) {
        return jsonEncode([
          {"insert": "\n"}
        ]);
      }
      if (any is String) {
        // "metin" şeklinde gelmişse delta'ya sar
        final txt = any.trim();
        if (txt.isEmpty) {
          return jsonEncode([
            {"insert": "\n"}
          ]);
        }
        return jsonEncode([
          {"insert": "$txt\n"}
        ]);
      }
    } catch (_) {
      // JSON değilse düz metin olarak delta'ya sar
    }

    // Düz metinse delta'ya sar
    return jsonEncode([
      {"insert": "$raw\n"}
    ]);
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  String? _safeStr(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return (s.isEmpty || s == 'null') ? null : s;
  }

  // --- Helpers: normalize & safe map ---

  String _normalizeStatus(String? raw) {
    final s = (raw ?? '').toLowerCase();
    if (s == 'open') return 'published';
    if (s.isEmpty) return 'draft';
    return s;
  }

  Map<String, dynamic> _toStrKeyedMap(Map? any) {
    if (any == null) return <String, dynamic>{};
    final out = <String, dynamic>{};
    if (any is Map) {
      any.forEach((k, v) => out[k?.toString() ?? ''] = v);
    }
    return out;
  }

  Map<String, dynamic> _normalizeJob(Map<String, dynamic> m) {
    final out = Map<String, dynamic>.from(m);
    out['status'] = _normalizeStatus(m['status']); // open -> published
    out['position_area'] = _safeStr(m['position_area']) ?? _safeStr(m['area']);
    return out;
  }

  Map<String, dynamic>? _unwrapData(dynamic res) {
    if (res is! Map) return null;
    final d = res['data'];
    if (d is Map && d['data'] is Map) {
      return Map<String, dynamic>.from(d['data']); // çift zarf
    }
    if (d is Map) return Map<String, dynamic>.from(d); // tek zarf
    return null;
  }

  List<Map<String, dynamic>> _extractItems(dynamic res) {
    final data = _unwrapData(res);
    if (data == null) return const <Map<String, dynamic>>[];
    final raw = data['items'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // --------------------------------
  // Loaders
  // --------------------------------
  Future<void> _loadAreas() async {
    setState(() => _loadingAreas = true);
    try {
      final res = await _v1.call(
        module: 'position',
        action: 'get_position_areas', // PositionHandler::get_position_areas
        params: const {},
      );
      final data = res['data'];
      if (data is Map) {
        final Map<String, dynamic> m = Map<String, dynamic>.from(data);
        final tmp = <String, List<String>>{};
        for (final entry in m.entries) {
          final k = entry.key.toString();
          final v = (entry.value is List)
              ? List<String>.from(entry.value)
              : <String>[];
          tmp[k] = v..sort();
        }
        final list = tmp.keys.toList()..sort();
        setState(() {
          _areaMap = tmp;
          _areas = list;
        });
      }
    } catch (e) {
      _snack('Failed to load areas: $e');
    } finally {
      if (mounted) setState(() => _loadingAreas = false);
    }
  }

  // ------------------------------
  // post objesini zarf ne olursa olsun çıkarmaya çalışan helper
  // ------------------------------
  Map<String, dynamic>? _extractPost(dynamic res) {
    if (res is! Map) return null;

    // 1) {data:{post:{...}}}
    dynamic d = res['data'];
    if (d is Map && d['post'] is Map) {
      return _toStrKeyedMap(d['post'] as Map);
    }

    // 2) Çift zarf: {data:{data:{post:{...}}}}
    if (d is Map && d['data'] is Map) {
      final inner = d['data'] as Map;
      if (inner['post'] is Map) {
        return _toStrKeyedMap(inner['post'] as Map);
      }
      // Bazı handler'lar post'u doğrudan inner data'da döndürebilir
      final m = _toStrKeyedMap(inner);
      final hasId = m['id'] != null;
      final looksLikePost =
          m['title'] != null || m['position_id'] != null || m['status'] != null;
      if (hasId && looksLikePost) return m;
    }

    // 3) {data:{id,title,...}}
    if (d is Map) {
      final m = _toStrKeyedMap(d);
      final hasId = m['id'] != null;
      final looksLikePost =
          m['title'] != null || m['position_id'] != null || m['status'] != null;
      if (hasId && looksLikePost) return m;
    }

    // 4) En uç durumda üst seviyede post olabilir
    if (res['post'] is Map) {
      return _toStrKeyedMap(res['post'] as Map);
    }

    return null;
  }

  // ------------------------------
  // GÜNCEL _load()
  // ------------------------------
  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      Map<String, dynamic>? post;

      // 1) Önce overview, olmazsa detail
      try {
        final res = await RecruitmentServiceV1.postOverview(
          id: widget.jobId!,
          recent: 0,
        );
        post = _extractPost(res);
      } catch (e) {
        // overview patlarsa detail'e düş
      }

      if (post == null) {
        try {
          final res2 = await RecruitmentServiceV1.postDetail(id: widget.jobId!);
          post = _extractPost(res2);
        } catch (e) {
          // detail de patladıysa post null kalır
        }
      }

      if (post == null) {
        _snack('Post not found or invalid response.');
        if (mounted) setState(() {});
        return;
      }

      // 2) Normalize + formu doldur
      final norm = _normalizeJob(post);

      // Employment & Age
      _employmentType = _safeStr(norm['employment_type']);
      _ageMinCtrl.text = (norm['age_min'] ?? '').toString();
      _ageMaxCtrl.text = (norm['age_max'] ?? '').toString();

// Salary
      _salaryMinCtrl.text = (norm['salary_min'] ?? '').toString();
      _salaryMaxCtrl.text = (norm['salary_max'] ?? '').toString();
      _salaryCurrencyCtrl.text = (norm['salary_currency'] ?? '').toString();
      _salaryRateUnit = _safeStr(norm['salary_rate_unit']);

// Contract / Probation
      _contractMonthsCtrl.text =
          (norm['contract_duration_months'] ?? '').toString();
      _probationMonthsCtrl.text = (norm['probation_months'] ?? '').toString();

// Rotation + Bonus
      _rotOnCtrl.text = (norm['rotation_on_months'] ?? '').toString();
      _rotOffCtrl.text = (norm['rotation_off_months'] ?? '').toString();
      _bonusType = _safeStr(norm['rotation_bonus_type']);
      _bonusValueCtrl.text = (norm['rotation_bonus_value'] ?? '').toString();

// City
      _cityId = _asInt(norm['city_id']);

      _title.text = (norm['title'] ?? '').toString();
      _location.text = (norm['location'] ?? '').toString();
      _parseLocationFromTextOnEdit(_location.text.trim());

      _status = (norm['status'] ?? '').toString();
      _createdAt = (norm['created_at'] ?? '').toString();
      _updatedAt = (norm['updated_at'] ?? '').toString();

      final pid = _asInt(norm['position_id']);
      final areaFromData = _safeStr(norm['position_area'] ?? norm['area']);
      final deptFromData = _safeStr(norm['position_department']);

      if (pid != null) _positionId = pid;
      if (areaFromData != null) _area = areaFromData;
      if (deptFromData != null && deptFromData.isNotEmpty)
        _department = deptFromData;

      final rawDesc = (norm['description'] ?? '').toString();
      _initialDescDeltaJson = _asDeltaJson(rawDesc);

      _initialReqIds = <int>[];
      final rawReq = norm['requirements_json'];
      if (rawReq != null) {
        try {
          final dec = rawReq is String ? jsonDecode(rawReq) : rawReq;
          if (dec is List) {
            _initialReqIds = dec
                .map((e) {
                  if (e is int) return e;
                  if (e is Map && e['id'] != null) {
                    return int.tryParse('${e['id']}') ?? -1;
                  }
                  return -1;
                })
                .where((x) => x > 0)
                .toList();
          }
        } catch (_) {
          _initialReqIds = <int>[];
        }
      }

      // 3) Area/department/position bağlamını tamamla
      await _ensurePositionContextLoaded();

      // 4) Editor'ları remount et ki initial değerler uygulasın
      if (mounted) {
        setState(() {
          // yeni key’ler = remount
          _descKey = GlobalKey<QuillTextEditorState>();
          _certKey = GlobalKey<CertificatePickerState>();
          _hydrateSeq++; // KeyedSubtree kullanıyorsan kalsın; istersen kaldırabilirsin
        });
      }
    } catch (e) {
      _snack('Failed to load post: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _ensurePositionContextLoaded() async {
    // Area/department boş ama position_id varsa, detaydan doldur
    if ((_area == null || _department == null) && _positionId != null) {
      try {
        final posDetail = await _v1.call(
          module: 'position',
          action: 'detail',
          params: {'id': _positionId},
        );
        final Map? d = (posDetail is Map && posDetail['data'] is Map)
            ? (posDetail['data'] as Map)
            : null;
        final a = _safeStr(d?['area']);
        final dep = _safeStr(d?['department']);
        if (a != null) _area = a;
        if (dep != null) _department = dep;
      } catch (_) {}
    }

    // Departmanlar
    if (_area != null) {
      final deps = _areaMap[_area!] ?? <String>[];
      if (deps.isEmpty) {
        await _loadDepartmentsForArea(_area!, clearSelection: false);
      } else {
        setState(() => _departments = deps);
      }
    }
    if (_area != null && _department != null) {
      await _loadPositionsFor(_area!, _department!, clearSelection: false);
    }
    if (_positionId != null) {
      final p = _positions.firstWhere(
        (e) => _asInt(e['id']) == _positionId,
        orElse: () => const <String, dynamic>{},
      );
      _positionDescPreview = _safeStr(p['description']);
    }

    // Pozisyon listesi
    if (_area != null && _department != null) {
      await _loadPositionsFor(_area!, _department!);
    }

    // Seçili pozisyon açıklaması
    if (_positionId != null) {
      final p = _positions.firstWhere(
        (e) => _asInt(e['id']) == _positionId,
        orElse: () => const <String, dynamic>{},
      );
      _positionDescPreview = _safeStr(p['description']);
    }
  }

  // --------------------------------
  // Position quick search
  // --------------------------------
  void _onGlobalSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final q = _searchCtl.text.trim();
      if (q.length < 3) {
        if (mounted) {
          setState(() {
            _searchResults = <Map<String, dynamic>>[];
            _searching = false;
          });
        }
        return;
      }
      setState(() => _searching = true);
      try {
        final res = await _v1.call(
          module: 'position',
          action: 'get_list',
          params: {'q': q, 'per_page': 10, 'page': 1},
        );
        final items = _extractItems(res);
        setState(() => _searchResults = items.take(10).toList());
      } catch (e) {
        _snack('Search failed: $e');
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  Future<void> _applyQuickPick(Map<String, dynamic> pos) async {
    final a = _safeStr(pos['area']);
    final d = _safeStr(pos['department']);
    final id = _asInt(pos['id']);

    setState(() {
      _area = a;
      _department = d;
      _positionId = null;
      _positions = <Map<String, dynamic>>[];
      _positionDescPreview = null;
      _searchCtl.clear();
      _searchResults = <Map<String, dynamic>>[];
    });

    _areaKey.currentState?.didChange(a);
    _deptKey.currentState?.didChange(d);
    _positionKey.currentState?.didChange(null);

    // Departmanları hazırla
    if (a != null) {
      if ((_areaMap[a] ?? const <String>[]).isEmpty) {
        await _loadDepartmentsForArea(a, clearSelection: false);
      } else {
        setState(() => _departments = _areaMap[a]!);
      }
    }
    if (a != null && d != null) {
      await _loadPositionsFor(a, d, clearSelection: false);
    }

    if (id != null) {
      // Liste içinde var mı?
      var exists = _positions.any((x) => _asInt(x['id']) == id);

      // Yoksa detail’den tek kaydı alıp ekle
      if (!exists) {
        try {
          final det = await _v1.call(
            module: 'position',
            action: 'detail',
            params: {'id': id},
          );
          final data = (det['data'] is Map) ? (det['data'] as Map) : null;
          if (data != null && data.isNotEmpty) {
            setState(() {
              final m = Map<String, dynamic>.from(data);
              _positions.add(m);
              exists = true;
            });
          }
        } catch (_) {}
      }

      // Seçimi uygula
      setState(() {
        _positionId = id;
        _positionKey.currentState?.didChange(id);
        if (exists) {
          final m = _positions.firstWhere(
            (x) => _asInt(x['id']) == id,
            orElse: () => const <String, dynamic>{},
          );
          _positionDescPreview = _safeStr(m['description']);
        }
      });
    }
  }

  // --------------------------------
  // Positions data
  // --------------------------------
  Future<void> _loadDepartmentsForArea(String area,
      {bool clearSelection = false}) async {
    setState(() {
      _loadingDeps = true;
      _departments = <String>[];
      if (clearSelection) {
        _department = null;
        _positions = <Map<String, dynamic>>[];
        _positionId = null;
        _positionDescPreview = null;
      }
    });
    try {
      final res = await _v1.call(
        module: 'position',
        action: 'get_list',
        params: {'area': area, 'per_page': 1000, 'page': 1},
      );
      final items = _extractItems(res);
      final depts = <String>{};
      for (final m in items) {
        final dep = _safeStr(m['department']);
        if (dep != null && dep.isNotEmpty) depts.add(dep);
      }
      final list = depts.toList()..sort();

      setState(() {
        _departments = list;
        _areaMap[area] = list; // cache
      });
    } catch (e) {
      _snack('Failed to load departments: $e');
    } finally {
      if (mounted) setState(() => _loadingDeps = false);
    }
  }

  Future<void> _loadPositionsFor(String area, String department,
      {bool clearSelection = false}) async {
    setState(() {
      _loadingPositions = true;
      _positions = <Map<String, dynamic>>[];
      if (clearSelection) {
        _positionId = null;
        _positionDescPreview = null;
      }
    });
    try {
      final res = await _v1.call(
        module: 'position',
        action: 'get_list',
        params: {
          'area': area,
          'department': department,
          'per_page': 1000,
          'page': 1,
        },
      );

      final items = _extractItems(res);
      int _s(Map<String, dynamic> e) => _asInt(e['sort']) ?? 999999;
      items.sort((a, b) {
        final sa = _s(a), sb = _s(b);
        if (sa != sb) return sa.compareTo(sb);
        return (_safeStr(a['name']) ?? '').compareTo(_safeStr(b['name']) ?? '');
      });

      setState(() => _positions = items);
    } catch (e) {
      _snack('Failed to load positions: $e');
    } finally {
      if (mounted) setState(() => _loadingPositions = false);
    }
  }

  // --------------------------------
  // Location (CityHandler)
  // --------------------------------
  List<Map<String, dynamic>> _extractCities(dynamic res) {
    if (res is Map) {
      final d = res['data'];
      dynamic arr;
      if (d is Map) arr = d['cities'] ?? d['items'];
      arr ??= res['cities'];
      if (arr is List) {
        return arr
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return const <Map<String, dynamic>>[];
  }

  void _onLocationInputChanged() {
    _locDebounce?.cancel();
    final q = _location.text.trim();
    if (q.length < 2) {
      setState(() => _locResults = <Map<String, dynamic>>[]);
      return;
    }
    _locDebounce = Timer(const Duration(milliseconds: 300), () {
      _searchCities(q);
    });
  }

  Future<void> _searchCities(String q) async {
    setState(() => _locSearching = true);
    try {
      final res = await _v1.call(
        module: 'city', // CityHandler
        action: 'list', // list()
        params: {'q': q, 'limit': 10},
      );
      final items = _extractCities(res);
      setState(() => _locResults = items.take(10).toList());
    } catch (e) {
      _snack('City search failed: $e');
    } finally {
      if (mounted) setState(() => _locSearching = false);
    }
  }

  void _selectCity(Map<String, dynamic> city) {
    final name = (city['name'] ?? '').toString();
    final iso3 = (city['iso3'] ?? '').toString().toUpperCase();
    _cityId = int.tryParse('${city['id']}');
    setState(() {
      _selectedCity = city;
      _location.text = iso3.isNotEmpty ? '$name ($iso3)' : name;
      _locResults = <Map<String, dynamic>>[];
    });

    // recents (id bazlı unique, max 5)
    final id = city['id'];
    _recentCities.removeWhere((e) => e['id'] == id);
    _recentCities.insert(0, city);
    if (_recentCities.length > 5) {
      _recentCities.removeLast();
    }
  }

  void _clearLocation() {
    setState(() {
      _selectedCity = null;
      _location.clear();
      _locResults = <Map<String, dynamic>>[];
    });
  }

  void _parseLocationFromTextOnEdit(String text) {
    final re = RegExp(r'^\s*(.+?)\s*\(([A-Z]{3})\)\s*$');
    final m = re.firstMatch(text);
    if (m != null) {
      _selectedCity = {
        'name': m.group(1),
        'iso3': m.group(2),
      };
    } else {
      _selectedCity = null;
    }
  }

  // --------------------------------
  // Save/publish/close/archive
  // --------------------------------
  Future<void> _save() async {
    // Klavyeyi kapat, en yakın Form’u yeniden ölçtür
    FocusScope.of(context).unfocus();

    // 1) Güvenli form doğrulaması
    final formState = _formKey.currentState;
    if (formState == null) {
      _snack('Form not ready, please try again.');
      return;
    }
    final isValid = formState.validate();

    if (!isValid) {
      _snack('Please fill all required fields.');
      return;
    }

    // 2) Kaydı başlat
    setState(() => _busy = true);

    // Quill JSON (boşsa da backend’in kabul ettiği şekilde üret)
    final descJson = _asDeltaJson(_descKey.currentState?.getJson());

    final selectedCertIds = _certKey.currentState?.getSelectedIds() ?? <int>[];
    int? _toInt(TextEditingController c) =>
        c.text.trim().isEmpty ? null : int.tryParse(c.text.trim());
    num? _toNum(TextEditingController c) =>
        c.text.trim().isEmpty ? null : num.tryParse(c.text.trim());

    final ageMin = _toInt(_ageMinCtrl);
    final ageMax = _toInt(_ageMaxCtrl);
    final salMin = _toNum(_salaryMinCtrl);
    final salMax = _toNum(_salaryMaxCtrl);
    final contractMo = _toInt(_contractMonthsCtrl);
    final probationMo = _toInt(_probationMonthsCtrl);
    final rotOn = _toInt(_rotOnCtrl);
    final rotOff = _toInt(_rotOffCtrl);
    final bonusVal = _toNum(_bonusValueCtrl);

    try {
      if (widget.jobId == null) {
        await RecruitmentServiceV1.postCreate(
          companyId: widget.companyId,
          title: _title.text.trim(),
          description: descJson,
          positionId: _positionId,
          area: _area,
          location:
              _location.text.trim().isEmpty ? null : _location.text.trim(),
          requirementsJson: selectedCertIds,
          employmentType: _employmentType,
          ageMin: ageMin,
          ageMax: ageMax,
          salaryMin: salMin,
          salaryMax: salMax,
          salaryCurrency: _salaryCurrencyCtrl.text.trim().isEmpty
              ? null
              : _salaryCurrencyCtrl.text.trim().toUpperCase(),
          salaryRateUnit: _salaryRateUnit,
          contractDurationMonths: contractMo,
          probationMonths: probationMo,
          rotationOnMonths: rotOn,
          rotationOffMonths: rotOff,
          rotationBonusType: _bonusType,
          rotationBonusValue: bonusVal,
          cityId: _cityId,
        );
        _snack('Job post created.');
      } else {
        await RecruitmentServiceV1.postUpdate(
          id: widget.jobId!,
          title: _title.text.trim(),
          description: descJson,
          positionId: _positionId,
          area: _area,
          location:
              _location.text.trim().isEmpty ? null : _location.text.trim(),
          requirementsJson: selectedCertIds,

          // ⬇️ yeni alanlar
          employmentType: _employmentType,
          ageMin: ageMin,
          ageMax: ageMax,
          salaryMin: salMin,
          salaryMax: salMax,
          salaryCurrency: _salaryCurrencyCtrl.text.trim().isEmpty
              ? null
              : _salaryCurrencyCtrl.text.trim().toUpperCase(),
          salaryRateUnit: _salaryRateUnit,
          contractDurationMonths: contractMo,
          probationMonths: probationMo,
          rotationOnMonths: rotOn,
          rotationOffMonths: rotOff,
          rotationBonusType: _bonusType,
          rotationBonusValue: bonusVal,
          cityId: _cityId,
        );
        _snack('Job post updated.');
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _snack('Save failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scrollToFirstError() async {
    final order = <GlobalKey>[
      _titleKey,
      _areaKey,
      _deptKey,
      _positionKey,
    ];

    for (final key in order) {
      final st = key.currentState;
      final ctx = key.currentContext;
      if (st is FormFieldState && st.hasError && ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          alignment: 0.08,
        );
        break;
      }
    }
  }

  Future<void> _publish() async {
    if (widget.jobId == null) return;
    setState(() => _busy = true);
    try {
      await RecruitmentServiceV1.postPublish(id: widget.jobId!);
      await _load();
      _snack('Post published.');
    } catch (e) {
      _snack('Publish failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close() async {
    if (widget.jobId == null) return;
    setState(() => _busy = true);
    try {
      await RecruitmentServiceV1.postClose(id: widget.jobId!);
      await _load();
      _snack('Post closed.');
    } catch (e) {
      _snack('Close failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _archive() async {
    if (widget.jobId == null) return;
    setState(() => _busy = true);
    try {
      await RecruitmentServiceV1.postArchive(id: widget.jobId!);
      await _load();
      _snack('Post archived.');
    } catch (e) {
      _snack('Archive failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // --------------------------------
  // UI helpers (chips clear)
  // --------------------------------
  void _clearArea() {
    setState(() {
      _area = null;
      _department = null;
      _positionId = null;
      _departments = <String>[];
      _positions = <Map<String, dynamic>>[];
      _positionDescPreview = null;
    });
  }

  void _clearDepartment() {
    setState(() {
      _department = null;
      _positionId = null;
      _positions = <Map<String, dynamic>>[];
      _positionDescPreview = null;
    });
  }

  void _clearPosition() {
    setState(() {
      _positionId = null;
      _positionDescPreview = null;
    });
  }

  String? _currentPositionName() {
    final id = _positionId;
    if (id == null) return null;
    final m = _positions.firstWhere(
      (e) => _asInt(e['id']) == id,
      orElse: () => const <String, dynamic>{},
    );
    return _safeStr(m['name']) ?? id.toString();
  }

  // --------------------------------
  // Build
  // --------------------------------
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.jobId != null;
    dynamic s = '';
    if (isEdit) {
      String sIndex = widget.jobId.toString();
      int ilen = sIndex.length;

      if (ilen < 6) {
        for (int i = ilen; i < 6; i++) {
          s += '0';
        }
      }
      s = '$s$sIndex';
    } else {
      s = null;
    }

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(isEdit ? Icons.badge_outlined : Icons.add_card_outlined,
              size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isEdit ? 'Edit Job Post #$s' : 'New Job Post',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (_status != null && _status!.isNotEmpty)
            _StatusPill(status: _status!),
        ],
      ),
    );

    final progressBar = _busy
        ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(minHeight: 2),
          )
        : const SizedBox.shrink();

    final metaSteps = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _StepChip(
              label: 'Area',
              value: _area,
              onClear: _area != null ? _clearArea : null),
          _StepChip(
              label: 'Department',
              value: _department,
              onClear: _department != null ? _clearDepartment : null),
          _StepChip(
              label: 'Position',
              value: _currentPositionName(),
              onClear: _positionId != null ? _clearPosition : null),
          _StepChip(
            label: 'Location',
            value: _location.text.isNotEmpty ? _location.text : null,
            onClear: _location.text.isNotEmpty ? _clearLocation : null,
          ),
        ],
      ),
    );

    final globalSearch = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            children: [
              TextField(
                controller: _searchCtl,
                decoration: InputDecoration(
                  labelText: 'Quick search (min 3 chars, max 10 results)',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : (_searchCtl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtl.clear();
                                setState(() =>
                                    _searchResults = <Map<String, dynamic>>[]);
                              },
                            )
                          : null),
                ),
              ),
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final m = _searchResults[i];
                    final name = _safeStr(m['name']) ?? 'Unnamed';
                    final area = _safeStr(m['area']) ?? '-';
                    final dep = _safeStr(m['department']) ?? '-';
                    return ListTile(
                      dense: true,
                      title: Text(name),
                      subtitle: Text('$area · $dep'),
                      trailing: FilledButton.tonal(
                        onPressed: () => _applyQuickPick(m),
                        child: const Text('Use'),
                      ),
                      onTap: () => _applyQuickPick(m),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // Area
    final areaChips = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.map_outlined, size: 18),
                const SizedBox(width: 8),
                Text('Select Area',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (_loadingAreas)
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
              ]),
              const SizedBox(height: 10),
              FormField<String>(
                key: _areaKey,
                validator: (_) => (_area == null) ? 'Required' : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _areas.map((a) {
                        return ChoiceChip(
                          label: Text(a.toUpperCase()),
                          selected: a == _area,
                          onSelected: (sel) async {
                            if (!sel || _area == a) return;
                            setState(() => _area = a);
                            field.didChange(a); // ⬅️ önemli
                            await _loadDepartmentsForArea(a,
                                clearSelection: true);
                            // Area değişince dependent alanlar hata veriyorsa:
                            _deptKey.currentState?.validate();
                            _positionKey.currentState?.validate();
                          },
                        );
                      }).toList(),
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(field.errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            )),
                      ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );

    final departmentChips = _area != null
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.apartment_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text('Select Department',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      if (_loadingDeps)
                        const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                    ]),
                    const SizedBox(height: 10),
                    FormField<String>(
                      key: _deptKey,
                      validator: (_) =>
                          (_department == null) ? 'Required' : null,
                      builder: (field) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _departments.map((d) {
                              final selected = d == _department;
                              final cap = d.isEmpty
                                  ? ''
                                  : (d[0].toUpperCase() +
                                      d.substring(1).toLowerCase());
                              return ChoiceChip(
                                label: Text(cap),
                                selected: selected,
                                onSelected: _loadingDeps
                                    ? null
                                    : (val) async {
                                        if (!val) return;
                                        setState(() => _department = d);
                                        field.didChange(d);
                                        await _loadPositionsFor(_area!, d,
                                            clearSelection: true);
                                      },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    final hasItem = _positions.any((e) => _asInt(e['id']) == _positionId);
    final dropdownValue = hasItem ? _positionId : null;

    final positionPicker = _department != null
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.work_outline, size: 18),
                      const SizedBox(width: 8),
                      Text('Select Position',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      if (_loadingPositions)
                        const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                    ]),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      key: _positionKey,
                      validator: (_) =>
                          (_positionId == null) ? 'Required' : null,
                      value: dropdownValue,
                      items: _positions
                          .map((e) => DropdownMenuItem<int>(
                                value: _asInt(e['id']),
                                child: Text(_safeStr(e['name']) ?? 'Unnamed'),
                              ))
                          .toList(),
                      onChanged: _loadingPositions
                          ? null
                          : (val) {
                              setState(() {
                                _positionId = val;
                                final m = _positions.firstWhere(
                                  (x) => _asInt(x['id']) == val,
                                  orElse: () => const <String, dynamic>{},
                                );
                                _positionDescPreview =
                                    _safeStr(m['description']);
                              });
                            },
                      decoration: const InputDecoration(
                        labelText: 'Position',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    if ((_positionDescPreview ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _positionDescPreview!,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.left,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    final formCard = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                key: _titleKey,
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Job title (required)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // --- LOCATION SEARCH CARD ---
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.place_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text('Location',
                            style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        if (_locSearching)
                          const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                      ]),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _location,
                        decoration: InputDecoration(
                          labelText: 'Search city',
                          hintText: 'e.g. Istanbul → Istanbul (TUR)',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          suffixIcon: (_location.text.isNotEmpty)
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: _clearLocation)
                              : null,
                        ),
                      ),
                      if (_locResults.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _locResults.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final m = _locResults[i];
                            final title =
                                '${(m['name'] ?? '').toString()} (${(m['iso3'] ?? '').toString().toUpperCase()})';
                            return ListTile(
                              dense: true,
                              title: Text(title),
                              onTap: () => _selectCity(m),
                              trailing: FilledButton.tonal(
                                onPressed: () => _selectCity(m),
                                child: const Text('Use'),
                              ),
                            );
                          },
                        ),
                      ] else if (_recentCities.isNotEmpty &&
                          _location.text.trim().length < 2) ...[
                        const SizedBox(height: 8),
                        Text('Recent',
                            style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _recentCities.map((m) {
                            final cap =
                                '${m['name']} (${(m['iso3'] ?? '').toString().toUpperCase()})';
                            return ActionChip(
                              label: Text(cap),
                              onPressed: () => _selectCity(m),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.description_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('Description',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 8),

              // Remount tetiklemek için KeyedSubtree
              KeyedSubtree(
                key: ValueKey('desc_$_hydrateSeq'),
                child: QuillTextEditor(
                  key: _descKey,
                  initialJsonDelta: _initialDescDeltaJson ??
                      jsonEncode([
                        {"insert": "\n"}
                      ]),
                  showAll: false,
                  toolbarButtons: buildCustomToolbarButtons(base: const {
                    'showBoldButton': true,
                    'showItalicButton': true,
                    'showUnderLineButton': true,
                    'showColorButton': true,
                    'showBackgroundColorButton': true,
                    'showClearFormat': true,
                  }),
                  minHeight: 120,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final requirementsCard = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.rule_folder_outlined, size: 18),
                const SizedBox(width: 8),
                Text('Requirements (Certificates)',
                    style: Theme.of(context).textTheme.titleMedium),
              ]),
              const SizedBox(height: 12),

              // Remount tetiklemek için KeyedSubtree
              KeyedSubtree(
                key: ValueKey('cert_$_hydrateSeq'),
                child: CertificatePicker(
                  key: _certKey,
                  initialSelectedIds: _initialReqIds,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final offerTermsCard = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.handshake_outlined, size: 18),
                const SizedBox(width: 8),
                Text('Offer / Terms',
                    style: Theme.of(context).textTheme.titleMedium),
              ]),
              const SizedBox(height: 12),

              // Employment Type
              DropdownButtonFormField<String>(
                value: _employmentType,
                items: const [
                  'full_time',
                  'part_time',
                  'contract',
                  'seasonal',
                  'internship',
                  'temporary',
                  'other'
                ]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _employmentType = v),
                decoration: const InputDecoration(
                  labelText: 'Employment type',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),

              const SizedBox(height: 12),

              // Age min/max
              Row(children: [
                Expanded(
                    child: TextField(
                  controller: _ageMinCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Age min',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                  controller: _ageMaxCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Age max',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                )),
              ]),

              const SizedBox(height: 12),

              // Salary min/max
              Row(children: [
                Expanded(
                    child: TextField(
                  controller: _salaryMinCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}$')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Salary min',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                  controller: _salaryMaxCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}$')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Salary max',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                )),
              ]),

              const SizedBox(height: 8),

              Row(children: [
                Expanded(
                    child: TextField(
                  controller: _salaryCurrencyCtrl,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Currency (ISO-4217)',
                    hintText: 'USD / EUR / OTHERS',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: DropdownButtonFormField<String>(
                  value: _salaryRateUnit,
                  items: const [
                    'hour',
                    'day',
                    'month',
                    'year',
                    'contract',
                    'trip'
                  ]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _salaryRateUnit = v),
                  decoration: const InputDecoration(
                    labelText: 'Rate unit',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                )),
              ]),

              const SizedBox(height: 12),

              // Contract / Probation
              Row(children: [
                Expanded(
                    child: TextField(
                  controller: _contractMonthsCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Contract (months)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                  controller: _probationMonthsCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Probation (months)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                )),
              ]),

              const SizedBox(height: 12),

              // Rotation & Bonus
              Row(children: [
                Expanded(
                    child: TextField(
                  controller: _rotOnCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Rotation ON (months)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                  controller: _rotOffCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Rotation OFF (months)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                )),
              ]),

              const SizedBox(height: 8),

              Row(children: [
                Expanded(
                    child: DropdownButtonFormField<String>(
                  value: _bonusType,
                  items: const ['none', 'fixed', 'one_salary', 'percent']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _bonusType = v),
                  decoration: const InputDecoration(
                    labelText: 'Bonus type',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                  controller: _bonusValueCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}$')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Bonus value (if fixed/percent)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                )),
              ]),
            ],
          ),
        ),
      ),
    );

    Widget _actionButtons() {
      final s = (_status ?? 'draft').toLowerCase();
      final isEdit = widget.jobId != null;
      final busy = _busy;

      return Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: busy ? null : () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
          ),
          if (isEdit && s == 'draft')
            FilledButton.icon(
              onPressed: busy ? null : _publish,
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('Publish'),
            ),
          if (isEdit && s == 'published')
            FilledButton.icon(
              onPressed: busy ? null : _close,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Close'),
            ),
          if (isEdit && s == 'closed')
            FilledButton.icon(
              onPressed: busy ? null : _archive,
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Archive'),
            ),
          FilledButton.icon(
            onPressed: busy ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
        ],
      );
    }

    final metaCard = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Text('Metadata',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                _MetaRow(label: 'Status', value: _status ?? 'draft'),
                const SizedBox(width: 12),
                _MetaRow(label: 'Created', value: _createdAt ?? '-'),
                const SizedBox(width: 12),
                _MetaRow(label: 'Updated', value: _updatedAt ?? '-'),
              ]),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: _actionButtons()),
            ],
          ),
        ),
      ),
    );

    return CustomScaffold(
      title: 'Job Post Editor',
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          controller: _scrollCtrl,
          children: [
            header,
            progressBar,
            metaSteps,
            globalSearch,
            areaChips,
            departmentChips,
            positionPicker,
            formCard,
            offerTermsCard,
            requirementsCard,
            metaCard,
          ],
        ),
      ),
    );
  }
}

// ---- UI bits ----

class _StepChip extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback? onClear;
  const _StepChip({required this.label, this.value, this.onClear});

  @override
  Widget build(BuildContext context) {
    final has = (value != null && value!.isNotEmpty);
    return InputChip(
      label: Text(has ? '$label: $value' : label),
      avatar: has ? const Icon(Icons.check, size: 18) : null,
      onDeleted: has ? onClear : null,
      deleteIcon: const Icon(Icons.close, size: 18),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.outline),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color bg;
    Color fg;
    switch (s) {
      case 'draft':
        bg = Colors.grey.withAlpha(30);
        fg = Colors.grey.shade800;
        break;
      case 'published':
        bg = Colors.green.withAlpha(30);
        fg = Colors.green.shade800;
        break;
      case 'closed':
        bg = Colors.orange.withAlpha(30);
        fg = Colors.orange.shade800;
        break;
      case 'archived':
        bg = Colors.blueGrey.withAlpha(30);
        fg = Colors.blueGrey.shade800;
        break;
      default:
        bg = Theme.of(context).colorScheme.surfaceContainerHighest;
        fg = Theme.of(context).colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        s.isEmpty ? 'unknown' : s,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}
