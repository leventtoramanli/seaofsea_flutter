import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/views/companies/dashboard/controller/dashboard_controller.dart';
import 'package:seaofsea/views/companies/dashboard/widgets/announcements_section.dart';
import 'package:seaofsea/views/companies/dashboard/widgets/updates_card.dart';

class AnnouncementsSlot extends StatelessWidget {
  final int companyId;
  final Widget? emptyPlaceholder; // varsayılan: UpdatesCard
  final Widget? loadingPlaceholder; // küçük skeleton
  final EdgeInsetsGeometry? padding; // kullanmak istersen

  const AnnouncementsSlot({
    super.key,
    required this.companyId,
    this.emptyPlaceholder,
    this.loadingPlaceholder,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DashboardController>();

    final loading = ctrl.announcementsLoading;
    final items = ctrl.announcements;

    Widget child;
    if (loading) {
      child = loadingPlaceholder ?? const _AnnouncementsSkeleton();
    } else if (items.isEmpty) {
      child = emptyPlaceholder ?? const UpdatesCard();
    } else {
      child = AnnouncementsSection(companyId: companyId);
    }

    if (padding != null) {
      return Padding(padding: padding!, child: child);
    }
    return child;
  }
}

class _AnnouncementsSkeleton extends StatelessWidget {
  const _AnnouncementsSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: List.generate(3, (i) => i).map((_) {
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            height: 90,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(theme, width: 180, height: 16),
                const SizedBox(height: 8),
                _shimmerBox(theme, width: double.infinity, height: 12),
                const SizedBox(height: 6),
                _shimmerBox(theme,
                    width: MediaQuery.of(context).size.width * .5, height: 12),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _shimmerBox(ThemeData theme,
      {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(.5),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
