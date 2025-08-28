import 'package:flutter/material.dart';
import 'package:seaofsea/views/companies/dashboard/models/dashboard_models.dart';

class Workboard extends StatelessWidget {
  final String role; // admin|editor|viewer|follower|none
  final bool loading;
  final Map<ApplicationStatus, int>? applicationCounts;
  final VoidCallback onViewAllApplications;
  final VoidCallback onViewAllMessages;
  final VoidCallback onViewAllJobs;

  const Workboard({
    super.key,
    required this.role,
    required this.loading,
    required this.applicationCounts,
    required this.onViewAllApplications,
    required this.onViewAllMessages,
    required this.onViewAllJobs,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    final isEditor = role == 'editor';
    final isEmployee = isAdmin || isEditor || role == 'viewer';
    final isVisitorOrFollower = !isEmployee;

    final tabs = isVisitorOrFollower
        ? const [Tab(text: 'Open Jobs'), Tab(text: 'Updates')]
        : const [
            Tab(text: 'Applications'),
            Tab(text: 'Approvals'),
            Tab(text: 'Messages')
          ];

    final pendingLike = (applicationCounts == null)
        ? null
        : (applicationCounts![ApplicationStatus.pending] ?? 0) +
            (applicationCounts![ApplicationStatus.preApproved] ?? 0) +
            (applicationCounts![ApplicationStatus.waitingManagerApproval] ?? 0);

    return DefaultTabController(
      length: tabs.length,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      isScrollable: true,
                      tabs: tabs,
                    ),
                  ),
                  if (!isVisitorOrFollower)
                    TextButton(
                      onPressed: onViewAllApplications,
                      child: const Text('View all'),
                    )
                  else
                    TextButton(
                      onPressed: onViewAllJobs,
                      child: const Text('View all'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 230,
              child: TabBarView(
                children: isVisitorOrFollower
                    ? [
                        const _WorkListPlaceholder(
                          icon: Icons.badge_outlined,
                          title: 'Open positions will appear here',
                        ),
                        const _WorkListPlaceholder(
                          icon: Icons.campaign_outlined,
                          title: 'Company updates will appear here',
                        ),
                      ]
                    : [
                        _WorkListPlaceholder(
                          icon: Icons.assignment_outlined,
                          title: 'Applications awaiting action',
                          loading: loading,
                          count: pendingLike,
                        ),
                        const _WorkListPlaceholder(
                          icon: Icons.verified_outlined,
                          title: 'Approvals queue',
                        ),
                        const _WorkListPlaceholder(
                          icon: Icons.message_outlined,
                          title: 'Recent messages',
                        ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkListPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool loading;
  final int? count;
  const _WorkListPlaceholder({
    required this.icon,
    required this.title,
    this.loading = false,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: loading
          ? CircularProgressIndicator(color: theme.colorScheme.primary)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 32),
                const SizedBox(height: 8),
                Text(title, style: theme.textTheme.titleMedium),
                if (count != null) ...[
                  const SizedBox(height: 4),
                  Text('$count item(s)', style: theme.textTheme.bodyMedium),
                ]
              ],
            ),
    );
  }
}
