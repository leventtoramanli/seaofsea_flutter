import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/utils/theme_data.dart';
import 'package:seaofsea/widgets/custom_button.dart';

class CompanyDashboard extends StatefulWidget {
  final VoidCallback goToContactInfo;
  final int companyId;

  const CompanyDashboard(
      {super.key, required this.goToContactInfo, required this.companyId});

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

enum ApplicationStatus {
  pending,
  preApproved, // Ön onay verilmiş (geçici)
  approved,
  rejected,
  waitingManagerApproval, // Personel müdürü onayı var, işletme onayı bekleniyor
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  Map<ApplicationStatus, int>? applicationCounts;

  @override
  void initState() {
    super.initState();
    _fetchApplicationCounts();
  }

  Future<void> _fetchApplicationCounts() async {
    final api = context.read<ApiManager>();

    // companyId dinamik alındı, widget.companyId olarak güncelle
    final int companyId = widget.companyId;

    final response = await api.post(context, 'get_company_users', {
      'company_id': companyId,
      // Eğer gerekiyorsa role ve rank parametreleri eklenebilir
    });

    if (response['success'] == true && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      final usersList = data['data'] as List<dynamic>;

      // applicationCounts için sayma işlemi
      final counts = <ApplicationStatus, int>{
        ApplicationStatus.pending: 0,
        ApplicationStatus.preApproved: 0,
        ApplicationStatus.approved: 0,
        ApplicationStatus.rejected: 0,
        ApplicationStatus.waitingManagerApproval: 0,
      };

      for (final user in usersList) {
        // user Map<String, dynamic> olarak kabul edelim
        final statusString = (user['status'] ?? '').toString().toLowerCase();

        switch (statusString) {
          case 'pending':
            counts[ApplicationStatus.pending] =
                counts[ApplicationStatus.pending]! + 1;
            break;
          case 'preapproved':
          case 'pre_approved': // backend değişken isimlendirmesine göre kontrol et
            counts[ApplicationStatus.preApproved] =
                counts[ApplicationStatus.preApproved]! + 1;
            break;
          case 'approved':
            counts[ApplicationStatus.approved] =
                counts[ApplicationStatus.approved]! + 1;
            break;
          case 'rejected':
            counts[ApplicationStatus.rejected] =
                counts[ApplicationStatus.rejected]! + 1;
            break;
          case 'waitingmanagerapproval':
          case 'waiting_manager_approval':
            counts[ApplicationStatus.waitingManagerApproval] =
                counts[ApplicationStatus.waitingManagerApproval]! + 1;
            break;
          default:
            // Durumu olmayan veya farklı ise sayma
            break;
        }
      }

      setState(() {
        applicationCounts = counts;
      });
    } else {
      debugPrint('Failed to fetch application counts: ${response['message']}');
      setState(() {
        applicationCounts = {
          ApplicationStatus.pending: 0,
          ApplicationStatus.preApproved: 0,
          ApplicationStatus.approved: 0,
          ApplicationStatus.rejected: 0,
          ApplicationStatus.waitingManagerApproval: 0,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>();

    int totalPending = 0;
    if (applicationCounts != null) {
      totalPending = (applicationCounts![ApplicationStatus.pending] ?? 0) +
          (applicationCounts![ApplicationStatus.preApproved] ?? 0) +
          (applicationCounts![ApplicationStatus.waitingManagerApproval] ?? 0);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildDashboardCard(
                'Applications',
                applicationCounts == null ? '0' : totalPending.toString(),
                Icons.assignment,
                context,
                customColors,
                () {
                  Navigator.pushNamed(
                    context,
                    '/company_users',
                    arguments: {'company_id': widget.companyId},
                  );
                },
              ),
              _buildDashboardCard(
                  'Messages', '8', Icons.message, context, customColors, () {}),
            ],
          ),
          const SizedBox(height: 24),
          _buildVisitorChart(context, 'Visitor Chart', customColors),
          const SizedBox(height: 24),
          _buildVisitorChart(context, 'Employee Chart', customColors),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Go to Contact Info',
            icon: Icons.contact_page,
            onPressed: widget.goToContactInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(String title, String count, IconData icon,
      BuildContext context, CustomColors? customColors, VoidCallback? onTap) {
    final theme = Theme.of(context);
    final primaryColor = customColors?.customColor ?? theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 160,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: primaryColor.withAlpha((0.4 * 255).round()),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          splashColor: primaryColor.withAlpha((0.2 * 255).round()),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(icon, size: 32, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      count,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisitorChart(
      BuildContext context, String title, CustomColors? customColors) {
    final theme = Theme.of(context);
    final bgColor = theme.brightness == Brightness.dark
        ? Colors.grey.shade900
        : Colors.grey.shade100;
    final shadowColor = theme.brightness == Brightness.dark
        ? Colors.black54
        : Colors.grey.shade400;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '📊 $title',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
