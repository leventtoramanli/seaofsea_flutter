// views/companies/company_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/utils/theme_data.dart';
import 'package:seaofsea/widgets/custom_button.dart';

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

enum ApplicationStatus {
  pending,
  preApproved,
  approved,
  rejected,
  waitingManagerApproval
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  Map<ApplicationStatus, int>? applicationCounts;
  bool _loading = false;

  static const Map<ApplicationStatus, String> _statusParam = {
    ApplicationStatus.pending: 'pending',
    ApplicationStatus.preApproved: 'pre_approved',
    ApplicationStatus.approved: 'approved',
    ApplicationStatus.rejected: 'rejected',
    ApplicationStatus.waitingManagerApproval: 'waiting_manager_approval',
  };

  @override
  void initState() {
    super.initState();
    _fetchApplicationCounts();
  }

  Future<void> _fetchApplicationCounts() async {
    setState(() => _loading = true);
    final v1 = context.read<V1ApiManager>();

    Future<int> fetchTotal(String? status) async {
      final res = await v1.call(
        module: 'company',
        action: 'members_list',
        params: {
          'company_id': widget.companyId,
          if (status != null) 'status': status,
          'perPage': 1, // sadece total lazım
          'page': 1,
        },
        context: context,
      );

      if (res['success'] != true) {
        // hata göster ama 0 say
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(res['message']?.toString() ?? 'Load failed')),
          );
        }
        return 0;
      }

      final data = res['data'];
      if (data is Map && data['total'] is int) return data['total'] as int;
      // bazı router şekillerinde int total string olabilir
      if (data is Map && data['total'] != null) {
        final t = int.tryParse(data['total'].toString());
        if (t != null) return t;
      }
      // fallback: items say
      if (data is Map && data['items'] is List)
        return (data['items'] as List).length;
      if (data is List) return data.length;
      return 0;
    }

    try {
      final results = await Future.wait<int>([
        fetchTotal(_statusParam[ApplicationStatus.pending]),
        fetchTotal(_statusParam[ApplicationStatus.preApproved]),
        fetchTotal(_statusParam[ApplicationStatus.approved]),
        fetchTotal(_statusParam[ApplicationStatus.rejected]),
        fetchTotal(_statusParam[ApplicationStatus.waitingManagerApproval]),
      ]);

      final counts = <ApplicationStatus, int>{
        ApplicationStatus.pending: results[0],
        ApplicationStatus.preApproved: results[1],
        ApplicationStatus.approved: results[2],
        ApplicationStatus.rejected: results[3],
        ApplicationStatus.waitingManagerApproval: results[4],
      };

      if (!mounted) return;
      setState(() => applicationCounts = counts);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>();

    final int totalPending = (applicationCounts == null)
        ? 0
        : (applicationCounts![ApplicationStatus.pending] ?? 0) +
            (applicationCounts![ApplicationStatus.preApproved] ?? 0) +
            (applicationCounts![ApplicationStatus.waitingManagerApproval] ?? 0);

    return RefreshIndicator(
      onRefresh: _fetchApplicationCounts,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Kısa loading hali
            if (_loading && applicationCounts == null)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(2, (_) => _skeletonCard(context)),
              ),

            if (!_loading || applicationCounts != null)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildDashboardCard(
                    'Applications',
                    applicationCounts == null ? '—' : totalPending.toString(),
                    Icons.assignment,
                    context,
                    customColors,
                    () => Navigator.pushNamed(
                      context,
                      '/company_users',
                      arguments: {
                        'company_id': widget.companyId,
                        // pending benzeri statüler için sayfada filtrelemek istersen:
                        'status': 'pending',
                      },
                    ),
                  ),
                  _buildDashboardCard(
                    'Messages',
                    '—', // istersen sayıyı list çağrısı ile doldururuz
                    Icons.message,
                    context,
                    customColors,
                    () =>
                        Navigator.pushNamed(context, '/company_notifications'),
                  ),
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
      ),
    );
  }

  Widget _buildDashboardCard(
    String title,
    String count,
    IconData icon,
    BuildContext context,
    CustomColors? customColors,
    VoidCallback? onTap,
  ) {
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

  Widget _skeletonCard(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 160,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: 110,
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          child: Container(
            height: 16,
            width: 80,
            decoration: BoxDecoration(
              color: theme.disabledColor.withOpacity(.2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisitorChart(
    BuildContext context,
    String title,
    CustomColors? customColors,
  ) {
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
          )
        ],
      ),
      child: Center(
        child: Text(
          '📊 $title',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
