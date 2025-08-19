import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/utils/theme_provider.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

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
  String? _selectedCompanyId; // Şirket seçici (placeholder)
  bool get _hasCompanies =>
      false; 
      // TODO: gerçek şirket listesi bağlanınca güncellenecek

  final ScrollController _infoScrollController = ScrollController();

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
  }

  void _animateInfoScroll() {
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

    final Color glassBackground =
        isDark ? Colors.grey.withAlpha(15) : Colors.grey.withAlpha(40);
    final Color glassBorder =
        isDark ? Colors.white.withAlpha(20) : Colors.white.withAlpha(30);

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
                  _buildBannerStack(), // Email doğrulama uyarısına ek, global duyurular
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
                ],
              ),
            ),
          ),

          // === (1) CAM GÖRÜNÜMLÜ HIZLI BİLGİ BAR ===
          Container(
            // değişiklik yapılacak alan bunun dışlında bir yere dokunmayalım
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: footerBorder, width: 0.5),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: glassBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: glassBorder),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: SingleChildScrollView(
                    controller: _infoScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFooterButton(
                          icon: Icons.verified_user,
                          label: 'Role: Admin',
                          onTap: () {},
                        ),
                        _buildFooterButton(
                          icon: Icons.directions_boat_filled,
                          label: 'Fleet: 3 Ships',
                          onTap: () {},
                        ),
                        _buildFooterButton(
                          icon: Icons.assignment_turned_in_outlined,
                          label: 'Tasks: 2 open',
                          onTap: () {},
                        ),
                        _buildFooterButton(
                          icon: Icons.message_outlined,
                          label: 'Messages: 2 new',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
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
    Color cardColor,
    Color borderColor,
    Color textColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Kişisel/Şirket toggle
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Personel'),
                icon: Icon(Icons.person_outline),
              ),
              ButtonSegment(
                value: true,
                label: Text('Company'),
                icon: Icon(Icons.apartment_outlined),
              ),
            ],
            selected: {_contextIsCompany},
            onSelectionChanged: (s) {
              setState(() {
                _contextIsCompany = s.first;
              });
            },
          ),

          const SizedBox(width: 12),

          // Şirket seçici (yoksa disabled)
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCompanyId,
              items: const [], // TODO: şirket listesi bağlanınca doldurulacak
              onChanged: _hasCompanies
                  ? (v) => setState(() => _selectedCompanyId = v)
                  : null,
              decoration: InputDecoration(
                hintText: _hasCompanies ? 'Select Company' : 'Company not found',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Global arama placeholder
          IconButton(
            onPressed: () {
              // TODO: global arama sayfasına git
            },
            icon: const Icon(Icons.search),
            tooltip: 'Search',
          ),
        ],
      ),
    );
  }

  // =========================
  // BLOK: BannerStack (2.2)
  // =========================
  Widget _buildBannerStack() {
    // Şimdilik sadece duyuru bandı (email doğrulama popup'ı zaten initState’de)
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
                  onPressed: () {
                    // TODO: linke git
                  },
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
    // Görünürlük/perm filtreleri ileride bağlanacak
    final items = <_KpiItem>[
      _KpiItem(
          icon: Icons.notifications_active_outlined,
          title: 'Notifications',
          count: null),
      _KpiItem(
          icon: Icons.assignment_outlined, title: 'My Applications', count: null),
      _KpiItem(
          icon: Icons.person_pin_circle_outlined,
          title: 'Profile %',
          count: null),
      if (_contextIsCompany)
        _KpiItem(
            icon: Icons.work_history_outlined,
            title: 'Open Positions',
            count: null),
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
    final loading = item.count == null; // Placeholder
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
      length: 3,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Applications'),
                Tab(text: 'Approvals'),
                Tab(text: 'Messages'),
              ],
            ),
            const Divider(height: 1),
            SizedBox(
              height: 220, // sabit yükseklik (placeholder)
              child: const TabBarView(
                children: [
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
    // Placeholder yatay kaydırma
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
            onPressed: () {
              // TODO: ilgili sayfaya/filtreye git
            },
          );
        },
      ),
    );
  }

  // =========================
  // BLOK: Recent (2.5)
  // =========================
  Widget _buildRecentRow() {
    // Placeholder son gezintiler
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
