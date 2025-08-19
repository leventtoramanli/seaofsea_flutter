// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/company_service.dart';

import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/utils/theme_provider.dart';

import 'package:seaofsea/views/companies/company_contact_info.dart';
import 'package:seaofsea/views/companies/company_dashboard.dart';
import 'package:seaofsea/views/companies/company_helpers.dart';
import 'package:seaofsea/views/companies/controllers/company_detail_controller.dart';
import 'package:seaofsea/views/companies/utils/role_caps.dart';
import 'package:seaofsea/views/companies/widgets/company_header.dart';
import 'package:seaofsea/views/companies/widgets/company_people_sheet.dart';
import 'package:seaofsea/views/companies/widgets/states/error_view.dart';
import 'package:seaofsea/views/companies/widgets/states/loading_skeleton.dart';

import 'package:seaofsea/widgets/custon_scaffold.dart';
import 'package:seaofsea/widgets/online_images.dart';

class CompanyDetailPage extends StatefulWidget {
  final Map<String, dynamic> companyData;
  const CompanyDetailPage({super.key, required this.companyData});

  @override
  State<CompanyDetailPage> createState() => _CompanyDetailPageState();
}

class _CompanyDetailPageState extends State<CompanyDetailPage> {
  bool _isLoadingRole = true;
  String? _userRole; // admin|editor|viewer|follower|none

  late Map<String, List<Map<String, String>>> _contactInfo;
  late CompanyDetailController _c;
  late CompanyService _companyService;

  int _currentPageIndex = 0;
  bool get isAdmin => _userRole == 'admin';
  bool get isEditor => _userRole == 'editor';
  bool get isViewer => _userRole == 'viewer';
  bool get isFollower => _userRole == 'follower';
  bool get isEmployee => isAdmin || isEditor || isViewer;
  bool _typesSaving = false;

  List<Map<String, dynamic>> _allCompanyTypes = [];
  List<int> _selectedCompanyTypeIds = [];
  late Map<String, dynamic> _company;

  String? _errorText;

  @override
  void initState() {
    super.initState();
    _company = Map<String, dynamic>.from(widget.companyData);

    // type_ids (liste payload’ından)
    final t = widget.companyData['type_ids'] ??
        widget.companyData['company_type_ids'];
    if (t is List) {
      _selectedCompanyTypeIds = t
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e > 0)
          .toList();
    }

    // contact_info parse (liste payload’ından)
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
    } catch (_) {
      _contactInfo = {};
    }

    final v1 = context.read<V1ApiManager>();
    _companyService = CompanyService(v1);
    _c = CompanyDetailController(service: _companyService);

    _c.addListener(() {
      setState(() {
        _isLoadingRole = _c.loading;
        _userRole = _c.role;
        _company = {..._company, ..._c.company};
        _contactInfo = _c.contactInfo;
        _allCompanyTypes = _c.allTypes;
        _selectedCompanyTypeIds = _c.selectedTypeIds;
        _errorText = _c.error;
        // Not: _currentPageIndex'i şimdilik controller’dan yönetmiyoruz.
      });
    });

    final companyId = _company['id'] ?? _company['company_id'];
    _c.init(companyId, initialTypeIds: _selectedCompanyTypeIds);

    // DİKKAT: Controller zaten tüm veriyi çekiyor.
    // Aşağıdaki üç satır kaldırıldı ki iki kez yükleme olmasın.
    // _fetchUserRole();
    // _fetchCompanyDetails();
    // _fetchCompanyTypes(fetchAll: false);
  }

  // --- Safe helpers ---
  List<Map<String, dynamic>> _parseItems(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map && data['items'] is List) {
      final items = data['items'] as List;
      return items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> _fetchCompanyDetails() async {
    final companyId = _company['id'] ?? _company['company_id'];
    await _c.refreshAll(companyId);
  }

  Future<void> _fetchUserRole() async {
    final companyId = _company['id'] ?? _company['company_id'];
    await _c.refreshAll(companyId);
  }

  Future<void> _fetchCompanyTypes({bool fetchAll = false}) async {
    final companyId = _company['id'] ?? _company['company_id'];
    // fetchAll paramını şimdilik gözardı ediyoruz; controller zaten seçili ID’lere göre getiriyor.
    await _c.refreshAll(companyId);
  }

  void _handleAddCompanyType() async {
    if (_allCompanyTypes.isEmpty) {
      await _fetchCompanyTypes(fetchAll: true);
    }
    handleAddCompanyType(
      context: context,
      allTypes: _allCompanyTypes,
      selectedIds: _selectedCompanyTypeIds,
      onSelectedUpdated: (updatedIds) async {
        await _updateCompanyTypesOptimistic(updatedIds);
      },
    );
  }

  Future<void> _updateCompanyTypesOptimistic(List<int> newIds) async {
    final companyId = _company['id'] ?? _company['company_id'];
    final prevIds = List<int>.from(_selectedCompanyTypeIds);
    bool undone = false;

    // 1) UI’yi anında güncelle
    setState(() {
      _selectedCompanyTypeIds = newIds;
      _typesSaving = true;
    });

    // 2) Snackbar + Undo
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: const Text('Company types updated'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            undone = true;
            setState(() => _selectedCompanyTypeIds = prevIds);
            // Sunucuya geri almayı gönder
            await _c.saveTypes(companyId, prevIds);
          },
        ),
      ),
    );

    // 3) Sunucuya kaydı gönder
    final ok = await _c.saveTypes(companyId, newIds);
    setState(() => _typesSaving = false);

    if (!ok) {
      // Kaydetme başarısız → geri al ve kullanıcıyı bilgilendir
      setState(() => _selectedCompanyTypeIds = prevIds);
      messenger.showSnackBar(
        SnackBar(content: Text('❌ ${'Update failed. Reverted.'}')),
      );
      return;
    }

    // 4) Snackbar kapanana kadar bekle; Undo’ya basıldıysa yukarıda zaten geri alındı
    await controller.closed;

    // Not: Undo’ya basılmadıysa burada ekstra bir şey yapmamıza gerek yok.
  }

  Future<void> _showModalC(
    BuildContext context,
    String action,
    String title,
  ) async {
    final companyId =
        widget.companyData['id'] ?? widget.companyData['company_id'];

    // Minimal: service varsa onu kullan; yoksa v1.call ile de olurdu.
    Future<List<Map<String, dynamic>>> loader() async {
      if (action == 'get_company_followers') {
        return await _companyService.getCompanyFollowers(companyId);
      } else if (action == 'members_list') {
        return await _companyService.getCompanyMembers(companyId);
      } else {
        // Beklenmeyen action → boş liste
        return <Map<String, dynamic>>[];
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return CompanyPeopleSheet(
          title: title,
          load: loader,
          imagePath: 'uploads/user/user/',
          imageNameKey: 'user_image',
          nameKey: 'name',
          surnameKey: 'surname',
          subtitleKeys: const ['rank', 'role'],
        );
      },
    );
  }

  Future<void> _retryAll() async {
    final companyId = _company['id'] ?? _company['company_id'];
    await _c.refreshAll(companyId);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final isTablet = MediaQuery.of(context).size.width > 600 && !isDesktop;

    if (_isLoadingRole || _userRole == null) {
      return CustomScaffold(
        title: _company['name'] ?? 'Company',
        body: const LoadingSkeleton(),
        floatingActionButton: _buildBadges(),
      );
    }

    final caps = RoleCaps.from(_userRole);
    final isAdminOrEditor = caps.canSeeDashboard;
    final companyId =
        widget.companyData['id'] ?? widget.companyData['company_id'];

    if (_errorText != null && _errorText!.isNotEmpty) {
      return CustomScaffold(
        title: _company['name'] ?? 'Company',
        body: ErrorView(message: _errorText!, onRetry: _retryAll),
        floatingActionButton: _buildBadges(),
      );
    }

    return CustomScaffold(
      title: _company['name'] ?? 'Company',
      floatingActionButton: _buildBadges(),
      body: isAdminOrEditor
          ? IndexedStack(
              index: _currentPageIndex,
              children: [
                CompanyDashboard(
                  goToContactInfo: () => setState(() => _currentPageIndex = 1),
                  companyId: companyId,
                ),
                CompanyContactInfo(
                  header: CompanyHeader(
                    company: _company,
                    logoWidget:
                        buildCompanyLogo(context, companyId, _company['logo']),
                    adminButtons: buildAdminButtons(
                      context,
                      companyId,
                      _company,
                      onChanged: () async {
                        await _retryAll();
                      },
                    ),
                    actionButtons: buildActionButtons(
                      context,
                      caps.isViewer,
                      caps.isFollower,
                      caps.isEmployee,
                      companyId,
                    ),
                  ),
                  companyTypeSection: buildCompanyTypeSection(
                    _allCompanyTypes,
                    _selectedCompanyTypeIds,
                    caps.isAdmin,
                    caps.isEditor,
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
                        onUpdate: (updatedInfo) async {
                          setState(() => _contactInfo = updatedInfo);
                          updateContactInfoOnServer(
                            context: context,
                            companyId: companyId,
                            contactInfo: updatedInfo,
                          );
                          final cid = companyId;
                          await _c.saveContactInfo(cid, updatedInfo);
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
                        onUpdate: (updatedInfo) async {
                          setState(() => _contactInfo = updatedInfo);
                          updateContactInfoOnServer(
                            context: context,
                            companyId: companyId,
                            contactInfo: updatedInfo,
                          );
                          // Controller senkronizasyonu — 5b
                          final cid = companyId;
                          await _c.saveContactInfo(cid, updatedInfo);
                        },
                      );
                    },
                    onDeletePressed: (category, item, updatedInfo) async {
                      setState(() => _contactInfo = updatedInfo);
                      updateContactInfoOnServer(
                        context: context,
                        companyId: companyId,
                        contactInfo: updatedInfo,
                      );
                      // Controller senkronizasyonu — 5b
                      final cid = companyId;
                      await _c.saveContactInfo(cid, updatedInfo);
                    },
                    onTap: (category, value) =>
                        _handleContactTap(category, value),
                  ),
                ),
              ],
            )
          : CompanyContactInfo(
              header: CompanyHeader(
                company: _company,
                logoWidget:
                    buildCompanyLogo(context, companyId, _company['logo']),
                adminButtons: buildAdminButtons(
                  context,
                  companyId,
                  _company,
                  onChanged: () async {
                    await _retryAll();
                  },
                ),
                actionButtons: buildActionButtons(
                  context,
                  caps.isViewer,
                  caps.isFollower,
                  caps.isEmployee,
                  companyId,
                ),
              ),
              companyTypeSection: buildCompanyTypeSection(
                _allCompanyTypes,
                _selectedCompanyTypeIds,
                caps.isAdmin,
                caps.isEditor,
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
                    onUpdate: (updatedInfo) async {
                      setState(() => _contactInfo = updatedInfo);
                      updateContactInfoOnServer(
                        context: context,
                        companyId: companyId,
                        contactInfo: updatedInfo,
                      );
                      final cid = companyId;
                      await _c.saveContactInfo(cid, updatedInfo);
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
                    onUpdate: (updatedInfo) async {
                      setState(() => _contactInfo = updatedInfo);
                      updateContactInfoOnServer(
                        context: context,
                        companyId: companyId,
                        contactInfo: updatedInfo,
                      );
                      // Controller senkronizasyonu — 5b
                      final cid = companyId;
                      await _c.saveContactInfo(cid, updatedInfo);
                    },
                  );
                },
                onDeletePressed: (category, item, updatedInfo) async {
                  setState(() => _contactInfo = updatedInfo);
                  updateContactInfoOnServer(
                    context: context,
                    companyId: companyId,
                    contactInfo: updatedInfo,
                  );
                  final cid = companyId;
                  await _c.saveContactInfo(cid, updatedInfo);
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
        showPhoneOptions(context, value);
        return;
      case 'emails':
        uri = Uri(scheme: 'mailto', path: value);
        break;
      case 'websites':
        uri = Uri.parse(value.startsWith('http') ? value : 'https://$value');
        break;
      case 'addresses':
        final query =
            value.replaceAll('.', '').trim().replaceAll(RegExp(r'\s+'), '+');
        uri = Uri.parse('https://yandex.com/maps/?text=$query');
        break;
      default:
        return;
    }
    try {
      await launchDirectly(context, uri.toString());
    } catch (e) {
      debugPrint('❌ Failed to launch $uri: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open $category')),
        );
      }
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
          onPressed: () => _showModalC(context, 'members_list', 'Employees'),
          child: const Icon(Icons.engineering),
        ),
      ],
    );
  }
}
