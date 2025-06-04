// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/utils/theme_provider.dart';
import 'package:seaofsea/views/companies/company_contact_info.dart';
import 'package:seaofsea/views/companies/company_dashboard.dart';
import 'package:seaofsea/views/companies/company_helpers.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';
import 'package:seaofsea/widgets/online_images.dart';

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
  int _currentPageIndex = 0;

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

      _contactInfo = parseContactInfo(decoded);
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
          _contactInfo = parseContactInfo(decodedContactInfo);
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

  void _handleAddCompanyType() async {
    if (_allCompanyTypes.isEmpty) {
      await _fetchCompanyTypes(fetchAll: true);
    }
    handleAddCompanyType(
      context: context,
      allTypes: _allCompanyTypes,
      selectedIds: _selectedCompanyTypeIds,
      onSelectedUpdated: (updatedIds) {
        setState(() {
          _selectedCompanyTypeIds = updatedIds;
        });
        updateCompanyTypesOnServer(
          context,
          updatedIds,
          widget.companyData['id'],
        );
      },
    );
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
                          title: SelectableText(
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

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;
    final bool isTablet = MediaQuery.of(context).size.width > 600 && !isDesktop;
    if (_isLoadingRole || _userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool isAdminOrEditor = isAdmin || isEditor;

    return CustomScaffold(
      title: widget.companyData['name'] ?? 'Company Name',
      floatingActionButton: _buildBadges(),
      body: isAdminOrEditor
          ? IndexedStack(
              index: _currentPageIndex,
              children: [
                CompanyDashboard(
                  goToContactInfo: () {
                    setState(() => _currentPageIndex = 1);
                  },
                  companyId: widget.companyData['id'],
                ),
                CompanyContactInfo(
                  header: buildHeader(
                    context: context,
                    isDesktop: isDesktop,
                    isTablet: isTablet,
                    isAdmin: isAdmin,
                    isEditor: isEditor,
                    companyId: widget.companyData['id'],
                    logo: widget.companyData['logo'],
                    adminButtons: buildAdminButtons(
                        context, widget.companyData['id'], widget.companyData),
                    actionButtons: buildActionButtons(
                      context,
                      isViewer,
                      isFollower,
                      isEmployee,
                      widget.companyData['id'],
                    ),
                  ),
                  companyTypeSection: buildCompanyTypeSection(
                    _allCompanyTypes,
                    _selectedCompanyTypeIds,
                    isAdmin,
                    isEditor,
                    _handleAddCompanyType,
                  ),
                  contactSection: buildContactSection(
                    context: context,
                    userRole: _userRole!,
                    contactInfo: _contactInfo,
                    onAddPressed: (category) {
                      showContactDialog(
                        context: context,
                        themeProvider: context.read<ThemeProvider>(),
                        category: category,
                        contactInfo: _contactInfo,
                        onUpdate: (updatedInfo) {
                          setState(() => _contactInfo = updatedInfo);
                          updateContactInfoOnServer(
                            context: context,
                            companyId: widget.companyData['id'],
                            contactInfo: updatedInfo,
                          );
                        },
                      );
                    },
                    onEditPressed: (category, item) {
                      showContactDialog(
                        context: context,
                        themeProvider: context.read<ThemeProvider>(),
                        category: category,
                        item: item,
                        contactInfo: _contactInfo,
                        onUpdate: (updatedInfo) {
                          setState(() => _contactInfo = updatedInfo);
                          updateContactInfoOnServer(
                            context: context,
                            companyId: widget.companyData['id'],
                            contactInfo: updatedInfo,
                          );
                        },
                      );
                    },
                    onDeletePressed: (category, item, updatedInfo) {
                      setState(() => _contactInfo = updatedInfo);
                      updateContactInfoOnServer(
                        context: context,
                        companyId: widget.companyData['id'],
                        contactInfo: updatedInfo,
                      );
                    },
                    onTap: (category, value) =>
                        _handleContactTap(category, value),
                  ),
                ),
              ],
            )
          : CompanyContactInfo(
              header: buildHeader(
                context: context,
                isDesktop: isDesktop,
                isTablet: isTablet,
                isAdmin: isAdmin,
                isEditor: isEditor,
                companyId: widget.companyData['id'],
                logo: widget.companyData['logo'],
                adminButtons: buildAdminButtons(
                    context, widget.companyData['id'], widget.companyData),
                actionButtons: buildActionButtons(
                  context,
                  isViewer,
                  isFollower,
                  isEmployee,
                  widget.companyData['id'],
                ),
              ),
              companyTypeSection: buildCompanyTypeSection(
                _allCompanyTypes,
                _selectedCompanyTypeIds,
                isAdmin,
                isEditor,
                _handleAddCompanyType,
              ),
              contactSection: buildContactSection(
                context: context,
                userRole: _userRole!,
                contactInfo: _contactInfo,
                onAddPressed: (category) {
                  showContactDialog(
                    context: context,
                    themeProvider: context.read<ThemeProvider>(),
                    category: category,
                    contactInfo: _contactInfo,
                    onUpdate: (updatedInfo) {
                      setState(() => _contactInfo = updatedInfo);
                      updateContactInfoOnServer(
                        context: context,
                        companyId: widget.companyData['id'],
                        contactInfo: updatedInfo,
                      );
                    },
                  );
                },
                onEditPressed: (category, item) {
                  showContactDialog(
                    context: context,
                    themeProvider: context.read<ThemeProvider>(),
                    category: category,
                    item: item,
                    contactInfo: _contactInfo,
                    onUpdate: (updatedInfo) {
                      setState(() => _contactInfo = updatedInfo);
                      updateContactInfoOnServer(
                        context: context,
                        companyId: widget.companyData['id'],
                        contactInfo: updatedInfo,
                      );
                    },
                  );
                },
                onDeletePressed: (category, item, updatedInfo) {
                  setState(() => _contactInfo = updatedInfo);
                  updateContactInfoOnServer(
                    context: context,
                    companyId: widget.companyData['id'],
                    contactInfo: updatedInfo,
                  );
                },
                onTap: (category, value) => _handleContactTap(category, value),
              ),
            ),
    );
  }

  Future<void> _handleContactTap(String category, String value) async {
    Uri? uri;

    switch (category) {
      case 'phones':
        // Bu durumda _showPhoneOptions çağrılıyor (zaten tanımlı)
        showPhoneOptions(context, value);
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
      await launchDirectly(context, uri.toString());
    } catch (e) {
      debugPrint('❌ Failed to launch $uri: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open $category')),
      );
    }
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
