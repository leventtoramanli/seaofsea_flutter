// join_company_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class JoinCompanyPage extends StatefulWidget {
  final int? companyId;

  const JoinCompanyPage({super.key, this.companyId});

  @override
  State<JoinCompanyPage> createState() => _JoinCompanyPageState();
}

class _JoinCompanyPageState extends State<JoinCompanyPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customRankController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  List<int> _joinedCompanyIds = [];
  Map<String, dynamic>? _selectedCompany;
  String _selectedRank = 'Crew';

  final List<String> _availableRanks = [
    'Crew',
    'Engineer',
    'Captain',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadJoinedCompanies();
    if (widget.companyId != null) {
      _fetchCompanyById(widget.companyId!);
    }
  }

  Future<void> _loadJoinedCompanies() async {
    final api = Provider.of<ApiManager>(context, listen: false);
    final res = await api.post(context, 'get_user_companies', {});
    if (res['success'] == true && res['data'] is List) {
      final companies = res['data'] as List;
      setState(() {
        _joinedCompanyIds = companies.map((e) => e['id'] as int).toList();
      });
    }
  }

  Future<void> _fetchCompanyById(int id) async {
    final api = Provider.of<ApiManager>(context, listen: false);
    final response = await api.post(context, 'get_company_detail', {
      'company_id': id,
    });

    if (response['success'] == true && response['data'] != null) {
      setState(() {
        _selectedCompany = response['data'];
      });
    } else {
      setState(() {
        _error = 'Company not found.';
      });
    }
  }

  Future<void> _attemptJoin() async {
    if (_selectedCompany == null) return;
    final api = Provider.of<ApiManager>(context, listen: false);
    final response = await api.post(context, 'create_user_company', {
      'company_id': _selectedCompany!['id'].toString(),
      'role': 'employee',
      'rank': _selectedRank == 'Other'
          ? _customRankController.text.trim()
          : _selectedRank,
    });

    if (response['success'] == true) {
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() {
        _error = response['message'] ?? 'Failed to join company.';
      });
    }
  }

  Future<void> _searchCompany(String query) async {
    if (query.trim().length < 3) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final api = Provider.of<ApiManager>(context, listen: false);
    final response = await api.post(context, 'get_companies', {
      'search': query.trim(),
      'limit': 10,
    });

    if (response['success'] == true && response['data']?['items'] is List) {
      final List items = response['data']['items'];
      final List<Map<String, dynamic>> companies =
          items.cast<Map<String, dynamic>>();

      _searchResults = companies.map((company) {
        final isMember = _joinedCompanyIds.contains(company['id']);
        return {...company, 'is_member': isMember};
      }).toList();
    } else {
      _error = 'No companies found.';
      _searchResults.clear();
    }

    setState(() => _isLoading = false);
  }

  Widget _buildCompanyTile(Map<String, dynamic> company) {
    final bool isMember = company['is_member'] == true;

    return ListTile(
      leading: const Icon(Icons.business),
      title: Text(company['name'] ?? 'Unnamed'),
      subtitle: Text(company['email'] ?? ''),
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
          title: Text(_selectedCompany!['name'] ?? 'Unnamed'),
          subtitle: Text(_selectedCompany!['email'] ?? ''),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _availableRanks.contains(_selectedRank) ? _selectedRank : 'Other',
          decoration: const InputDecoration(
            labelText: 'Select Position',
            border: OutlineInputBorder(),
          ),
          items: _availableRanks.map((rank) {
            return DropdownMenuItem(
              value: rank,
              child: Text(rank),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedRank = value ?? 'Other');
          },
        ),
        const SizedBox(height: 16),
        if (_selectedRank == 'Other')
          TextField(
            controller: _customRankController,
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