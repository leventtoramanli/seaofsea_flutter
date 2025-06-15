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
  int _layoutMode = 0; // 0 = Grid, 1 = Text List, 2 = Button List
  bool _dialogShown = false;

  final ScrollController _infoScrollController = ScrollController();

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
                        // Yeniden gönderme işlemi
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

    // Scroll animation
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (_layoutMode == 1) {
                    return ListView(
                      children: _modules
                          .map((module) => ListTile(
                                leading: Icon(module.icon, color: textColor),
                                title: Text(module.title,
                                    style: TextStyle(color: textColor)),
                              ))
                          .toList(),
                    );
                  } else if (_layoutMode == 2) {
                    return ListView(
                      children: _modules
                          .map((module) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: ElevatedButton.icon(
                                  icon: Icon(module.icon),
                                  label: Text(module.title),
                                  onPressed: () {},
                                ),
                              ))
                          .toList(),
                    );
                  } else {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Center(
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: _modules.map((module) {
                            return SizedBox(
                              width: 140,
                              height: 140,
                              child: _buildModuleBox(
                                  module, cardColor, borderColor, textColor),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
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

class _Module {
  final IconData icon;
  final String title;
  const _Module(this.icon, this.title);
}

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
