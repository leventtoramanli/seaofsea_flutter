import 'package:flutter/material.dart';
import 'package:seaofsea/utils/theme_data.dart'; // CustomColors extension varsa

class KpiGrid extends StatelessWidget {
  final bool loading;
  final List<KpiTile> tiles;
  const KpiGrid({super.key, required this.loading, required this.tiles});

  @override
  Widget build(BuildContext context) {
    final skeletons = List.generate(
      4,
      (_) => KpiCard(
        icon: Icons.hourglass_empty,
        title: '—',
        value: null,
        loading: true,
        onTap: null,
      ),
    );

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: (loading
          ? skeletons
          : tiles
              .map((t) => KpiCard(
                    icon: t.icon,
                    title: t.title,
                    value: t.value,
                    loading: false,
                    onTap: t.onTap,
                  ))
              .toList()),
    );
  }
}

class KpiTile {
  final IconData icon;
  final String title;
  final int? value; // null => skeleton
  final VoidCallback? onTap;
  KpiTile({required this.icon, required this.title, this.value, this.onTap});
}

class KpiCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? value;
  final bool loading;
  final VoidCallback? onTap;
  const KpiCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>();
    final primaryColor = customColors?.customColor ?? theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 170,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: primaryColor.withAlpha(64),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 28, color: primaryColor),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: loading
                      ? Container(
                          key: const ValueKey('sk'),
                          height: 18,
                          width: 50,
                          decoration: BoxDecoration(
                            color: theme.disabledColor.withAlpha(50),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        )
                      : Text(
                          '${value ?? 0}',
                          key: const ValueKey('vl'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
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
}
