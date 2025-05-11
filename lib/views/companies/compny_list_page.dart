import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class CompanyListPage extends StatefulWidget {
  const CompanyListPage({super.key});

  @override
  State<CompanyListPage> createState() => _CompanyListPageState();
}

class _CompanyListPageState extends State<CompanyListPage> {
  bool _myExpanded = true;
  bool _allExpanded = false;
  List _myCompanies = [];
  List _allCompanies = [];
  int _page = 1;
  int _totalCompanies = 0;
  final String _orderBy = 'created_at';
  final String _orderDirection = 'DESC';
  final int _limit = 25;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _fetchInitialData() async {
    await _fetchMyCompanies();
    await _fetchAllCompanies(reset: true);
  }

  Future<void> _fetchMyCompanies() async {
    final api = context.read<ApiManager>();
    final response = await api.post(context, 'get_user_companies', {});
    if (response['success'] && response['data'] is List) {
      debugPrint('My Companies: ${response['data']}');
      setState(() => _myCompanies = response['data']);
    }
  }

  Future<void> _fetchAllCompanies({bool reset = false}) async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    final api = context.read<ApiManager>();

    final response = await api.post(context, 'get_companies', {
      'page': _page,
      'limit': _limit,
      'search': _searchQuery,
      'orderBy': _orderBy,
      'orderDirection': _orderDirection,
    });

    if (response['success'] == true &&
        response['data'] is Map &&
        response['data']['items'] is List) {
      final items = response['data']['items'] as List;
      final total = response['data']['pagination']?['total'] ?? 0;
      setState(() {
        if (reset) {
          _allCompanies = items;
          _page = 2;
        } else {
          _allCompanies.addAll(items);
          _page++;
        }
        _hasMore = items.length == _limit;
        _totalCompanies = total;
      });
    } else {
      debugPrint('⚠️ Unexpected response structure: $response');
    }

    setState(() => _isLoading = false);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchAllCompanies();
    }
  }

  Future<bool> _checkLogin() async {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  return auth.isLoggedIn;
}


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkLogin(),
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data == true) {
          return _buildCompanyListBody();
        } else {
          return const Center(
              child: Text('Please login to view your companies.'));
        }
      },
    );
  }

  Widget _buildCompanyListBody() {
    final api = Provider.of<ApiManager>(context, listen: false);

    return CustomScaffold(
      title: 'Companies',
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/create_company'),
                  icon: const Icon(Icons.add_business),
                  label: const Text('Create Company'),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/join_company'),
                  icon: const Icon(Icons.group_add),
                  label: const Text('Join Company'),
                ),
              ],
            ),
            const Divider(),
            ExpansionTile(
              shape: Border.all(color: Colors.transparent),
              title:
                  _buildExpansionTitle('Your Companies', _myCompanies.length),
              initiallyExpanded: _myExpanded,
              onExpansionChanged: (val) => setState(() => _myExpanded = val),
              children: _myCompanies.isEmpty
                  ? [
                      const ListTile(
                          title: Text('You don\'t have any companies'))
                    ]
                  : _myCompanies
                      .map((company) => _buildCompanyTile(context, api, company,
                          isMyCompany: true))
                      .toList(),
            ),
            const Divider(),
            ExpansionTile(
              shape: Border.all(color: Colors.transparent),
              title: _buildExpansionTitle('All Companies', _totalCompanies,
                  format: true),
              initiallyExpanded: _allExpanded,
              onExpansionChanged: (val) => setState(() => _allExpanded = val),
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search Companies...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      _searchQuery = value.trim();
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 300), () {
                        if (_searchQuery.replaceAll(' ', '').length >= 2 ||
                            _searchQuery.isEmpty) {
                          _page = 1;
                          _hasMore = true;
                          _fetchAllCompanies(reset: true);
                        }
                      });
                    },
                  ),
                ),
                const Divider(),
                ..._allCompanies
                    .map((company) => _buildCompanyTile(context, api, company))
                    // ignore: unnecessary_to_list_in_spreads
                    .toList(),
              ],
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionTitle(String title, int count, {bool format = false}) {
    return Row(
      children: [
        Text(title),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            format ? _formatNumber(count) : '$count',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyTile(BuildContext context, ApiManager api, Map company,
      {bool isMyCompany = false}) {
    final String name = company['name'] ?? 'Unnamed';
    final String createdAt = company['created_at'] ?? 'Unknown date';
    final String? role = company['role']; // sadece your companies için gelir.
    debugPrint('images/companies/logo/thumb/${company['logo']}');
    return ListTile(
      leading: Image.network(
        api.showImage(
          company['logo'] != null
              ? 'images/companies/logo/thumb/${company['logo']}'
              : 'assets/logo256.png',
          company['logo'] == null,
        ),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset('assets/logo256.png',
              width: 40, height: 40, fit: BoxFit.cover);
        },
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isMyCompany && role != null) ...[
            const SizedBox(width: 8),
            _buildRoleIcon(role),
          ],
        ],
      ),
      subtitle: Text('Created: $createdAt'),
      onTap: () {
        Navigator.pushNamed(
          context,
          '/company_detail',
          arguments: company,
        );
      },
    );
  }

  Widget _buildRoleIcon(String? role) {
    switch (role) {
      case 'admin':
        return const Icon(Icons.shield, color: Colors.blue, size: 18);
      case 'editor':
        return const Icon(Icons.edit, color: Colors.orange, size: 18);
      case 'viewer':
        return const Icon(Icons.remove_red_eye, color: Colors.green, size: 18);
      default:
        return const SizedBox.shrink();
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000 && number < 1100) {
      return '1K';
    } else if (number >= 1100 && number < 10000) {
      final main = (number / 1000).toStringAsFixed(1);
      return '${main}K';
    } else if (number >= 10000) {
      final main = (number / 1000).toStringAsFixed(0);
      return '${main}K';
    } else {
      return number.toString();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
}
