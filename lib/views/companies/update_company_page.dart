// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/utils/theme_provider.dart';

import 'package:seaofsea/views/companies/company_helpers.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class UpdateCompanyPage extends StatefulWidget {
  final Map<String, dynamic> companyData;
  const UpdateCompanyPage({super.key, required this.companyData});

  @override
  State<UpdateCompanyPage> createState() => _UpdateCompanyPageState();
}

class _UpdateCompanyPageState extends State<UpdateCompanyPage> {
  final _formKey = GlobalKey<FormState>();
  late final V1ApiManager v1;

  late TextEditingController _nameCtl;
  late TextEditingController _emailCtl;

  bool _loading = true;
  String? _loadError;
  bool _fullTypeListLoaded = false;

  // Sunucudan gelen en güncel logo dosya adı (varsa)
  String? _logoFile;

  Map<String, List<Map<String, String>>> _contactInfo = {};
  List<Map<String, dynamic>> _allCompanyTypes = [];
  List<int> _selectedTypeIds = [];

  int get _companyId =>
      (widget.companyData['id'] ?? widget.companyData['company_id']) is int
          ? (widget.companyData['id'] ?? widget.companyData['company_id'])
          : int.tryParse(
                (widget.companyData['id'] ?? widget.companyData['company_id'])
                        ?.toString() ??
                    '',
              ) ??
              0;

  @override
  void initState() {
    super.initState();
    v1 = context.read<V1ApiManager>();

    _nameCtl = TextEditingController(
        text: widget.companyData['name']?.toString() ?? '');
    _emailCtl = TextEditingController(
        text: widget.companyData['email']?.toString() ?? '');

    // Eğer listeden kısmi data geldiyse bile ilk render boş kalmasın diye
    // mevcut alanları deniyoruz; asıl doldurma company.detail ile olacak.
    _primeFromIncoming(widget.companyData);

    // Sunucudan kesin ve güncel veriyi çek
    _loadDetail();
  }

  void _primeFromIncoming(Map<String, dynamic> src) {
    // contact_info
    final raw = src['contact_info'];
    try {
      dynamic decoded = (raw is String) ? jsonDecode(raw) : raw;
      _contactInfo = parseContactInfo(decoded ?? {});
    } catch (_) {
      _contactInfo = {};
    }

    // type_ids
    _selectedTypeIds =
        _parseTypeIds(src['type_ids'] ?? src['company_type_ids']);

    // logo
    final lf = src['logo']?.toString();
    if (lf != null && lf.isNotEmpty) _logoFile = lf;
  }

  List<int> _parseTypeIds(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e > 0)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final dec = jsonDecode(raw);
        if (dec is List) {
          return dec
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((e) => e > 0)
              .toList();
        }
      } catch (_) {}
    }
    return <int>[];
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final res = await v1.call(
        module: 'company',
        action: 'detail',
        params: {'id': _companyId},
        // public olabilir ama güncel veri için auth’lu çağrı da sorun olmaz
        requiresAuth: false,
      );

      if (res['success'] == true && res['data'] is Map) {
        final map = Map<String, dynamic>.from(res['data']);

        // Text controllers (varsa güncel veriyle override)
        final name = map['name']?.toString();
        final email = map['email']?.toString();
        if (name != null && name.isNotEmpty) _nameCtl.text = name;
        if (email != null && email.isNotEmpty) _emailCtl.text = email;

        // logo
        final lf = map['logo']?.toString();
        if (lf != null && lf.isNotEmpty) _logoFile = lf;

        // contact_info
        try {
          final ciRaw = map['contact_info'];
          final decoded = (ciRaw is String) ? jsonDecode(ciRaw) : ciRaw;
          _contactInfo = parseContactInfo(decoded ?? {});
        } catch (_) {
          _contactInfo = {};
        }

        // type_ids
        _selectedTypeIds =
            _parseTypeIds(map['type_ids'] ?? map['company_type_ids']);

        // ilk etapta sadece seçili tipleri getir; kullanıcı “+”a basınca tümünü çekeceğiz
        await fetchCompanyTypes(
          context: context,
          filterIds: _selectedTypeIds,
          onFetched: (list) => _allCompanyTypes = list,
        );
        _fullTypeListLoaded = false; // <— ekle

        setState(() {
          _loading = false;
          _loadError = null;
        });
      } else {
        setState(() {
          _loading = false;
          _loadError = res['message']?.toString() ?? 'Failed to load details.';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _loadError = 'Error: $e';
      });
    }
  }

  Future<void> _fetchAllTypesIfNeeded() async {
    if (_allCompanyTypes.isNotEmpty &&
        _allCompanyTypes.length >= _selectedTypeIds.length) {
      // zaten seçili tipleri ve muhtemelen daha fazlasını aldık
      return;
    }
    await fetchCompanyTypes(
      context: context,
      filterIds: const [],
      onFetched: (list) => setState(() => _allCompanyTypes = list),
    );
  }

  Future<void> _ensureAllTypesLoaded() async {
    if (_fullTypeListLoaded) return;
    await fetchCompanyTypes(
      context: context,
      filterIds: const [], // <— filtre yok: TAM LİSTE
      perPage: 1000, // <— güvenli geniş limit
      onFetched: (list) {
        setState(() {
          _allCompanyTypes = list;
          _fullTypeListLoaded = true;
        });
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final res = await v1.call(
      module: 'company',
      action: 'update',
      params: {
        'id': _companyId,
        'name': _nameCtl.text.trim(),
        'email': _emailCtl.text.trim(),
        'type_ids': _selectedTypeIds,
        'contact_info': _contactInfo,
      },
    );

    if (res['success'] == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Company updated.')));
      Navigator.pop(context, true); // detail sayfası isterse refresh edebilir
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ${res['message'] ?? 'Update failed.'}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();

    return CustomScaffold(
      title: 'Update Company',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _ErrorView(message: _loadError!, onRetry: _loadDetail)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LOGO (company_helpers.dart içindeki buildCompanyLogo görünümü)
                        buildCompanyLogo(context, _companyId, _logoFile),

                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameCtl,
                          decoration: const InputDecoration(
                            labelText: 'Company Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailCtl,
                          decoration: const InputDecoration(
                            labelText: 'Company Email',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 20),
                        // COMPANY TYPE
                        buildCompanyTypeSection(
                          _allCompanyTypes,
                          _selectedTypeIds,
                          true,
                          true,
                          () async {
                            await _ensureAllTypesLoaded(); // <— önce tam listeyi yükle
                            handleAddCompanyType(
                              context: context,
                              allTypes: _allCompanyTypes,
                              selectedIds: _selectedTypeIds,
                              onSelectedUpdated: (ids) =>
                                  setState(() => _selectedTypeIds = ids),
                            );
                          },
                        ),

                        // CONTACT INFO
                        const SizedBox(height: 12),
                        buildSectionTitle(
                            context, Icons.contact_page, 'Contact Info'),
                        const SizedBox(height: 8),
                        buildContactSection(
                          context: context,
                          userRole: 'admin', // edit ekranı
                          contactInfo: _contactInfo,
                          onAddPressed: (category) {
                            showContactDialog(
                              context: context,
                              themeProvider: themeProvider,
                              category: category,
                              contactInfo: _contactInfo,
                              onUpdate: (updated) =>
                                  setState(() => _contactInfo = updated),
                            );
                          },
                          onEditPressed: (category, item) {
                            showContactDialog(
                              context: context,
                              themeProvider: themeProvider,
                              category: category,
                              item: item,
                              contactInfo: _contactInfo,
                              onUpdate: (updated) =>
                                  setState(() => _contactInfo = updated),
                            );
                          },
                          onDeletePressed: (category, item, updated) =>
                              setState(() => _contactInfo = updated),
                          onTap: (_, __) {}, // edit ekranında dış link yok
                        ),

                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
