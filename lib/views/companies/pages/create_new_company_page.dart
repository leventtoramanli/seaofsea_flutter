// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/views/companies/pages/company_list_page.dart';
import 'package:seaofsea/widgets/custom_image_picker.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class CreateCompanyPage extends StatefulWidget {
  const CreateCompanyPage({super.key});

  @override
  State<CreateCompanyPage> createState() => _CreateCompanyPageState();
}

class _CreateCompanyPageState extends State<CreateCompanyPage> {
  final _v1 = V1ApiManager();

  // ---- UI State / Controllers
  File? _companyLogo;
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _rankCtl = TextEditingController();

  bool _isLoading = false;
  String? _error;

  // ---- Company Types
  List<Map<String, dynamic>> _allCompanyTypes = [];
  List<int> _selectedTypeIds = [];

  // ---- Contact info
  // format: { "phones": [{"label":"Sales","value":"+90..."}, ...], "emails":[...], ...}
  final Map<String, List<Map<String, String>>> _contactInfo = {
    'phones': [],
    'emails': [],
    'addresses': [],
    'websites': [],
  };

  @override
  void initState() {
    super.initState();
    _fetchCompanyTypes();
  }

  // ---------- Helpers ----------

  String _detectMime(File f) {
    final p = f.path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.jpg') || p.endsWith('.jpeg')) return 'image/jpeg';
    if (p.endsWith('.webp')) return 'image/webp';
    return 'application/octet-stream';
  }

  dynamic _companyIdFromData(dynamic data) {
    if (data is Map) {
      final id = data['company_id'] ?? data['id'];
      return id;
    }
    return null;
  }

  Future<void> _fetchCompanyTypes() async {
    try {
      final res = await _v1.call(
        module: 'company',
        action: 'types',
        params: {},
        requiresAuth: false, // public
      );
      if (res['success'] == true) {
        final data = res['data'];
        List items;
        if (data is List) {
          items = data;
        } else if (data is Map && data['items'] is List) {
          items = data['items'];
        } else {
          items = const [];
        }

        final safe = items
            .where((e) => e is Map && e['id'] != null && e['name'] != null)
            .cast<Map<String, dynamic>>()
            .toList();

        if (!mounted) return;
        setState(() => _allCompanyTypes = safe);
      }
    } catch (e) {
      debugPrint('❌ company.types error: $e');
    }
  }

  // ------- Contact info dialogs -------
  Future<void> _addOrEditContactItem(String category,
      {Map<String, String>? item, int? index}) async {
    final isEdit = item != null && index != null;
    final labelCtl = TextEditingController(text: item?['label'] ?? '');
    final valueCtl = TextEditingController(text: item?['value'] ?? '');

    final defs = _defsForCategory(category);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text('${isEdit ? "Edit" : "Add"} ${_titleForCategory(category)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtl,
              decoration: InputDecoration(
                labelText: defs.label,
                hintText: defs.hintLabel,
                prefixIcon: const Icon(Icons.label_outline),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: valueCtl,
              decoration: InputDecoration(
                labelText: defs.valueLabel,
                hintText: defs.hintValue,
                prefixIcon: Icon(defs.valueIcon),
                border: const OutlineInputBorder(),
              ),
              keyboardType: defs.keyboardType,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'Update' : 'Add')),
        ],
      ),
    );

    if (ok == true) {
      final label = labelCtl.text.trim();
      final value = valueCtl.text.trim();
      if (label.isEmpty || value.isEmpty) return;

      setState(() {
        _contactInfo.putIfAbsent(category, () => []);
        if (isEdit) {
          _contactInfo[category]![index!] = {'label': label, 'value': value};
        } else {
          _contactInfo[category]!.add({'label': label, 'value': value});
        }
      });
    }
  }

  void _removeContactItem(String category, int index) {
    setState(() => _contactInfo[category]?.removeAt(index));
  }

  // ---------- Submit flow ----------
  Future<void> _submitCompany() async {
    final name = _nameCtl.text.trim();
    final email = _emailCtl.text.trim();
    final rank = _rankCtl.text.trim();

    if (name.isEmpty || email.isEmpty || rank.isEmpty) {
      setState(() => _error = 'All fields are required.');
      return;
    }
    if (!EmailValidator.validate(email)) {
      setState(() => _error = 'Email is not valid.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1) Create
      final createRes = await _v1.call(
        module: 'company',
        action: 'create',
        params: {
          'name': name,
          'email': email,
        },
        requiresAuth: true,
        context: context,
      );

      if (createRes['success'] != true) {
        setState(() => _error =
            createRes['message']?.toString() ?? 'Company creation failed.');
        return;
      }

      final companyId = _companyIdFromData(createRes['data'])?.toString();
      if (companyId == null || companyId.isEmpty) {
        setState(() => _error = 'Company ID not returned from API.');
        return;
      }

      // 2) Add current user as admin (with rank)
      final addMemberRes = await _v1.call(
        module: 'company',
        action: 'add_member',
        params: {
          'company_id': companyId,
          'role': 'admin',
          'rank': rank,
        },
        requiresAuth: true,
        context: context,
      );

      if (addMemberRes['success'] != true) {
        // optional rollback
        await _v1.call(
          module: 'company',
          action: 'delete',
          params: {'company_id': companyId},
          requiresAuth: true,
          context: context,
        );
        setState(() => _error = addMemberRes['message']?.toString() ??
            'Failed to link user to company.');
        return;
      }

      // 3) Update optional: type_ids + contact_info
      final bool hasTypes = _selectedTypeIds.isNotEmpty;
      final bool hasContactInfo = _contactInfo.values.any((l) => l.isNotEmpty);

      if (hasTypes || hasContactInfo) {
        final updateParams = {
          'id': companyId,
          if (hasTypes) 'type_ids': _selectedTypeIds,
          if (hasContactInfo) 'contact_info': _contactInfo,
        };

        final updateRes = await _v1.call(
          module: 'company',
          action: 'update',
          params: updateParams,
          requiresAuth: true,
          context: context,
        );

        if (updateRes['success'] != true) {
          debugPrint(
              '⚠️ company.update (types/contact) failed: ${updateRes['message']}');
        }
      }

      // 4) Upload logo (optional)
      if (_companyLogo != null) {
        final uploadRes = await _v1.call(
          module: 'company',
          action: 'upload_logo',
          params: {'company_id': companyId, 'thumb': true, 'thumbSize': 128},
          file: _companyLogo,
          fileType: _detectMime(_companyLogo!),
          fileName: _companyLogo!.path.split('/').last,
          requiresAuth: true,
          context: context,
        );
        if (uploadRes['success'] != true) {
          debugPrint('⚠️ Logo upload failed: ${uploadRes['message']}');
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company created successfully.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CompanyListPage()),
      );
    } catch (e) {
      debugPrint('❌ Error during company creation: $e');
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;

    return CustomScaffold(
      title: 'Create Company',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Logo
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Company Logo'),
                  const SizedBox(height: 8),
                  Container(
                    width: 102,
                    height: 102,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CustomImagePicker(
                      aspectRatio: 1,
                      deleteOld: true,
                      addWatermark: true,
                      onImagePicked: (file, _) =>
                          setState(() => _companyLogo = file),
                      meta: const {'type': 'company'},
                      iwidth: 100,
                      iheight: 100,
                      iradius: 0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: gap),

            // Basic info
            _buildTextField(_nameCtl, 'Company Name'),
            const SizedBox(height: gap),
            _buildTextField(_emailCtl, 'Company E-Mail',
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: gap),
            _buildTextField(_rankCtl, 'Your Rank'),

            const SizedBox(height: 16),

            // Company Types (multi-select)
            _buildCompanyTypes(),

            const SizedBox(height: 16),

            // Contact info editor
            _buildContactEditor(),

            if (_error != null) ...[
              const SizedBox(height: gap),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),

            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _submitCompany,
                    icon: const Icon(Icons.check),
                    label: const Text('Save Company'),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildCompanyTypes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Company Type', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownSearch<Map<String, dynamic>>.multiSelection(
          items: _allCompanyTypes,
          selectedItems: _selectedTypeIds
              .map((id) => _allCompanyTypes.firstWhere(
                    (t) => t['id'] == id,
                    orElse: () => {},
                  ))
              .where((e) => e.isNotEmpty)
              .toList(),
          itemAsString: (item) => item['name'] ?? 'Unnamed',
          compareFn: (a, b) => a['id'] == b['id'],
          popupProps: const PopupPropsMultiSelection.menu(
            showSearchBox: true,
          ),
          onChanged: (selected) {
            setState(() => _selectedTypeIds =
                selected.map<int>((e) => e['id'] as int).toList());
          },
          dropdownDecoratorProps: const DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: 'Select types',
              contentPadding: EdgeInsets.all(12),
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contact Info', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _contactCategory('phones'),
        const SizedBox(height: 8),
        _contactCategory('emails'),
        const SizedBox(height: 8),
        _contactCategory('addresses'),
        const SizedBox(height: 8),
        _contactCategory('websites'),
      ],
    );
  }

  Widget _contactCategory(String category) {
    final items = _contactInfo[category] ?? [];
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: Column(
          children: [
            Row(
              children: [
                Icon(_iconForCategory(category), size: 18),
                const SizedBox(width: 8),
                Text(_titleForCategory(category),
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _addOrEditContactItem(category),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 8, top: 4),
                child: Text(
                  'No $category added.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              ...List.generate(items.length, (i) {
                final it = items[i];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.drag_indicator, size: 18),
                  title: Text(it['label'] ?? ''),
                  subtitle: Text(it['value'] ?? ''),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _addOrEditContactItem(
                          category,
                          item: it,
                          index: i,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: () => _removeContactItem(category, i),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ----- tiny helpers for contact defs -----
  _FieldDefs _defsForCategory(String c) {
    switch (c) {
      case 'phones':
        return const _FieldDefs(
          label: 'Label',
          hintLabel: 'e.g. Sales',
          valueLabel: 'Phone',
          hintValue: '+90 555 555 55 55',
          valueIcon: Icons.phone,
          keyboardType: TextInputType.phone,
        );
      case 'emails':
        return const _FieldDefs(
          label: 'Label',
          hintLabel: 'e.g. Support',
          valueLabel: 'E-mail',
          hintValue: 'info@company.com',
          valueIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        );
      case 'addresses':
        return const _FieldDefs(
          label: 'Label',
          hintLabel: 'e.g. HQ',
          valueLabel: 'Address',
          hintValue: 'Street, City, Country',
          valueIcon: Icons.location_on_outlined,
          keyboardType: TextInputType.streetAddress,
        );
      case 'websites':
        return const _FieldDefs(
          label: 'Label',
          hintLabel: 'e.g. Main',
          valueLabel: 'URL',
          hintValue: 'https://example.com',
          valueIcon: Icons.language_outlined,
          keyboardType: TextInputType.url,
        );
      default:
        return const _FieldDefs(
          label: 'Label',
          hintLabel: '',
          valueLabel: 'Value',
          hintValue: '',
          valueIcon: Icons.info_outline,
          keyboardType: TextInputType.text,
        );
    }
  }

  IconData _iconForCategory(String c) {
    switch (c) {
      case 'phones':
        return Icons.phone;
      case 'emails':
        return Icons.email_outlined;
      case 'addresses':
        return Icons.location_on_outlined;
      case 'websites':
        return Icons.language_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _titleForCategory(String c) {
    switch (c) {
      case 'phones':
        return 'Phones';
      case 'emails':
        return 'E-mails';
      case 'addresses':
        return 'Addresses';
      case 'websites':
        return 'Websites';
      default:
        return c;
    }
  }
}

class _FieldDefs {
  final String label;
  final String hintLabel;
  final String valueLabel;
  final String hintValue;
  final IconData valueIcon;
  final TextInputType keyboardType;
  const _FieldDefs({
    required this.label,
    required this.hintLabel,
    required this.valueLabel,
    required this.hintValue,
    required this.valueIcon,
    required this.keyboardType,
  });
}
