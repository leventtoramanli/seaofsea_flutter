// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/utils/permission_gate.dart';
import 'package:seaofsea/utils/theme_provider.dart';
import 'package:seaofsea/views/companies/contact_field_definitions.dart';
import 'package:seaofsea/widgets/custom_form_field.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';
import 'package:seaofsea/widgets/online_images.dart';
import 'package:url_launcher/url_launcher.dart';

class CompanyShowcasePage extends StatefulWidget {
  final Map<String, dynamic> companyData;

  const CompanyShowcasePage({super.key, required this.companyData});

  @override
  State<CompanyShowcasePage> createState() => _CompanyShowcasePageState();
}

class _CompanyShowcasePageState extends State<CompanyShowcasePage> {
  bool _isLoadingRole = true;
  late Map<String, List<Map<String, String>>> _contactInfo;
  String? _userRole;

  bool get isAdmin => _userRole == 'admin';
  bool get isEditor => _userRole == 'editor';
  bool get isViewer => _userRole == 'viewer';
  bool get isFollower => _userRole == 'follower';
  bool get isEmployee => isAdmin || isEditor || isViewer;
  List<Map<String, dynamic>> _allCompanyTypes = [];
  List<int> _selectedCompanyTypeIds = [];

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _fetchCompanyDetails();
    _fetchCompanyTypes(fetchAll: false);
    final types = widget.companyData['company_type_ids'];
    if (types != null && types is List) {
      _selectedCompanyTypeIds = List<int>.from(types);
    }
    final rawContactInfo = widget.companyData['contact_info'];
    try {
      dynamic decoded;
      if (rawContactInfo == null || rawContactInfo.toString().isEmpty) {
        decoded = {};
      } else {
        decoded = rawContactInfo is String
            ? jsonDecode(rawContactInfo)
            : rawContactInfo;
      }

      _contactInfo = _parseContactInfo(decoded);
      debugPrint('✅ Parsed contact_info: ${jsonEncode(_contactInfo)}');
    } catch (e) {
      debugPrint('❌ Contact info parse error: $e');
      _contactInfo = {};
    }
  }

  Future<void> _fetchCompanyDetails() async {
    final api = context.read<ApiManager>();
    final companyId = widget.companyData['id'];

    final response = await api.post(context, 'get_company_detail', {
      'company_id': companyId,
    });

    if (response['success'] == true && response['data'] is Map) {
      final fullData = response['data'];

      try {
        final decodedContactInfo = fullData['contact_info'] is String
            ? jsonDecode(fullData['contact_info'])
            : fullData['contact_info'] ?? {};

        setState(() {
          _contactInfo = _parseContactInfo(decodedContactInfo);
          final rawTypes = fullData['company_type_ids'];
          List<int> parsedTypes = [];

          if (rawTypes != null) {
            if (rawTypes is String) {
              try {
                final decoded = jsonDecode(rawTypes);
                if (decoded is List) {
                  parsedTypes = decoded
                      .map<int>((e) => int.tryParse(e.toString()) ?? 0)
                      .where((e) => e > 0)
                      .toList();
                }
              } catch (e) {
                debugPrint('❌ Failed to decode company_type_ids string: $e');
              }
            } else if (rawTypes is List) {
              parsedTypes = rawTypes
                  .map<int>((e) => int.tryParse(e.toString()) ?? 0)
                  .where((e) => e > 0)
                  .toList();
            }
          }

          setState(() {
            _selectedCompanyTypeIds = parsedTypes;
          });
        });
        debugPrint('📦 Company detail fetched: ${jsonEncode(_contactInfo)}');
      } catch (e) {
        debugPrint('❌ contact_info parse error: $e');
      }
    } else {
      debugPrint('❌ Failed to fetch full company data');
    }
  }

  Map<String, List<Map<String, String>>> _parseContactInfo(
      dynamic contactInfoRaw) {
    if (contactInfoRaw == null || contactInfoRaw is! Map) return {};

    final Map<String, List<Map<String, String>>> parsed = {};

    for (final entry in contactInfoRaw.entries) {
      final key = entry.key.toString();
      final valueList = entry.value;
      if (valueList is List) {
        parsed[key] = valueList.map<Map<String, String>>((item) {
          return {
            'label': item['label']?.toString() ?? '',
            'value': item['value']?.toString() ?? '',
          };
        }).toList();
      }
    }

    return parsed;
  }

  Future<void> _fetchUserRole() async {
    final api = context.read<ApiManager>();

    final response = await api.post(context, 'get_user_company_role', {
      'company_id': widget.companyData['id'],
    });

    if (response['success'] == true && response['data']?['role'] != null) {
      setState(() {
        _userRole = response['data']['role'];
        _isLoadingRole = false;
      });
    } else {
      setState(() {
        _userRole = 'none';
        _isLoadingRole = false;
      });
    }
  }

  Future<void> _showContactDialog({
    required String category,
    Map<String, String>? item,
  }) async {
    final themeProvider = context.read<ThemeProvider>();
    final def = contactFieldDefinitions[category] ?? {};

    final labelController = TextEditingController(text: item?['label'] ?? '');
    final valueController = TextEditingController(text: item?['value'] ?? '');

    final isEditMode = item != null;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '${isEditMode ? "Edit" : "Add"} ${category[0].toUpperCase()}${category.substring(1)}',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomFormField(
                controller: labelController,
                label: def['label'] ?? 'Label',
                hint: def['hint'] ?? '',
                icon: def['icon'] ?? const Icon(Icons.label),
                validationMessage: 'Label cannot be empty',
                maxLines: 1,
                themeProvider: themeProvider,
              ),
              const SizedBox(height: 12),
              CustomFormField(
                controller: valueController,
                label: def['valueLabel'] ?? 'Value',
                hint: def['valueHint'] ?? '',
                icon: def['valueIcon'] ?? const Icon(Icons.info),
                validationMessage: 'Value cannot be empty',
                isEmail: def['isEmail'] ?? false,
                isPhone: def['isPhone'] ?? false,
                isNumeric: def['isNumeric'] ?? false,
                isUrl: def['isUrl'] ?? false,
                maxLines: def['maxLines'] ?? 1,
                themeProvider: themeProvider,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final label = labelController.text.trim();
                final value = valueController.text.trim();
                if (label.isNotEmpty && value.isNotEmpty) {
                  setState(() {
                    if (isEditMode) {
                      final index = _contactInfo[category]?.indexOf(item);
                      if (index != null && index != -1) {
                        _contactInfo[category]?[index] = {
                          'label': label,
                          'value': value,
                        };
                      }
                    } else {
                      _contactInfo
                          .putIfAbsent(category, () => [])
                          .add({'label': label, 'value': value});
                    }
                  });
                  _updateContactInfoOnServer();
                  Navigator.pop(context);
                }
              },
              child: Text(isEditMode ? 'Update' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'phones':
        return Icons.phone;
      case 'emails':
        return Icons.email;
      case 'addresses':
        return Icons.location_on;
      case 'websites':
        return Icons.language;
      default:
        return Icons.info_outline;
    }
  }

  void _deleteContactItem(String category, Map<String, String> item) {
    setState(() {
      _contactInfo[category]?.remove(item);
    });
    _updateContactInfoOnServer();
  }

  Widget _buildCompanyTypeSection() {
    // Eşleşmiş türleri getir ve isme göre sırala
    final sortedChips = _selectedCompanyTypeIds
        .map((id) => _allCompanyTypes.firstWhere(
              (type) => type['id'] == id,
              orElse: () => {'id': id, 'name': 'Unknown', 'description': ''},
            ))
        .toList()
      ..sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.business, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Company Type:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (isAdmin || isEditor)
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Add Company Type',
                onPressed: _handleAddCompanyType,
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (_selectedCompanyTypeIds.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 28),
            child: Text('Not specified'),
          )
        else
          Wrap(
            spacing: 8,
            children: sortedChips.map((matched) {
              return Tooltip(
                message: matched['description'] ?? '',
                child: Chip(
                  label: Text(matched['name'] ?? 'Unknown'),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _handleAddCompanyType() async {
    if (_allCompanyTypes.isEmpty) {
      await _fetchCompanyTypes(fetchAll: true);
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Company Types'),
          content: SizedBox(
            width: 400,
            child: DropdownSearch<Map<String, dynamic>>.multiSelection(
              items: _allCompanyTypes,
              selectedItems: _selectedCompanyTypeIds
                  .map((id) => _allCompanyTypes
                      .firstWhere((type) => type['id'] == id, orElse: () => {}))
                  .where((e) => e.isNotEmpty)
                  .toList(),
              itemAsString: (item) => item['name'] ?? 'Unnamed',
              compareFn: (item, selectedItem) =>
                  item['id'] == selectedItem['id'],
              popupProps: const PopupPropsMultiSelection.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    labelText: 'Search',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                showSelectedItems: true,
              ),
              onChanged: (selected) {
                setState(() {
                  _selectedCompanyTypeIds =
                      selected.map((e) => e['id'] as int).toList();
                });
              },
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Company Types',
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateCompanyTypesOnServer();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateCompanyTypesOnServer() async {
    final api = context.read<ApiManager>();
    final companyId = widget.companyData['id'];

    final response = await api.post(context, 'update_company', {
      'company_id': companyId,
      'company_type_ids': _selectedCompanyTypeIds,
    });

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company types updated successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ${response['message'] ?? 'Update failed.'}')),
      );
    }
  }

  Future<void> _fetchCompanyTypes({bool fetchAll = false}) async {
    final api = context.read<ApiManager>();
    final Map<String, dynamic> requestData = {};

    if (!fetchAll && _selectedCompanyTypeIds.isNotEmpty) {
      requestData['filter_ids'] = _selectedCompanyTypeIds;
    }

    try {
      final response =
          await api.post(context, 'get_company_types', requestData);
      debugPrint('Company Types: ${response['data']}');

      if (response['success'] == true && response['data'] is List) {
        final items = response['data'] as List;
        final safeList = items
            .where((e) => e is Map && e['id'] != null && e['name'] != null)
            .cast<Map<String, dynamic>>()
            .toList();

        setState(() {
          _allCompanyTypes = safeList;
        });

        if (safeList.isEmpty) {
          debugPrint('ℹ️ No company types found.');
        }
      } else {
        debugPrint('❌ Invalid or missing data in company types response.');
        setState(() {
          _allCompanyTypes = [];
        });
      }
    } catch (e) {
      debugPrint('❌ Exception while fetching company types: $e');
      setState(() {
        _allCompanyTypes = [];
      });
    }
  }

  Future<void> _updateContactInfoOnServer() async {
    final api = context.read<ApiManager>();
    final companyId = widget.companyData['id'];

    final response = await api.post(context, 'update_company', {
      'company_id': companyId,
      'contact_info': _contactInfo,
    });

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact info updated successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update contact info.')),
      );
    }
  }

  Future<void> _showModalC(
      BuildContext context, String endpoint, String title) async {
    final api = context.read<ApiManager>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FutureBuilder(
          future: api.post(context, endpoint, {
            'company_id': widget.companyData['id'],
          }),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('Error loading data.')),
              );
            } else if (snapshot.hasData &&
                snapshot.data is Map<String, dynamic>) {
              final data = snapshot.data as Map<String, dynamic>;
              final items = data['data'] ?? [];
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('No have any followers.')),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(title,
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  Divider(),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final user = items[index];
                        final hasProfileImage = user['user_image'] != null &&
                            user['user_image'].toString().isNotEmpty;

                        return ListTile(
                          leading: hasProfileImage
                              ? OnlineImage(
                                  imagePath: 'images/user/user/',
                                  imageName: user['user_image'],
                                  sizeW: 40,
                                  rounded: true,
                                  border: true,
                                )
                              : const Icon(Icons.person),
                          title: Text(
                            '${user['name'] ?? ''} ${user['surname'] ?? ''}'
                                    .trim()
                                    .isEmpty
                                ? 'Unnamed'
                                : '${user['name'] ?? ''} ${user['surname'] ?? ''}'
                                    .trim(),
                          ),
                          subtitle: Text(user['rank'] ?? '-'),
                        );
                      },
                    ),
                  ),
                ],
              );
            } else {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('Unexpected error.')),
              );
            }
          },
        );
      },
    );
  }

  void _showPhoneOptions(String phoneNumber) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (Platform.isAndroid || Platform.isIOS)
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Call'),
                  onTap: () async {
                    final uri = Uri(scheme: 'tel', path: phoneNumber);
                    try {
                      await launchUrl(uri);
                    } catch (e) {
                      debugPrint('❌ Launch failed: $e');
                    }
                    Navigator.pop(context);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: phoneNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Phone number copied')),
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;
    final bool isTablet = MediaQuery.of(context).size.width > 600 && !isDesktop;

    if (_isLoadingRole || _userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return CustomScaffold(
      title: widget.companyData['name'] ?? 'Company Name',
      floatingActionButton: _buildBadges(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, isDesktop, isTablet),
            const SizedBox(height: 24),
            const Divider(),
            _buildCompanyTypeSection(),
            const SizedBox(height: 24),
            const Divider(),
            _buildSectionTitle(context, Icons.contact_phone, 'Contact Info'),
            const SizedBox(height: 8),
            _buildContactSection(),
            const SizedBox(height: 24),
            const Divider(),
          ],
        ),
      ),
    );
  }

  Future<void> _handleContactTap(String category, String value) async {
    Uri? uri;

    switch (category) {
      case 'phones':
        // Bu durumda _showPhoneOptions çağrılıyor (zaten tanımlı)
        _showPhoneOptions(value);
        return;

      case 'emails':
        uri = Uri(scheme: 'mailto', path: value);
        break;

      case 'websites':
        uri = Uri.parse(value.startsWith('http') ? value : 'https://$value');
        debugPrint('📦 Launching $uri');
        break;

      case 'addresses':
        final query =
            value.replaceAll('.', '').trim().replaceAll(RegExp(r'\s+'), '+');
        uri = Uri.parse('https://yandex.com/maps/?text=$query');
        debugPrint('📦 Launching $query');
        break;

      default:
        return;
    }

    try {
      await _launchDirectly(uri.toString());
    } catch (e) {
      debugPrint('❌ Failed to launch $uri: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open $category')),
      );
    }
  }

  Future<void> _launchDirectly(String url) async {
    try {
      if (Platform.isWindows) {
        await Process.run('start', [url], runInShell: true);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      } else if (Platform.isAndroid || Platform.isIOS) {
        final uri = Uri.parse(url);
        if (!await launchUrl(uri)) {
          throw Exception('Could not launch $url');
        }
      } else {
        throw UnsupportedError('Platform not supported');
      }
    } catch (e) {
      debugPrint('❌ Launch failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link')),
      );
    }
  }

  Widget _buildContactSection() {
    final allCategories = ['phones', 'emails', 'addresses', 'websites'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: allCategories.map((category) {
        final items = _contactInfo[category] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getIconForCategory(category), size: 18),
                const SizedBox(width: 8),
                Text(
                  category[0].toUpperCase() + category.substring(1),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_userRole == 'admin' || _userRole == 'editor')
                  GestureDetector(
                    onTap: () => _showContactDialog(category: category),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.add_circle, size: 20),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 32),
                child: Text('-'),
              )
            else
              ...items.map((item) {
                final label = item['label'] ?? '';
                final value = item['value'] ?? '';
                final isPhone = category == 'phones';
                final displayValue = isPhone
                    ? (value.startsWith('+') ? value : '+$value')
                    : value;

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(label),
                  subtitle: GestureDetector(
                    onTap: () => _handleContactTap(category, displayValue),
                    child: Text(
                      displayValue,
                      style: const TextStyle(
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  trailing: (_userRole == 'admin' || _userRole == 'editor')
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showContactDialog(
                                category: category,
                                item: item,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () =>
                                  _deleteContactItem(category, item),
                            ),
                          ],
                        )
                      : null,
                );
              }),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop, bool isTablet) {
    final hasLogo = widget.companyData['logo'] != null &&
        widget.companyData['logo'].toString().isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        hasLogo
            ? OnlineImage(
                imagePath: 'images/companies/logo/thumb/',
                imageName: widget.companyData['logo'],
                sizeW: 80,
                rounded: true,
                border: true,
              )
            : CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[300],
                child:
                    const Icon(Icons.business, size: 40, color: Colors.white),
              ),
        Column(
          children: [
            if ((isDesktop || isTablet) && (isAdmin || isEditor))
              _buildAdminButtons(),
            const SizedBox(height: 5),
            _buildActionButtons(context),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminButtons() {
    final companyId = widget.companyData['id'] as int;

    return Row(
      children: [
        PermissionGate(
          permissionCode: 'company.update',
          entityId: companyId,
          child: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(
              context,
              '/update_company',
              arguments: widget.companyData,
            ),
            tooltip: 'Edit Company',
          ),
        ),
        PermissionGate(
          permissionCode: 'company.view_members',
          entityId: companyId,
          child: IconButton(
            icon: const Icon(Icons.group),
            onPressed: () => Navigator.pushNamed(
              context,
              '/manage_company_users',
              arguments: widget.companyData,
            ),
            tooltip: 'Manage Users',
          ),
        ),
        PermissionGate(
          permissionCode: 'company.settings',
          entityId: companyId,
          child: IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(
              context,
              '/company_settings',
              arguments: widget.companyData,
            ),
            tooltip: 'Company Settings',
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isViewer || isFollower)
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.work_outline),
            label: const Text('Apply for a Job'),
          ),
        if (isEmployee)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.meeting_room),
              label: const Text('Enter Workspace'),
            ),
          ),
      ],
    );
  }

  Widget _buildBadges() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'followersBadge',
          onPressed: () =>
              _showModalC(context, 'get_company_followers', 'Followers'),
          child: const Icon(Icons.group),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'employeesBadge',
          onPressed: () =>
              _showModalC(context, 'get_company_employees', 'Employees'),
          child: const Icon(Icons.engineering),
        ),
      ],
    );
  }
}
