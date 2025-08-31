import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/job_service.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class JobEditorPage extends StatefulWidget {
  final int companyId;
  final int? jobId; // null => create, not null => edit

  const JobEditorPage({
    super.key,
    required this.companyId,
    this.jobId,
  });

  @override
  State<JobEditorPage> createState() => _JobEditorPageState();
}

class _JobEditorPageState extends State<JobEditorPage> {
  late final JobService _jobs;
  late final V1ApiManager _v1;

  // form fields
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locCtrl = TextEditingController(); // readOnly; city picker doldurur
  final _notesCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // enums
  final _areas = const ['crew', 'office'];
  final _areaLabels = const {'crew': 'Crew', 'office': 'Office'};
  final _visibilities = const ['public', 'followers', 'private'];
  String _area = 'crew';
  String _visibility = 'public';

  // departments (optional) & positions
  Map<String, List<String>> _departmentsByArea = {};
  String? _department; // optional
  bool _loadingDepartments = false;

  // positions fetched from backend (for selected area/department)
  List<Map<String, dynamic>> _positions = [];
  bool _loadingPositions = false;
  int? _positionId;

  // cities (from GeoHandler.get_city) — once, then client-side filter
  List<_City> _cities = [];
  bool _loadingCities = false;

  // certificates — once, then client-side filter
  List<_Certificate> _certs = [];
  bool _loadingCerts = false;

  // requirements state (JSON)
  // canonical keys: min_education, certificates, optional_certificates, min_years, notes
  final List<_Edu> _eduOptions = const [
    _Edu('primary', 'Primary School'),
    _Edu('middle', 'Middle School'),
    _Edu('highschool', 'High School'),
    _Edu('associate', 'Associate Degree'),
    _Edu('bachelor', 'Undergraduate'),
    _Edu('master', 'Master'),
    _Edu('phd', 'Doctorate'),
  ];
  String _minEducation = 'highschool';
  int _minYears = 0;
  final Set<int> _reqCertIds = {};
  final Set<int> _optCertIds = {};

  // page state
  bool _loading = true;
  bool _saving = false;
  String? _status; // open|draft|closed|...

  @override
  void initState() {
    super.initState();
    _v1 = context.read<V1ApiManager>();
    _jobs = JobService(_v1);
    _bootstrap();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ---------- helpers ----------
  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(RegExp(r'\s+')).map((w) {
      if (w.isEmpty) return w;
      final lw = w.toLowerCase();
      return lw[0].toUpperCase() + lw.substring(1);
    }).join(' ');
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      await Future.wait([
        _fetchDepartments(),
        _fetchCities(),
        _fetchCertificates(),
      ]);
      await _prefillIfEdit();
      await _fetchPositions();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- backend calls ----------
  /// PositionHandler::get_position_areas -> { area: [departments] }
  Future<void> _fetchDepartments() async {
    setState(() => _loadingDepartments = true);
    try {
      final res = await _v1.call(
        module: 'position',
        action: 'get_position_areas',
        params: const {},
      );

      final raw = (res['data'] ?? res);
      final map = (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};
      final parsed = <String, List<String>>{};
      for (final e in map.entries) {
        final k = e.key.toString();
        final v = e.value;
        if (v is List) {
          parsed[k] =
              v.map((x) => x.toString()).where((s) => s.isNotEmpty).toList();
        }
      }
      _departmentsByArea = parsed;

      // seçili area için departman uyumluluğunu koru
      final deps = _departmentsByArea[_area] ?? const [];
      if (!deps.contains(_department)) {
        _department = null;
      }
    } catch (_) {
      _departmentsByArea = {};
      _department = null;
    } finally {
      if (mounted) setState(() => _loadingDepartments = false);
    }
  }

  /// PositionHandler::get_positions_by_area (area zorunlu, department opsiyonel)
  Future<void> _fetchPositions() async {
    setState(() => _loadingPositions = true);
    try {
      final res = await _v1.call(
        module: 'position',
        action: 'get_positions_by_area',
        params: {
          'area': _area,
          if (_department != null && _department!.isNotEmpty)
            'department': _department,
          'perPage': 200,
        },
      );

      final d = res['data'];
      List items;
      if (d is Map && d['items'] is List) {
        items = d['items'];
      } else if (d is List) {
        items = d;
      } else if (res['items'] is List) {
        items = res['items'];
      } else {
        items = const [];
      }

      _positions = items
          .whereType<Map>()
          .map((e) => {
                'id': int.tryParse('${e['id'] ?? e['position_id'] ?? 0}') ?? 0,
                'name': (e['name'] ?? e['title'] ?? '').toString(),
                // küçük punto açıklama:
                'desc': (e['category'] ?? e['department'] ?? '').toString(),
              })
          .where((m) => m['id'] != 0 && (m['name'] as String).isNotEmpty)
          .toList();

      // seçili pozisyon artık listede yoksa sıfırla
      if (_positionId != null &&
          !_positions.any((p) => p['id'] == _positionId)) {
        _positionId = null;
      }
    } catch (_) {
      _positions = const [];
      _positionId = null;
    } finally {
      if (mounted) setState(() => _loadingPositions = false);
    }
  }

  /// GeoHandler::get_city -> { cities: [ {id,name,iso3}, ... ] }
  Future<void> _fetchCities() async {
    setState(() => _loadingCities = true);
    try {
      final res = await _v1.call(
        module: 'geo',
        action: 'get_city',
        params: const {},
      );
      final raw = res['data'] ?? res;
      final list = (raw is Map && raw['cities'] is List)
          ? raw['cities']
          : (raw is List ? raw : const []);
      _cities = list
          .whereType<Map>()
          .map((e) => _City(
                id: int.tryParse('${e['id'] ?? 0}') ?? 0,
                name: (e['name'] ?? '').toString(),
                iso3: (e['iso3'] ?? '').toString(),
              ))
          .where((c) => c.id > 0 && c.name.isNotEmpty)
          .toList();

      // eğer lokasyon zaten text olarak set edildiyse elleme
    } catch (_) {
      _cities = const [];
    } finally {
      if (mounted) setState(() => _loadingCities = false);
    }
  }

  /// Certificates: esnek parser (module: 'certificate', action: 'list' | 'simple_list')
  Future<void> _fetchCertificates() async {
    setState(() => _loadingCerts = true);
    try {
      Map res;
      try {
        res = await _v1.call(
          module: 'certificate',
          action: 'simple_list',
          params: const {'perPage': 1000},
        );
      } catch (_) {
        res = await _v1.call(
          module: 'certificate',
          action: 'list',
          params: const {'perPage': 1000},
        );
      }
      final raw = res['data'] ?? res;
      final items = (raw is Map && raw['items'] is List)
          ? raw['items']
          : (raw is List ? raw : const []);

      _certs = items
          .whereType<Map>()
          .map((e) => _Certificate(
                id: int.tryParse('${e['id'] ?? 0}') ?? 0,
                name: (e['name'] ?? '').toString(),
                stcw: (e['stcw_code'] ?? '').toString(),
                groupId: int.tryParse('${e['group_id'] ?? 0}') ?? 0,
                sort: int.tryParse('${e['sort_order'] ?? 999999}') ?? 999999,
                note: (e['note'] ?? '').toString(),
              ))
          .where((c) => c.id > 0 && c.name.isNotEmpty)
          .toList()
        ..sort((a, b) {
          final g = a.groupId.compareTo(b.groupId);
          if (g != 0) return g;
          final s = a.sort.compareTo(b.sort);
          if (s != 0) return s;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
    } catch (_) {
      _certs = const [];
    } finally {
      if (mounted) setState(() => _loadingCerts = false);
    }
  }

  Future<void> _prefillIfEdit() async {
    if (widget.jobId == null) return;
    try {
      final data = await _jobs.detail(widget.jobId!);
      final row = (data['item'] is Map)
          ? Map<String, dynamic>.from(data['item'])
          : Map<String, dynamic>.from(data);

      _titleCtrl.text = (row['title'] ?? '').toString();
      _descCtrl.text = (row['description'] ?? '').toString();
      _locCtrl.text = (row['location'] ?? '').toString();

      _area = (row['area'] ?? _area).toString();
      _visibility = (row['visibility'] ?? _visibility).toString();
      _positionId = int.tryParse('${row['position_id'] ?? 0}');
      _status = (row['status'] ?? '').toString();

      // requirements JSON oku
      final req = row['requirements'];
      Map<String, dynamic> r = {};

      if (req is String && req.trim().isNotEmpty) {
        final dec = _tryDecodeMap(req);
        if (dec != null) r = dec;
      } else if (req is Map) {
        r = Map<String, dynamic>.from(req);
      }

      if (r.isNotEmpty) {
        _minEducation = (r['min_education'] ?? _minEducation).toString();
        _minYears = int.tryParse('${r['min_years'] ?? _minYears}') ?? _minYears;

        final must = _asIntList(r['certificates']);
        final opt = _asIntList(r['optional_certificates']);

        _reqCertIds
          ..clear()
          ..addAll(must);
        _optCertIds
          ..clear()
          ..addAll(opt);

        _notesCtrl.text = (r['notes'] ?? '').toString();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Load failed: $e')),
      );
    }
  }

  Map<String, dynamic>? _tryDecodeMap(String s) {
    try {
      final dynamic dec = jsonDecode(s);
      if (dec is Map) {
        return Map<String, dynamic>.from(dec);
      }
    } catch (_) {
      // yut
    }
    return null;
  }

  List<int> _asIntList(dynamic v) {
    if (v is List) {
      return v.map((e) => int.tryParse('$e') ?? 0).where((n) => n > 0).toList();
    }
    return const [];
  }

  // ---------- actions ----------
  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // requirements payload
    final req = <String, dynamic>{
      'min_education': _minEducation,
      if (_minYears > 0) 'min_years': _minYears,
      if (_reqCertIds.isNotEmpty) 'certificates': _reqCertIds.toList(),
      if (_optCertIds.isNotEmpty) 'optional_certificates': _optCertIds.toList(),
      if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
    };

    setState(() => _saving = true);
    try {
      if (widget.jobId == null) {
        final id = await _jobs.create(
          companyId: widget.companyId,
          title: _titleCtrl.text.trim(),
          area: _area,
          visibility: _visibility,
          positionId: _positionId, // null olabilir
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          requirements: req.isEmpty ? null : req,
          location: _locCtrl.text.trim().isEmpty ? null : _locCtrl.text.trim(),
          notifyFollowers: false,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Job created')));
        Navigator.pop(context, true);
      } else {
        final patch = <String, dynamic>{
          'title': _titleCtrl.text.trim(),
          'area': _area,
          'visibility': _visibility,
          'position_id': _positionId,
          'description': _descCtrl.text.trim(),
          'requirements': req,
          'location': _locCtrl.text.trim(),
        };
        await _jobs.updateJob(widget.jobId!, patch);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _closeJob() async {
    if (widget.jobId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Close job?'),
        content: const Text('This will close the job to new applications.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Close')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _jobs.close(widget.jobId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Job closed')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Close failed: $e')));
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.jobId != null;
    final deps = _departmentsByArea[_area] ?? const <String>[];

    return CustomScaffold(
      title: isEdit ? 'Edit Job' : 'New Job',
      actions: [
        if (isEdit && (_status ?? '') != 'closed')
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              onPressed: _saving ? null : _closeJob,
              icon: const Icon(Icons.lock),
              label: const Text('Close'),
            ),
          ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Title is required'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Area & Visibility
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _area,
                          items: _areas
                              .map((a) => DropdownMenuItem(
                                    value: a,
                                    child:
                                        Text(_areaLabels[a] ?? _titleCase(a)),
                                  ))
                              .toList(),
                          onChanged: (v) async {
                            if (v == null || v == _area) return;
                            setState(() {
                              _area = v;
                              _department = null; // area değişti
                              _positionId = null;
                            });
                            await _fetchPositions();
                          },
                          decoration: const InputDecoration(
                            labelText: 'Area',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _visibility,
                          items: _visibilities
                              .map((v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(_titleCase(v)),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _visibility = v ?? _visibility),
                          decoration: const InputDecoration(
                            labelText: 'Visibility',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Department (optional)
                  if (_loadingDepartments)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  if (deps.isNotEmpty) ...[
                    DropdownButtonFormField<String?>(
                      value: _department,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('— All Departments —'),
                        ),
                        ...deps.map(
                          (d) => DropdownMenuItem<String?>(
                            value: d,
                            child: Text(_titleCase(d)),
                          ),
                        ),
                      ],
                      onChanged: (v) async {
                        setState(() {
                          _department = v;
                          _positionId = null;
                        });
                        await _fetchPositions();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Department (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Position (search-inside picker)
                  _SearchablePicker<int>(
                    label: 'Position',
                    value: _positionId,
                    items: _positions
                        .map((p) => _PickItem<int>(
                              value: p['id'] as int,
                              title: _titleCase(p['name'] as String),
                              subtitle:
                                  (p['desc'] as String?)?.trim().isEmpty ?? true
                                      ? null
                                      : p['desc'] as String,
                            ))
                        .toList(),
                    loading: _loadingPositions,
                    onRefresh: _fetchPositions,
                    onChanged: (v) => setState(() => _positionId = v),
                    allowClear: true,
                    emptyText: 'No position',
                  ),
                  const SizedBox(height: 12),

                  // City (Location)
                  _SearchablePicker<_City>(
                    label: 'Location (optional)',
                    value: _selectedCityFromText(),
                    items: _cities
                        .map((c) => _PickItem<_City>(
                              value: c,
                              title: c.display,
                              subtitle: null,
                            ))
                        .toList(),
                    loading: _loadingCities,
                    onRefresh: _fetchCities,
                    onChanged: (c) {
                      setState(() {
                        _locCtrl.text = c == null ? '' : c.display;
                      });
                    },
                    allowClear: true,
                    controller: _locCtrl,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _descCtrl,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // REQUIREMENTS
                  Text('Requirements',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),

                  // Min education & Min years
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _minEducation,
                          items: _eduOptions
                              .map((e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.label),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(
                              () => _minEducation = v ?? _minEducation),
                          decoration: const InputDecoration(
                            labelText: 'Min education',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Min years (experience)',
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _minYears.toDouble(),
                                  min: 0,
                                  max: 40,
                                  divisions: 40,
                                  label: '$_minYears',
                                  onChanged: (v) =>
                                      setState(() => _minYears = v.round()),
                                ),
                              ),
                              SizedBox(
                                width: 42,
                                child: Text(
                                  '$_minYears',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Required Certificates
                  _MultiSelectPicker<int>(
                    label: 'Required certificates',
                    allItems: _certs
                        .map((c) => _PickItem<int>(
                              value: c.id,
                              title: c.title,
                              subtitle: c.subtitle,
                              group:
                                  c.groupId == 0 ? null : 'Group ${c.groupId}',
                            ))
                        .toList(),
                    selected: _reqCertIds,
                    loading: _loadingCerts,
                    onRefresh: _fetchCertificates,
                    onChanged: (setVals) => setState(() => _reqCertIds
                      ..clear()
                      ..addAll(setVals)),
                  ),
                  const SizedBox(height: 12),

                  // Optional Certificates
                  _MultiSelectPicker<int>(
                    label: 'Optional certificates',
                    allItems: _certs
                        .map((c) => _PickItem<int>(
                              value: c.id,
                              title: c.title,
                              subtitle: c.subtitle,
                              group:
                                  c.groupId == 0 ? null : 'Group ${c.groupId}',
                            ))
                        .toList(),
                    selected: _optCertIds,
                    loading: _loadingCerts,
                    onRefresh: _fetchCertificates,
                    onChanged: (setVals) => setState(() => _optCertIds
                      ..clear()
                      ..addAll(setVals)),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _notesCtrl,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),

                  const SizedBox(height: 20),

                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_saving
                        ? 'Saving…'
                        : (isEdit ? 'Save Changes' : 'Create Job')),
                  ),
                ],
              ),
            ),
    );
  }

  _City? _selectedCityFromText() {
    final t = _locCtrl.text.trim();
    if (t.isEmpty) return null;
    // mevcut listede bulmaya çalış; yoksa null bırak (yazı serbest)
    try {
      return _cities.firstWhere((c) => c.display == t);
    } catch (_) {
      return null;
    }
  }
}

/* ===========================
 * Helper Models
 * =========================== */

class _IdName {
  final int id;
  final String name;
  final String? subtitle;
  _IdName(this.id, this.name, {this.subtitle});
}

class _City {
  final int id;
  final String name;
  final String iso3;
  _City({required this.id, required this.name, required this.iso3});
  String get display {
    final proper = name.isEmpty
        ? name
        : name[0].toUpperCase() + name.substring(1).toLowerCase();
    return iso3.isEmpty ? proper : '$proper ($iso3)';
  }
}

class _Certificate {
  final int id;
  final int groupId;
  final int sort;
  final String name;
  final String stcw;
  final String note;
  _Certificate({
    required this.id,
    required this.name,
    required this.stcw,
    required this.groupId,
    required this.sort,
    required this.note,
  });

  String get title => name;
  String? get subtitle {
    final parts = <String>[];
    if (stcw.isNotEmpty) parts.add(stcw);
    if (note.isNotEmpty) parts.add(note);
    return parts.isEmpty ? null : parts.join(' • ');
  }
}

class _Edu {
  final String key;
  final String label;
  const _Edu(this.key, this.label);
}

/* ===========================
 * Reusable Pickers
 * =========================== */

class _PickItem<T> {
  final T value;
  final String title;
  final String? subtitle;
  final String? group;
  _PickItem(
      {required this.value, required this.title, this.subtitle, this.group});
}

/// Single-select searchable picker. Renders as a TextFormField (readOnly),
/// opens a bottom sheet with search + list.
class _SearchablePicker<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<_PickItem<T>> items;
  final bool loading;
  final Future<void> Function()? onRefresh;
  final ValueChanged<T?> onChanged;
  final bool allowClear;
  final String emptyText;
  final TextEditingController? controller; // optional: mirrors selected text

  const _SearchablePicker({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.loading,
    required this.onChanged,
    this.onRefresh,
    this.allowClear = false,
    this.emptyText = 'None',
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final current = items.where((i) => i.value == value).toList();
    final title = current.isNotEmpty ? current.first.title : '';
    final sub = current.isNotEmpty ? current.first.subtitle : null;

    return InkWell(
      onTap: loading
          ? null
          : () async {
              final picked = await _showPicker<T>(context, label, items, value);
              if (picked is _PickerClear) {
                onChanged(null);
                controller?.text = '';
              } else if (picked != null) {
                onChanged(picked);
                if (controller != null) {
                  final display = items
                      .firstWhere((e) => e.value == picked,
                          orElse: () => items.first)
                      .title;
                  controller!.text = display;
                }
              }
            },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: loading
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  tooltip: onRefresh != null ? 'Refresh' : 'Open',
                  onPressed: loading
                      ? null
                      : () async {
                          if (onRefresh != null) {
                            await onRefresh!();
                          } else {
                            final picked = await _showPicker<T>(
                                context, label, items, value);
                            if (picked is _PickerClear) {
                              onChanged(null);
                              controller?.text = '';
                            } else if (picked != null) {
                              onChanged(picked);
                              if (controller != null) {
                                final display = items
                                    .firstWhere((e) => e.value == picked,
                                        orElse: () => items.first)
                                    .title;
                                controller!.text = display;
                              }
                            }
                          }
                        },
                  icon: Icon(onRefresh != null ? Icons.refresh : Icons.search),
                ),
        ),
        child: (value == null)
            ? Text(emptyText,
                style: TextStyle(color: Theme.of(context).hintColor))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  if (sub != null && sub.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(sub,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Theme.of(context).hintColor)),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Multi-select searchable picker with chips
class _MultiSelectPicker<T> extends StatelessWidget {
  final String label;
  final List<_PickItem<T>> allItems;
  final Set<T> selected;
  final bool loading;
  final Future<void> Function()? onRefresh;
  final ValueChanged<Set<T>> onChanged;

  const _MultiSelectPicker({
    super.key,
    required this.label,
    required this.allItems,
    required this.selected,
    required this.loading,
    required this.onChanged,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final selectedItems =
        allItems.where((i) => selected.contains(i.value)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: loading
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: onRefresh != null ? 'Refresh' : 'Add',
                    onPressed: loading
                        ? null
                        : () async {
                            if (onRefresh != null) {
                              await onRefresh!();
                            } else {
                              final picked = await _showMultiPicker<T>(
                                  context, label, allItems, selected);
                              if (picked is Set<T>) onChanged(picked);
                            }
                          },
                    icon:
                        Icon(onRefresh != null ? Icons.refresh : Icons.search),
                  ),
          ),
          child: selectedItems.isEmpty
              ? Text('No selection',
                  style: TextStyle(color: Theme.of(context).hintColor))
              : Wrap(
                  spacing: 8,
                  runSpacing: -8,
                  children: selectedItems
                      .map((i) => InputChip(
                            label:
                                Text(i.title, overflow: TextOverflow.ellipsis),
                            onDeleted: () {
                              final next = Set<T>.from(selected)
                                ..remove(i.value);
                              onChanged(next);
                            },
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

/* ===========================
 * Bottom sheet pickers (search inside)
 * =========================== */

class _PickerClear {
  const _PickerClear();
}

Future<T?> _showPicker<T>(
  BuildContext context,
  String title,
  List<_PickItem<T>> items,
  T? current,
) async {
  final controller = TextEditingController();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      List<_PickItem<T>> filtered = List.of(items);
      void applyFilter() {
        final q = controller.text.trim().toLowerCase();
        filtered = items.where((e) {
          final hay = '${e.title} ${e.subtitle ?? ''}'.toLowerCase();
          return q.isEmpty || hay.contains(q);
        }).toList();
      }

      applyFilter();

      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 12,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSt) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(title,
                          style: Theme.of(ctx).textTheme.titleMedium)),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, const _PickerClear()),
                    child: const Text('Clear'),
                  ),
                ],
              ),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search…',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setSt(applyFilter),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No results'),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final it = filtered[i];
                          final selected = it.value == current;
                          return ListTile(
                            title: Text(it.title),
                            subtitle:
                                (it.subtitle != null && it.subtitle!.isNotEmpty)
                                    ? Text(it.subtitle!)
                                    : null,
                            trailing: selected ? const Icon(Icons.check) : null,
                            onTap: () => Navigator.pop(ctx, it.value),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

Future<Set<T>?> _showMultiPicker<T>(
  BuildContext context,
  String title,
  List<_PickItem<T>> items,
  Set<T> selected,
) async {
  final controller = TextEditingController();
  final sel = Set<T>.from(selected);

  return showModalBottomSheet<Set<T>>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      List<_PickItem<T>> filtered = List.of(items);
      void applyFilter() {
        final q = controller.text.trim().toLowerCase();
        filtered = items.where((e) {
          final hay =
              '${e.title} ${e.subtitle ?? ''} ${e.group ?? ''}'.toLowerCase();
          return q.isEmpty || hay.contains(q);
        }).toList();
      }

      applyFilter();

      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 12,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSt) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(title,
                          style: Theme.of(ctx).textTheme.titleMedium)),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, <T>{}),
                    child: const Text('Clear all'),
                  ),
                ],
              ),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search…',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setSt(applyFilter),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No results'),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final it = filtered[i];
                          final checked = sel.contains(it.value);
                          return CheckboxListTile(
                            title: Text(it.title),
                            subtitle:
                                (it.subtitle != null && it.subtitle!.isNotEmpty)
                                    ? Text(it.subtitle!)
                                    : null,
                            value: checked,
                            onChanged: (v) => setSt(() {
                              if (v == true) {
                                sel.add(it.value);
                              } else {
                                sel.remove(it.value);
                              }
                            }),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, sel),
                    child: const Text('Done'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    },
  );
}
