import 'package:flutter/material.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class JoinCompanyPage extends StatefulWidget {
  final int? companyId;
  const JoinCompanyPage({super.key, this.companyId});

  @override
  State<JoinCompanyPage> createState() => _JoinCompanyPageState();
}

class _JoinCompanyPageState extends State<JoinCompanyPage> {
  final v1 = V1ApiManager();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customPositionController =
      TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  List<String> _positionList = [];
  Map<String, List<String>> _areaOptions = {};

  bool _isLoading = false;
  String? _error;
  String? _selectedAreaType;
  String? _selectedArea;
  String? _selectedPosition;

  List<int> _joinedCompanyIds = [];
  Map<String, dynamic>? _selectedCompany;

  @override
  void initState() {
    super.initState();
    _loadJoinedCompanies();
    _fetchAreaOptions(); // opsiyonel: yoksa sessiz geçer
    if (widget.companyId != null) {
      _fetchCompanyById(widget.companyId!);
    }
  }

  Future<void> _fetchAreaOptions() async {
    // Eğer henüz v1’de uç yoksa sessiz fallback:
    try {
      final res = await v1.call(
        module: 'position',
        action: 'areas',
        params: {},
        context: context,
      );
      if (res['success'] == true && res['data'] is Map) {
        final raw = Map<String, dynamic>.from(res['data']);
        setState(() {
          _areaOptions = raw.map((k, v) => MapEntry(k, List<String>.from(v)));
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchPositions({String? area}) async {
    if (_selectedArea == null) return;
    setState(() {
      _isLoading = true;
      _positionList = [];
    });

    try {
      final res = await v1.call(
        module: 'position',
        action: 'by_area',
        params: {'area': _selectedArea},
        context: context,
      );
      if (res['success'] == true && res['data'] is List) {
        final items = List.from(res['data']);
        setState(() {
          _positionList = items
              .map((e) => (e['name'] ?? '').toString())
              .where((e) => e.isNotEmpty)
              .toList();
        });
      }
    } catch (_) {}

    setState(() => _isLoading = false);
  }

  Future<void> _loadJoinedCompanies({String? area}) async {
    final res = await v1.call(
      module: 'company',
      action: 'my_list',
      params: {},
      context: context,
    );

    if (res['success'] == true &&
        res['data'] is Map &&
        res['data']['items'] is List) {
      final items = List.from(res['data']['items']);
      setState(() {
        _joinedCompanyIds = items
            .map((e) =>
                int.tryParse((e['company_id'] ?? e['id']).toString()) ?? 0)
            .where((x) => x > 0)
            .toList();
      });
    }
  }

  Future<void> _fetchCompanyById(int id) async {
    final res = await v1.call(
      module: 'company',
      action: 'detail',
      params: {'id': id},
      context: context,
    );

    if (res['success'] == true && res['data'] is Map) {
      setState(() => _selectedCompany = Map<String, dynamic>.from(res['data']));
    } else {
      setState(() => _error = 'Company not found.');
    }
  }

  Future<void> _attemptJoin() async {
    if (_selectedCompany == null) return;

    final rank = _selectedPosition == 'Other'
        ? _customPositionController.text.trim()
        : _selectedPosition;

    final res = await v1.call(
      module: 'company',
      action: 'add_member',
      params: {
        'company_id': _selectedCompany!['id'],
        'role': 'employee',
        if (rank != null && rank.isNotEmpty) 'rank': rank,
      },
      context: context,
    );

    if (res['success'] == true || res['ok'] == true) {
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() =>
          _error = (res['message'] ?? 'Failed to join company.').toString());
    }
  }

  Future<void> _searchCompany(String query) async {
    if (query.trim().length < 3) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = await v1.call(
      module: 'company',
      action: 'list',
      params: {'q': query.trim(), 'page': 1, 'perPage': 10},
      context: context,
    );

    if (res['success'] == true &&
        res['data'] is Map &&
        res['data']['items'] is List) {
      final items = List<Map<String, dynamic>>.from(
        List.from(res['data']['items'])
            .map((e) => Map<String, dynamic>.from(e)),
      );
      setState(() {
        _searchResults = items.map((c) {
          final id =
              int.tryParse((c['id'] ?? c['company_id']).toString()) ?? -1;
          final isMember = _joinedCompanyIds.contains(id);
          return {...c, 'is_member': isMember, 'id': id};
        }).toList();
      });
    } else {
      setState(() {
        _error = 'No companies found.';
        _searchResults.clear();
      });
    }

    setState(() => _isLoading = false);
  }

  Widget _buildCompanyTile(Map<String, dynamic> company) {
    final bool isMember = company['is_member'] == true;
    return ListTile(
      leading: const Icon(Icons.business),
      title: Text((company['name'] ?? 'Unnamed').toString()),
      subtitle: Text((company['email'] ?? '').toString()),
      trailing: isMember
          ? const Text('Already Joined', style: TextStyle(color: Colors.grey))
          : ElevatedButton(
              onPressed: () => setState(() => _selectedCompany = company),
              child: const Text('Select'),
            ),
    );
  }

  Widget _buildSelectedCompanyForm() {
    if (_selectedCompany == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.business),
          title: Text((_selectedCompany!['name'] ?? 'Unnamed').toString()),
          subtitle: Text((_selectedCompany!['email'] ?? '').toString()),
        ),
        const SizedBox(height: 16),

        // ——— Opsiyonel area/pozisyon ———
        if (_areaOptions.isNotEmpty)
          DropdownButtonFormField<String>(
            value: _selectedAreaType,
            decoration: const InputDecoration(
              labelText: 'Are you applying for a ship or office position?',
              border: OutlineInputBorder(),
            ),
            items: _areaOptions.keys
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedAreaType = value;
                _selectedArea = null;
                _selectedPosition = null;
              });
            },
          ),
        if (_areaOptions.isNotEmpty) const SizedBox(height: 16),

        if (_selectedAreaType != null &&
            _areaOptions[_selectedAreaType] != null)
          DropdownButtonFormField<String>(
            value: _selectedArea,
            decoration: const InputDecoration(
              labelText: 'Select Department Area',
              border: OutlineInputBorder(),
            ),
            items: _areaOptions[_selectedAreaType]!
                .map((area) => DropdownMenuItem(value: area, child: Text(area)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedArea = value;
                _selectedPosition = null;
              });
              _fetchPositions(area: value);
            },
          ),
        if (_selectedAreaType != null) const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          value: _positionList.contains(_selectedPosition)
              ? _selectedPosition
              : null,
          decoration: const InputDecoration(
            labelText: 'Select Position',
            border: OutlineInputBorder(),
          ),
          items: [
            ..._positionList
                .map((e) => DropdownMenuItem(value: e, child: Text(e))),
            const DropdownMenuItem(value: 'Other', child: Text('Other')),
          ],
          onChanged: (value) => setState(() => _selectedPosition = value),
        ),
        const SizedBox(height: 16),
        if (_selectedPosition == 'Other')
          TextField(
            controller: _customPositionController,
            decoration: const InputDecoration(
              labelText: 'Custom Position',
              border: OutlineInputBorder(),
            ),
          ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _attemptJoin,
          icon: const Icon(Icons.send),
          label: const Text('Apply to Join'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Join a Company',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.companyId == null && _selectedCompany == null) ...[
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search Company',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (value.trim().length >= 3) {
                    _searchCompany(value);
                  } else {
                    setState(() => _searchResults.clear());
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_selectedCompany != null)
              _buildSelectedCompanyForm()
            else if (_searchResults.isNotEmpty)
              Expanded(
                child: ListView(
                  children: _searchResults.map(_buildCompanyTile).toList(),
                ),
              )
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
