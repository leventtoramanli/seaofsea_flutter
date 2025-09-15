import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/utils/theme_provider.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';
import 'package:seaofsea/widgets/open_jobs_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 0 = Grid, 1 = Text List, 2 = Button List
  int _layoutMode = 0;
  bool _dialogShown = false;

  // Dashboard bağlamı
  bool _contextIsCompany = false; // "Kişisel" varsayılan
  String? _selectedCompanyId; // Şirket seçici

  final ScrollController _infoScrollController = ScrollController();

  List<Map<String, dynamic>> _myCompanies = [];
  bool _loadingCompanies = false;
  bool get _hasCompanies => _myCompanies.isNotEmpty;
  List<Map<String, dynamic>> _latestJobs = [];
  bool _loadingLatestJobs = false;

  // KPI state (null => skeleton)
  int? _kpiNotifications;
  int? _kpiApplications;
  int? _kpiOpenJobs;
  int? _kpiProfilePercent;

  bool _infoBarExpanded = true;

  final GlobalKey _bottomBarKey = GlobalKey();
  double _bottomBarHeight = 0;
  static const double _bottomBarHeightFallback = 56;

  void _measureSize(GlobalKey key, void Function(double) setHeight) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    final rb = ctx.findRenderObject() as RenderBox?;
    if (rb == null) return;
    final h = rb.size.height;
    if (h > 0 && mounted) setState(() => setHeight(h));
  }

  void _measureBottomBar() =>
      _measureSize(_bottomBarKey, (h) => _bottomBarHeight = h);

  // Placeholder duyurular (2.2.3)
  static const List<Map<String, String>> _announcements = [
    {"level": "info", "title": "Marketplace Beta!", "href": "/marketplace"},
    {"level": "warn", "title": "Sunday 02:00–03:00 Maintenance"},
    {"level": "info", "title": "New Features Coming Soon!"},
  ];

  @override
  void initState() {
    super.initState();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userInfo = authProvider.userInfo;

    _fetchMyCompanies();
    _fetchLatestJobs();

    if (userInfo != null) {
      final isVerified = userInfo['is_verified'];
      debugPrint('userInfo: $userInfo');
      debugPrint('isVerified: $isVerified');

      if (isVerified != 1 &&
          isVerified != '1' &&
          isVerified != true &&
          !_dialogShown) {
        if (!_dialogShown) {
          _dialogShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (!mounted) return;

              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Registration Successful'),
                  content: const Text(
                    'Please verify your email address. A verification email has been sent to your email address.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        // TODO: Doğrulama mailini yeniden gönder
                      },
                      child: const Text('Send Again'),
                    ),
                    TextButton(
                      onPressed: () {
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            });
          });
        }
      }
    } else {
      debugPrint('⚠️ userInfo is null at HomePage initState');
    }

    // Info bar otomatik kaydırma
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 800), _animateInfoScroll);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureBottomBar();
    });
  }

  @override
  void dispose() {
    _infoScrollController.dispose();
    super.dispose();
  }

  void _animateInfoScroll() {
    if (!_infoBarExpanded) return; // kapalıysa animasyon yok
    if (_infoScrollController.hasClients &&
        _infoScrollController.position.maxScrollExtent > 0) {
      _infoScrollController.animateTo(
        _infoScrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOut,
      );
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (_infoScrollController.hasClients) {
          _infoScrollController.animateTo(
            0,
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _onCompanyChanged(String id) {
    setState(() {
      _selectedCompanyId = id;
      _contextIsCompany = true;
    });
    _refreshDashboardForCompany();
  }

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

  int _parseTotal(dynamic data, int fallback) {
    if (data is Map) {
      final t = data['total'];
      if (t is int) return t;
      if (t is String) return int.tryParse(t) ?? fallback;
    }
    return fallback;
  }

  Future<void> _fetchMyCompanies() async {
    setState(() => _loadingCompanies = true);
    try {
      final v1 = context.read<V1ApiManager>();
      final res =
          await v1.call(module: 'company', action: 'my_list', params: {});
      final raw = _parseItems(res['data']);

      final mapped = raw
          .map((e) {
            final rawId = (e['id'] ?? e['company_id']);
            final idStr = rawId?.toString();
            final idInt = (rawId is int) ? rawId : int.tryParse(idStr ?? '');
            return {
              'id': idStr, // Dropdown için String
              'idInt': idInt, // Navigasyon/KPI için int
              'name': (e['short_name'] ?? e['name'] ?? 'Company').toString(),
              'role': (e['role'] ?? '').toString(),
            };
          })
          .where((m) => m['id'] != null && m['idInt'] != null)
          .toList();

      final seen = <String>{};
      final dedup = <Map<String, dynamic>>[];
      for (final m in mapped) {
        final id = m['id'] as String;
        if (seen.add(id)) dedup.add(m);
      }

      if (!mounted) return;
      setState(() {
        _myCompanies = dedup;

        final hasSelected = _selectedCompanyId != null &&
            _myCompanies.any((c) => c['id'] == _selectedCompanyId);

        if (!hasSelected) {
          _selectedCompanyId = _myCompanies.isNotEmpty
              ? _myCompanies.first['id'] as String
              : null;
        }

        // Şirket yoksa alan gizli; varsa kullanıcı isterse şirket moduna geçer
        _contextIsCompany =
            _myCompanies.isNotEmpty && _selectedCompanyId != null;
      });

      // İlk yüklemede seçili şirket varsa KPI’ları çek
      if (_contextIsCompany && _selectedCompanyId != null) {
        await _refreshDashboardForCompany();
      }
    } catch (e) {
      debugPrint('❌ _fetchMyCompanies error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Companies could not be loaded')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingCompanies = false);
    }
  }

  Future<void> _fetchLatestJobs() async {
    setState(() => _loadingLatestJobs = true);
    try {
      final v1 = context.read<V1ApiManager>();
      final res = await v1.call(
        module: 'recruitment',
        action: 'app_list_for_user',
        params: {
          'status': 'published',
          'visibility': 'public',
          'page': 1,
          'perPage': 10,
        },
      );

      final data = res['data'];
      List items;
      if (data is Map) {
        items =
            (data['items'] ?? data['jobs'] ?? data['results'] ?? []) as List;
      } else if (data is List) {
        items = data;
      } else {
        items = const [];
      }

      _latestJobs = items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      _latestJobs = const [];
      debugPrint('❌ _fetchLatestJobs error: $e');
    } finally {
      if (mounted) setState(() => _loadingLatestJobs = false);
    }
  }

  // ---- KPI Helpers ----
  Future<int> _fetchTotal({
    required String module,
    required String action,
    Map<String, dynamic>? params,
  }) async {
    final v1 = context.read<V1ApiManager>();
    final res =
        await v1.call(module: module, action: action, params: params ?? {});
    return _parseTotal(res['data'], 0);
  }

  Future<int> _tryTotals(
    List<({String module, String action, Map<String, dynamic> params})>
        attempts,
  ) async {
    for (final a in attempts) {
      try {
        return await _fetchTotal(
          module: a.module,
          action: a.action,
          params: a.params,
        );
      } catch (_) {
        // bir sonrakini dene
      }
    }
    return 0;
  }

  Future<void> _refreshDashboardForCompany() async {
    setState(() {
      _kpiNotifications = null;
      _kpiApplications = null;
      _kpiOpenJobs = null;
      _kpiProfilePercent = null;
    });

    final String? selIdStr = _selectedCompanyId;
    final int? companyId = (selIdStr != null) ? int.tryParse(selIdStr) : null;

    try {
      // 1) Bildirimler (sadece unread)
      final notif = await _tryTotals([
        (
          module: 'Company_announcement',
          action: 'list',
          params: {
            'only_unread': 1,
            if (companyId != null) 'company_id': companyId,
            'page': 1,
            'perPage': 1,
          }
        ),
      ]);

      // 2) Başvurularım
      final apps = await _fetchTotal(
        module: 'companyjob',
        action: 'my_applications',
        params: {'status': 'submitted', 'page': 1, 'perPage': 1},
      );

      // 3) Açık ilanlar (şirket modunda)
      int openJobs = 0;
      if (_contextIsCompany && companyId != null) {
        openJobs = await _fetchTotal(
          module: 'companyjob',
          action: 'list',
          params: {
            'company_id': companyId,
            'status': 'open',
            'page': 1,
            'perPage': 1
          },
        );
      }

      // 4) Profil % (sonra gerçek hesap bağlanacak)
      final int? pct = null;

      if (!mounted) return;
      setState(() {
        _kpiNotifications = notif;
        _kpiApplications = apps;
        _kpiOpenJobs = _contextIsCompany ? openJobs : null;
        _kpiProfilePercent = pct;
      });
    } catch (e) {
      debugPrint('❌ _refreshDashboardForCompany error: $e');
      if (!mounted) return;
      setState(() {
        _kpiNotifications = 0;
        _kpiApplications = 0;
        _kpiOpenJobs = _contextIsCompany ? 0 : null;
        _kpiProfilePercent = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dashboard verileri yenilenemedi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final Color cardColor =
        isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10);
    final Color borderColor =
        isDark ? Colors.white.withAlpha(30) : Colors.black.withAlpha(30);
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color footerColor =
        isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100;
    final Color footerBorder =
        isDark ? Colors.white.withAlpha(30) : Colors.black.withAlpha(30);

    return CustomScaffold(
      title: 'Dashboard',
      body: Column(
        children: [
          // === ANA İÇERİK: AppBar altı bütün bloklar ===
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildContextBar(cardColor, borderColor, textColor, isDark),
                  const SizedBox(height: 12),
                  _buildBannerStack(),
                  const SizedBox(height: 12),
                  _buildKpiRow(textColor, cardColor, borderColor),
                  const SizedBox(height: 16),
                  _buildWorkQueueTabs(cardColor, borderColor, textColor),
                  const SizedBox(height: 16),
                  _buildDiscoverStrip(),
                  const SizedBox(height: 12),
                  _buildRecentRow(),
                  const SizedBox(height: 16),
                  _buildModuleSection(cardColor, borderColor, textColor),
                  const SizedBox(height: 12),
                  _buildLatestJobsSection(),
                ],
              ),
            ),
          ),

          // === (2) ALT HIZLI EYLEM ÇUBUĞU + GÖRÜNÜM SEÇİCİ ===
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: footerColor,
              border: Border(
                top: BorderSide(color: footerBorder, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFooterButton(
                        icon: Icons.person_outline,
                        label: 'User',
                        onTap: () {},
                      ),
                      _buildFooterButton(
                        icon: Icons.business,
                        label: 'Company',
                        onTap: () {
                          Navigator.pushNamed(context, '/company_list');
                        },
                      ),
                      _buildFooterButton(
                        icon: Icons.mediation,
                        label: 'Social',
                        onTap: () {},
                      ),
                      _buildFooterButton(
                        icon: Icons.work_outline,
                        label: 'Apply Job',
                        onTap: () {
                          Navigator.pushNamed(context, '/job_application');
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 50,
                  alignment: Alignment.center,
                  child: DropdownButton<int>(
                    value: _layoutMode,
                    underline: Container(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _layoutMode = value);
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: 0,
                        child: Icon(Icons.grid_view),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Icon(Icons.list),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Icon(Icons.view_agenda),
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // =========================
  // BLOK: Context Bar (2.1)
  // =========================
  Widget _buildContextBar(
      Color cardColor, Color borderColor, Color textColor, bool isDark) {
    if (_myCompanies.isEmpty) {
      return const SizedBox.shrink(); // şirket yoksa tamamen gizle
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Text('Company', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedCompanyId,
              items: _myCompanies
                  .map((c) => DropdownMenuItem<String>(
                        value: c['id'] as String,
                        child: Text(c['name'] as String),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) _onCompanyChanged(v);
              },
              decoration: InputDecoration(
                hintText: 'Select company',
                isDense: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _selectedCompanyId == null
                ? null
                : () {
                    final comp = _myCompanies.firstWhere(
                      (c) => c['id'] == _selectedCompanyId,
                      orElse: () => {},
                    );
                    final int? cid = comp['idInt'] as int?;
                    if (cid == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Geçersiz şirket ID')),
                      );
                      return;
                    }

                    Navigator.pushNamed(
                      context,
                      '/company_detail', // gerekirse '/company_showcase'
                      arguments: {
                        // Karşı tarafın beklentisini birebir karşılayalım:
                        'id': cid,
                        'company_id': cid,
                        // Ekstra bilgi de taşıyoruz (opsiyonel)
                        'name': comp['name'],
                        'role': comp['role'],
                      },
                    );
                  },
            icon: const Icon(Icons.open_in_new),
            label: Text(
              (() {
                final sel = _myCompanies.firstWhere(
                  (c) => c['id'] == _selectedCompanyId,
                  orElse: () => const {'role': ''},
                );
                return (sel['role'] == 'admin') ? 'Manage' : 'Go to Company';
              })(),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // BLOK: BannerStack (2.2)
  // =========================
  Widget _buildBannerStack() {
    if (_announcements.isEmpty) return const SizedBox.shrink();

    return Column(
      children: _announcements.map((a) {
        final level = a['level'] ?? 'info';
        final title = a['title'] ?? '';
        final isWarn = level == 'warn';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isWarn
                ? Colors.orange.withAlpha(40)
                : Colors.blue.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isWarn
                  ? Colors.orange.withAlpha(90)
                  : Colors.blue.withAlpha(90),
            ),
          ),
          child: Row(
            children: [
              Icon(isWarn
                  ? Icons.warning_amber_rounded
                  : Icons.campaign_outlined),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
              if ((a['href'] ?? '').isNotEmpty)
                TextButton(
                  onPressed: () {},
                  child: const Text('Details'),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // =========================
  // BLOK: KPI Karoları (2.3)
  // =========================
  Widget _buildKpiRow(Color textColor, Color cardColor, Color borderColor) {
    final items = <_KpiItem>[
      _KpiItem(
          icon: Icons.notifications_active_outlined,
          title: 'Notifications',
          count: _kpiNotifications),
      _KpiItem(
          icon: Icons.assignment_outlined,
          title: 'My Applications',
          count: _kpiApplications),
      _KpiItem(
          icon: Icons.person_pin_circle_outlined,
          title: 'Profile %',
          count: _kpiProfilePercent),
      if (_contextIsCompany)
        _KpiItem(
            icon: Icons.work_history_outlined,
            title: 'Open Positions',
            count: _kpiOpenJobs),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((k) {
        return _kpiCard(k, cardColor, borderColor, textColor);
      }).toList(),
    );
  }

  Widget _kpiCard(
    _KpiItem item,
    Color cardColor,
    Color borderColor,
    Color textColor,
  ) {
    final loading = item.count == null;
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 28, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: TextStyle(color: textColor)),
                const SizedBox(height: 4),
                loading
                    ? Container(
                        height: 14,
                        width: 48,
                        decoration: BoxDecoration(
                          color: textColor.withAlpha(40),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      )
                    : Text('${item.count}',
                        style: TextStyle(
                            color: textColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // BLOK: WorkQueue Tabs (2.4)
  // =========================
  Widget _buildWorkQueueTabs(
      Color cardColor, Color borderColor, Color textColor) {
    return DefaultTabController(
      length: 4,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 👈 eklendi
          children: [
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Open Jobs'),
                Tab(text: 'Applications'),
                Tab(text: 'Approvals'),
                Tab(text: 'Messages'),
              ],
            ),
            const Divider(height: 0.5),
            SizedBox(
              // Expanded yerine sabit/sonlu yükseklik ver
              height: 350, // ihtiyaca göre 360–560 arası deneyebilirsin
              // const kaldırıldı, çünkü içinde stateful widget (OpenJobsTab) var
              child: TabBarView(
                // İstersen kaydırmayı kapat: physics: const NeverScrollableScrollPhysics(),
                children: const [
                  OpenJobsTab(
                    fixedHeight: 220,
                  ),
                  _EmptyListPlaceholder(label: 'Applications list'),
                  _EmptyListPlaceholder(label: 'Work/Items awaiting approval'),
                  _EmptyListPlaceholder(label: 'List of messages'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // BLOK: Discover/Public Pulse (2.5-2.6)
  // =========================
  Widget _buildDiscoverStrip() {
    final chips = <String>[
      'Popular Companies',
      'New Listings',
      'Marketplace (Beta)',
    ];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(chips[index]),
            onPressed: () {},
          );
        },
      ),
    );
  }

  // =========================
  // BLOK: Recent (2.5)
  // =========================
  Widget _buildRecentRow() {
    final items = ['Şirket A', 'İlan #1023', 'Şirket B'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Continue / Last Visited',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              return Container(
                width: 160,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child:
                    Center(child: Text(items[i], textAlign: TextAlign.center)),
              );
            },
          ),
        ),
      ],
    );
  }

  // =========================
  // BLOK: Module Grid (2.6) — _layoutMode ile
  // =========================
  Widget _buildModuleSection(
    Color cardColor,
    Color borderColor,
    Color textColor,
  ) {
    if (_layoutMode == 1) {
      return ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: _modules
            .map((module) => ListTile(
                  leading: Icon(module.icon, color: textColor),
                  title: Text(module.title, style: TextStyle(color: textColor)),
                  onTap: () {},
                ))
            .toList(),
      );
    } else if (_layoutMode == 2) {
      return ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: _modules
            .map((module) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ElevatedButton.icon(
                    icon: Icon(module.icon),
                    label: Text(module.title),
                    onPressed: () {},
                  ),
                ))
            .toList(),
      );
    } else {
      return Center(
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: _modules.map((module) {
            return SizedBox(
              width: 140,
              height: 140,
              child: _buildModuleBox(module, cardColor, borderColor, textColor),
            );
          }).toList(),
        ),
      );
    }
  }

  // === Ortak mini bileşenler ===

  Widget _buildFooterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleBox(
      _Module module, Color cardColor, Color borderColor, Color textColor) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: cardColor,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        padding: const EdgeInsets.all(12),
      ),
      onPressed: () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(module.icon, size: 40, color: textColor),
          const SizedBox(height: 8),
          Text(
            module.title,
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestJobsSection() {
    if (_loadingLatestJobs) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: const [
              SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Loading latest jobs…'),
            ],
          ),
        ),
      );
    }

    if (_latestJobs.isEmpty) return const SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.work_outline),
                const SizedBox(width: 8),
                Text('Latest Jobs',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/jobs_explore'),
                  child: const Text('View all'),
                ),
              ],
            ),
            const Divider(height: 12),
            ..._latestJobs.map((j) {
              final id = int.tryParse('${j['id'] ?? j['job_id'] ?? 0}') ?? 0;
              final title = (j['title'] ?? 'Untitled').toString();
              final companyName =
                  (j['company_name'] ?? j['company'] ?? '').toString();
              final companyId = int.tryParse('${j['company_id'] ?? 0}') ?? 0;
              final location = (j['location'] ?? j['city'] ?? '').toString();
              final createdAt = (j['created_at'] ?? '').toString();

              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: const Icon(Icons.badge_outlined),
                title:
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text([
                  if (companyName.isNotEmpty) companyName,
                  if (location.isNotEmpty) '• $location',
                  if (createdAt.isNotEmpty) '• $createdAt',
                ].join('  ')),
                trailing: OutlinedButton(
                  onPressed: id <= 0
                      ? null
                      : () {
                          Navigator.pushNamed(
                            context,
                            '/job_application',
                            arguments: {
                              'job_id': id,
                              if (companyId > 0) 'company_id': companyId,
                              if (companyName.isNotEmpty)
                                'company_name': companyName,
                            },
                          );
                        },
                  child: const Text('Apply'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// === Yardımcı tipler ===

class _Module {
  final IconData icon;
  final String title;
  const _Module(this.icon, this.title);
}

class _KpiItem {
  final IconData icon;
  final String title;
  final int? count; // null => loading placeholder
  const _KpiItem({required this.icon, required this.title, this.count});
}

class _EmptyListPlaceholder extends StatelessWidget {
  final String label;
  const _EmptyListPlaceholder({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

// === Mevcut modül kataloğu (statik) ===
const List<_Module> _modules = [
  _Module(Icons.people, 'Crew Module'),
  _Module(Icons.engineering, 'Planned Maintenance'),
  _Module(Icons.store, 'Store Module'),
  _Module(Icons.badge, 'Certificate Module'),
  _Module(Icons.shopping_cart, 'Purchase Module'),
  _Module(Icons.medical_services, 'Hospital Module'),
  _Module(Icons.local_hotel, 'Hotel Modules'),
  _Module(Icons.domain, 'Companies'),
  _Module(Icons.directions_boat, 'Fleet Management'),
  _Module(Icons.forum, 'Discussion Forum'),
  _Module(Icons.article, 'Blog & Posts'),
];
