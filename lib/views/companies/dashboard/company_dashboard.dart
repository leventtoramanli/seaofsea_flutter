// lib/views/companies/dashboard/company_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/permission_provider.dart';
import 'package:seaofsea/views/companies/dashboard/widgets/address_expandable_list.dart';
import 'package:seaofsea/views/companies/dashboard/widgets/announcements_section.dart';
import 'package:seaofsea/views/companies/dashboard/widgets/public_contact_strip.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/views/companies/dashboard/controller/dashboard_controller.dart';
import 'package:seaofsea/views/companies/dashboard/services/company_dashboard_service.dart';

// Employee widgets
import 'package:seaofsea/views/companies/dashboard/widgets/header_card.dart';
import 'package:seaofsea/views/companies/dashboard/widgets/quick_actions_bar.dart';
import 'package:seaofsea/views/companies/dashboard/widgets/kpi_grid.dart';
import 'package:seaofsea/views/companies/dashboard/widgets/workboard.dart';
import 'package:seaofsea/views/companies/dashboard/widgets/people_snapshot_card.dart';
import 'package:seaofsea/views/companies/dashboard/widgets/contact_summary_card.dart';

// Public widgets
import 'package:seaofsea/views/companies/dashboard/widgets/public_hero.dart';
import 'package:seaofsea/views/companies/dashboard/widgets/mini_kpi_row.dart';

// Recruitment
import 'package:seaofsea/services/v1/recruitment_service.dart';
import 'package:seaofsea/views/companies/dashboard/widgets/company_app_counters.dart';

class CompanyDashboard extends StatefulWidget {
  final VoidCallback goToContactInfo;
  final int companyId;

  const CompanyDashboard({
    super.key,
    required this.goToContactInfo,
    required this.companyId,
  });

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    final v1 = context.read<V1ApiManager>();
    _controller = DashboardController(
      service: CompanyDashboardService(v1),
      companyId: widget.companyId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadAll(context: context).then((_) {
        if (mounted) _controller.refreshOpenJobsPublic(context: context);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---- URL/Clipboard yardımcıları
  Future<void> _launchUri(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open the link')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open the link')),
      );
    }
  }

  Future<void> _openNewAppDialog(BuildContext context) async {
    final jobCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final coverCtrl = TextEditingController();

    bool loading = false;
    String? error;

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('New Application'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: jobCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Job Post ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // user_id opsiyonel: boş bırakırsan backend actor’u kullanır.
                  TextField(
                    controller: userCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Candidate User ID (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: coverCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Cover Letter (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                  if (loading) ...[
                    const SizedBox(height: 12),
                    const CircularProgressIndicator(),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.add_task_outlined),
                label: const Text('Create'),
                onPressed: loading
                    ? null
                    : () async {
                        final jid = int.tryParse(jobCtrl.text.trim());
                        if (jid == null || jid <= 0) {
                          setState(() =>
                              error = 'Please enter a valid Job Post ID.');
                          return;
                        }

                        setState(() {
                          loading = true;
                          error = null;
                        });

                        try {
                          final uid = int.tryParse(userCtrl.text.trim());
                          final res = await RecruitmentServiceV1.appCreate(
                            companyId: widget.companyId,
                            jobPostId: jid,
                            userId: uid, // null ise backend actor’u kullanır
                            coverLetter: coverCtrl.text.trim().isEmpty
                                ? null
                                : coverCtrl.text.trim(),
                          );

                          final ok = (res is Map && res['success'] == true) ||
                              (res is Map && res['id'] != null);
                          if (!ctx.mounted) return;
                          if (ok) {
                            Navigator.pop(ctx, true);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Application created')),
                              );
                            }
                          } else {
                            setState(() => error =
                                (res is Map && res['message'] != null)
                                    ? res['message'].toString()
                                    : 'Create failed');
                          }
                        } catch (e) {
                          setState(() => error = 'Error: $e');
                        } finally {
                          if (!ctx.mounted) return;
                          setState(() => loading = false);
                        }
                      },
              ),
            ],
          );
        });
      },
    );
  }

  void _copyToClipboard(String text, {String label = 'Copied to clipboard'}) {
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(label)),
    );
  }

  // ---- Contact tıklama davranışları
  void _onPhoneTap(Map<String, String> item) {
    final number = item['value']!.trim();
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.call),
            title: Text('Call $number'),
            onTap: () {
              Navigator.pop(context);
              _launchUri(Uri(scheme: 'tel', path: number));
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy number'),
            onTap: () {
              Navigator.pop(context);
              _copyToClipboard(number, label: 'Number copied');
            },
          ),
        ]),
      ),
    );
  }

  void _onEmailTap(Map<String, String> item) {
    final email = item['value']!.trim();
    _launchUri(Uri(scheme: 'mailto', path: email));
  }

  void _onWebsiteTap(Map<String, String> item) {
    var url = item['value']!.trim();
    if (!url.startsWith('http')) url = 'https://$url';
    _launchUri(Uri.parse(url));
  }

  void _onAddressTap(Map<String, String> item) {
    final q = Uri.encodeComponent(item['value']!.trim());
    _launchUri(Uri.parse('https://www.google.com/maps/search/?api=1&query=$q'));
  }

  bool _canManage(String role) => role == 'admin' || role == 'editor';
  bool _isEmployee(String role) =>
      role == 'admin' || role == 'editor' || role == 'viewer';

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1000;

    return ChangeNotifierProvider<DashboardController>.value(
      value: _controller,
      child: Consumer<DashboardController>(
        builder: (context, ctrl, _) {
          final s = ctrl.state;

          // Permission fallback: yeni ve eski kodları dene
          final pp = PermissionProvider.maybeOf(context);
          final canSeeApps =
              (pp?.can('recruitment.app.view_company') ?? false) ||
                  (pp?.can('recruitment.app.manage') ?? false) ||
                  (pp?.can('application.view') ?? false) ||
                  (pp?.can('application.review') ?? false) ||
                  (pp?.can('application.manage') ?? false) ||
                  (pp?.can('job.applications.view') ?? false)||
                  (pp?.can('recruitment.app.published') ?? false);

          final addressItems =
              s.contactSummary['addresses'] ?? const <Map<String, String>>[];

          final title = (s.detail?['name'] ?? 'Company').toString();
          final List<String> typeNames = (s.detail?['type_names'] is List)
              ? List<String>.from(s.detail!['type_names'])
              : const <String>[];
          final logoName = (s.detail?['logo'] as String?);
          final canManage = _canManage(s.role);
          final isEmployee = _isEmployee(s.role);

          // Kısa açıklama
          String? shortDescription;
          final aboutRaw = s.detail?['about'] ?? s.detail?['description'];
          if (aboutRaw is String && aboutRaw.trim().isNotEmpty) {
            shortDescription = aboutRaw.trim();
          }

          // İlk adres (Map Preview için)
          String? firstAddress;
          final addrs = s.contactSummary['addresses'];
          if (addrs != null && addrs.isNotEmpty) {
            firstAddress = (addrs.first['value'] ?? '').trim();
            if (firstAddress.isEmpty) firstAddress = null;
          }

          // Ziyaretçi/follower görünümü
          if (!isEmployee) {
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PublicHero(
                  title: title,
                  typeNames: typeNames,
                  shortDescription: shortDescription,
                  logoName: logoName,
                  followerCount: s.followers,
                  compact: true,
                  isFollowing: ctrl.isFollowing,
                  followBusy: ctrl.followBusy,
                  onToggleFollow: () async {
                    final ok = await ctrl.toggleFollow(context: context);
                    if (!ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Follow action failed')),
                      );
                    }
                  },
                  onApplyNowPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Apply coming soon')),
                    );
                  },
                  onOpenJobsPressed: () => Navigator.pushNamed(
                    context,
                    '/company_job_list',
                    arguments: {'company_id': widget.companyId},
                  ),
                  onSharePressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share coming soon')),
                    );
                  },
                  onSaveContactPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Save vCard coming soon')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                MiniKpiRow(
                  openJobs: s.openJobs,
                  followers: s.followers,
                  onJobsTap: () => Navigator.pushNamed(
                    context,
                    '/company_job_list',
                    arguments: {'company_id': widget.companyId},
                  ),
                  onFollowersTap: () {},
                ),
                const SizedBox(height: 12),
                // Küçük çipler: Phone / Email / Web
                PublicContactStrip(
                  contact: s.contactSummary,
                  onPhoneTap: _onPhoneTap,
                  onEmailTap: _onEmailTap,
                  onWebsiteTap: _onWebsiteTap,
                ),
                // Tek büyük Adres kartı (varsa)
                const SizedBox(height: 16),
                if (addressItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  AddressExpandableList(
                    addresses: addressItems,
                    onOpenMap: (m) => _onAddressTap(m),
                    onCopy: (m) => _copyToClipboard((m['value'] ?? '').trim(),
                        label: 'Address copied'),
                  ),
                ],
                const SizedBox(height: 16),
                AnnouncementsSection(companyId: widget.companyId),
                const SizedBox(height: 16), // sticky bar için altta boşluk
              ],
            );

            final isNarrow = MediaQuery.of(context).size.width < 720;

            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () => ctrl.loadAll(context: context),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: content,
                      ),
                    ),
                  ),
                ),
                // Mobilde yapışkan CTA bar
                if (isNarrow)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 8,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(16),
                        color: Theme.of(context).colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: ctrl.followBusy
                                      ? null
                                      : () async {
                                          final ok = await ctrl.toggleFollow(
                                              context: context);
                                          if (!ok && mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Follow action failed')),
                                            );
                                          }
                                        },
                                  icon: Icon(ctrl.isFollowing
                                      ? Icons.check
                                      : Icons.person_add_alt_1),
                                  label: Text(ctrl.isFollowing
                                      ? 'Following'
                                      : 'Follow'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Apply coming soon')),
                                    );
                                  },
                                  icon: const Icon(Icons.assignment_outlined),
                                  label: const Text('Apply'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                _buildNewAppFab(), // FAB (koşullu)
              ],
            );
          }

          debugPrint('openJobs: ${s.openJobs}');
          // Çalışanlar için (admin/editor/viewer)
          return RefreshIndicator(
            onRefresh: () => ctrl.loadAll(context: context),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  HeaderCard(
                    title: title,
                    typeNames: typeNames,
                    role: s.role,
                    followerCount: s.followers,
                    logoName: logoName,
                    onManage: canManage
                        ? () => Navigator.pushNamed(
                              context,
                              '/company_settings',
                              arguments: {'company_id': widget.companyId},
                            )
                        : null,
                    onFollowToggle: (!canManage)
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Follow/Unfollow coming soon')),
                            );
                          }
                        : null,
                  ),
                  const SizedBox(height: 12),
                  QuickActionsBar(
                    canManage: canManage,
                    onOpenJobs: () => Navigator.pushNamed(
                      context,
                      '/company_job_list',
                      arguments: {'company_id': widget.companyId},
                    ),
                    onPeople: () => Navigator.pushNamed(
                      context,
                      '/company_users',
                      arguments: {'company_id': widget.companyId},
                    ),
                    onMessages: () => Navigator.pushNamed(
                      context,
                      '/company_notifications',
                      arguments: {'company_id': widget.companyId},
                    ),
                    onContact: widget.goToContactInfo,
                    onInvite: canManage
                        ? () => Navigator.pushNamed(
                              context,
                              '/company_invite',
                              arguments: {'company_id': widget.companyId},
                            )
                        : null,
                    onSettings: canManage
                        ? () => Navigator.pushNamed(
                              context,
                              '/company_settings',
                              arguments: {'company_id': widget.companyId},
                            )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              KpiGrid(
                                loading:
                                    s.loading && s.applicationCounts == null,
                                tiles: [
                                  KpiTile(
                                    icon: Icons.assignment,
                                    title: 'Applications',
                                    value: ctrl.totalPendingLike,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/company_applications',
                                      arguments: {
                                        'company_id': widget.companyId,
                                      },
                                    ),
                                  ),
                                  KpiTile(
                                    icon: Icons.people_alt_outlined,
                                    title: 'Members',
                                    value: s.membersApproved,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/company_users',
                                      arguments: {
                                        'company_id': widget.companyId
                                      },
                                    ),
                                  ),
                                  KpiTile(
                                    icon: Icons.badge_outlined,
                                    title: 'Open Jobs',
                                    value: s.openJobs,
                                    onTap: () async {
                                      await Navigator.pushNamed(
                                        context,
                                        '/company_job_list',
                                        arguments: {
                                          'company_id': widget.companyId
                                        },
                                      );
                                      if (context.mounted) {
                                        await ctrl.refreshOpenJobsPublic(
                                            context: context);
                                      }
                                    },
                                  ),
                                  KpiTile(
                                    icon: Icons.group_add_outlined,
                                    title: 'Followers',
                                    value: s.followers,
                                    onTap: () {},
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (canSeeApps)
                                CompanyAppCounters(
                                  companyId: widget.companyId,
                                  onTapStatus: (status) => Navigator.pushNamed(
                                    context,
                                    '/company_applications',
                                    arguments: {
                                      'company_id': widget.companyId,
                                      'status': status,
                                    },
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Workboard(
                                role: s.role,
                                loading: s.loading,
                                applicationCounts: s.applicationCounts,
                                onViewAllApplications: () =>
                                    Navigator.pushNamed(
                                  context,
                                  '/company_applications',
                                  arguments: {'company_id': widget.companyId},
                                ),
                                onViewAllMessages: () => Navigator.pushNamed(
                                  context,
                                  '/company_notifications',
                                  arguments: {'company_id': widget.companyId},
                                ),
                                onViewAllJobs: () => Navigator.pushNamed(
                                  context,
                                  '/company_job_list',
                                  arguments: {'company_id': widget.companyId},
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // RIGHT
                        SizedBox(
                          width: 300,
                          child: Column(
                            children: [
                              PeopleSnapshotCard(
                                people: s.topPeople,
                                companyId: widget.companyId,
                              ),
                              const SizedBox(height: 12),
                              ContactSummaryCard(
                                contact: s.contactSummary,
                                onEdit:
                                    canManage ? widget.goToContactInfo : null,
                                onPhoneTap: _onPhoneTap,
                                onEmailTap: _onEmailTap,
                                onWebsiteTap: _onWebsiteTap,
                                onAddressTap: _onAddressTap,
                              ),
                              const SizedBox(height: 16),
                              AnnouncementsSection(companyId: widget.companyId),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KpiGrid(
                          loading: s.loading && s.applicationCounts == null,
                          tiles: [
                            KpiTile(
                              icon: Icons.assignment,
                              title: 'Applications',
                              value: ctrl.totalPendingLike,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/company_applications',
                                arguments: {
                                  'company_id': widget.companyId,
                                },
                              ),
                            ),
                            KpiTile(
                              icon: Icons.people_alt_outlined,
                              title: 'Members',
                              value: s.membersApproved,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/company_users',
                                arguments: {'company_id': widget.companyId},
                              ),
                            ),
                            KpiTile(
                              icon: Icons.badge_outlined,
                              title: 'Open Jobs',
                              value: s.openJobs,
                              onTap: () async {
                                await Navigator.pushNamed(
                                  context,
                                  '/company_job_list',
                                  arguments: {'company_id': widget.companyId},
                                );
                                if (context.mounted) {
                                  await ctrl.refreshOpenJobsPublic(
                                      context: context);
                                }
                              },
                            ),
                            KpiTile(
                              icon: Icons.group_add_outlined,
                              title: 'Followers',
                              value: s.followers,
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (canSeeApps)
                          CompanyAppCounters(
                            companyId: widget.companyId,
                            onTapStatus: (status) => Navigator.pushNamed(
                              context,
                              '/company_applications',
                              arguments: {
                                'company_id': widget.companyId,
                                'status': status,
                              },
                            ),
                          ),
                        const SizedBox(height: 16),
                        Workboard(
                          role: s.role,
                          loading: s.loading,
                          applicationCounts: s.applicationCounts,
                          onViewAllApplications: () => Navigator.pushNamed(
                            context,
                            '/company_applications',
                            arguments: {
                              'company_id': widget.companyId,
                            },
                          ),
                          onViewAllMessages: () => Navigator.pushNamed(
                            context,
                            '/company_notifications',
                            arguments: {'company_id': widget.companyId},
                          ),
                          onViewAllJobs: () => Navigator.pushNamed(
                            context,
                            '/company_job_list',
                            arguments: {'company_id': widget.companyId},
                          ),
                        ),
                        const SizedBox(height: 16),
                        PeopleSnapshotCard(
                          people: s.topPeople,
                          companyId: widget.companyId,
                        ),
                        const SizedBox(height: 12),
                        ContactSummaryCard(
                          contact: s.contactSummary,
                          onEdit: canManage ? widget.goToContactInfo : null,
                          onPhoneTap: _onPhoneTap,
                          onEmailTap: _onEmailTap,
                          onWebsiteTap: _onWebsiteTap,
                          onAddressTap: _onAddressTap,
                        ),
                        const SizedBox(height: 16),
                        AnnouncementsSection(companyId: widget.companyId),
                        const SizedBox(height: 16),
                      ],
                    ),
                  _buildNewAppFab(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewAppFab() {
    final pp = PermissionProvider.maybeOf(context);
    final canCreate = (pp?.can('recruitment.app.create') ?? false) ||
        (pp?.can('recruitment.app.manage') ?? false) ||
        (pp?.can('application.manage') ?? false);

    if (!canCreate) return const SizedBox.shrink();

    return Positioned(
      right: 16,
      bottom: 16,
      child: FloatingActionButton.extended(
        icon: const Icon(Icons.assignment_add),
        label: const Text('New Application'),
        onPressed: () => _openNewAppDialog(context),
      ),
    );
  }
}
