import 'package:flutter/material.dart';

class CompanyHeader extends StatelessWidget {
  final Map<String, dynamic> company;
  final Widget logoWidget;
  final Widget adminButtons;
  final Widget actionButtons;

  const CompanyHeader({
    super.key,
    required this.company,
    required this.logoWidget,
    required this.adminButtons,
    required this.actionButtons,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest, // modern M3 tonu
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Logo
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: logoWidget,
            ),

            // Ad + (istersen çok küçük bir alt başlık)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (company['name'] ?? 'Company').toString(),
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((company['tagline'] ?? '').toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        company['tagline'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            // Aksiyonlar (sağa yaslı, sıkı aralıklı)
            const SizedBox(width: 12),
            OverflowBar(
              spacing: 4,
              overflowAlignment: OverflowBarAlignment.end,
              children: [
                adminButtons,
                const SizedBox(width: 6),
                actionButtons,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
