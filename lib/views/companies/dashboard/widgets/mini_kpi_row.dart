import 'package:flutter/material.dart';

class MiniKpiRow extends StatelessWidget {
  final int openJobs;
  final int followers;
  final VoidCallback? onJobsTap;
  final VoidCallback? onFollowersTap;

  const MiniKpiRow({
    super.key,
    required this.openJobs,
    required this.followers,
    this.onJobsTap,
    this.onFollowersTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 560;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MiniKpiChip(
          icon: Icons.badge_outlined,
          label: 'Open Jobs',
          value: openJobs,
          onTap: onJobsTap,
          width: isWide ? 200 : double.infinity,
        ),
        _MiniKpiChip(
          icon: Icons.group_add_outlined,
          label: 'Followers',
          value: followers,
          onTap: onFollowersTap,
          width: isWide ? 200 : double.infinity,
        ),
      ],
    );
  }
}

class _MiniKpiChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final double width;
  final VoidCallback? onTap;

  const _MiniKpiChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    return SizedBox(
      width: width,
      child: Material(
        color: c.surfaceContainerHighest.withAlpha(60),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: c.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    '$value',
                    key: ValueKey('$label-$value'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
