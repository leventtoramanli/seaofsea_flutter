// views/companies/company_admin_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/services/v1/v1_config.dart';
import 'package:seaofsea/views/companies/company_detail_page.dart';

class CompanyAdminPage extends StatefulWidget {
  const CompanyAdminPage({super.key});

  @override
  State<CompanyAdminPage> createState() => _CompanyAdminPageState();
}

class _CompanyAdminPageState extends State<CompanyAdminPage> {
  late Future<List<Map<String, dynamic>>> _future;
  bool _didAutoNavigate = false;

  @override
  void initState() {
    super.initState();
    _future = _fetchAdminCompanies();
  }

  Future<List<Map<String, dynamic>>> _fetchAdminCompanies() async {
    final v1 = context.read<V1ApiManager>();
    final res = await v1.call(
      module: 'company',
      action: 'my_list',
      params: {},
      context: context,
    );

    if (res['success'] != true) return <Map<String, dynamic>>[];

    final data = res['data'];
    final raw = (data is Map && data['items'] is List) ? data['items'] as List : const [];

    // Sadece admin/editor olanları al
    final items = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).where((c) {
      final role = (c['role'] ?? '').toString().toLowerCase();
      return role == 'admin' || role == 'editor';
    }).map((c) {
      // Detay sayfasına uygun normalize
      return {
        'id': c['company_id'] ?? c['id'],
        'company_id': c['company_id'] ?? c['id'],
        'name': c['name'],
        'logo': c['logo'],
        'role': c['role'],
        'status': c['status'],
        // gerekiyorsa burada başka alanları da taşıyabilirsin
      };
    }).toList();

    return items;
  }

  Future<void> _reload() async {
    setState(() {
      _future = _fetchAdminCompanies();
      _didAutoNavigate = false;
    });
  }

  void _navigateToCompany(Map<String, dynamic> company) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyDetailPage(companyData: company),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Bir hata oluştu.'),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _reload,
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        final companies = snap.data ?? <Map<String, dynamic>>[];
        if (companies.isEmpty) {
          return const Center(child: Text('Admin/Editör olduğunuz bir şirket yok.'));
        }

        // Otomatik yönlendirme: pending olmayan tek şirket varsa
        final active = companies.where((c) => (c['status'] ?? '').toString().toLowerCase() != 'pending').toList();
        if (!_didAutoNavigate && active.length == 1) {
          _didAutoNavigate = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _navigateToCompany(active.first);
          });
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: companies.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = companies[i];
              final isPending = (c['status'] ?? '').toString().toLowerCase() == 'pending';
              final name = (c['name'] ?? 'No name').toString();
              final logo = (c['logo'] ?? '').toString();

              return ListTile(
                leading: _CompanyLeading(logo: logo, name: name, isPending: isPending),
                title: Text(name),
                subtitle: Text(isPending ? 'Role: ${c['role']} (Pending)' : 'Role: ${c['role']}'),
                trailing: isPending ? const Icon(Icons.lock_clock) : const Icon(Icons.chevron_right),
                onTap: isPending ? null : () => _navigateToCompany(c),
              );
            },
          ),
        );
      },
    );
  }
}

class _CompanyLeading extends StatelessWidget {
  final String logo;
  final String name;
  final bool isPending;
  const _CompanyLeading({required this.logo, required this.name, required this.isPending});

  @override
  Widget build(BuildContext context) {
    final radius = 20.0;

    if (logo.isNotEmpty) {
      final url = '${V1Config.baseUrl}uploads/images/companies/logo/$logo';
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackAvatar(radius),
        ),
      );
    }
    return _fallbackAvatar(radius);
  }

  Widget _fallbackAvatar(double r) {
    final initials = _initials(name);
    return CircleAvatar(
      radius: r,
      backgroundColor: isPending ? Colors.orange[100] : Colors.blueGrey[50],
      child: Text(
        initials,
        style: TextStyle(
          color: isPending ? Colors.orange[800] : Colors.blueGrey[700],
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }
}
