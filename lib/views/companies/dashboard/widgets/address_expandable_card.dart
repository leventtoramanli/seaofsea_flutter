import 'package:flutter/material.dart';

class AddressExpandableCard extends StatelessWidget {
  final String addressText;
  final VoidCallback onOpenMap;
  final VoidCallback onCopy;

  const AddressExpandableCard({
    super.key,
    required this.addressText,
    required this.onOpenMap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openExpanded(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _iconBadge(context),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  addressText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onOpenMap,
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Open on map'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBadge(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: c.primaryContainer.withAlpha(140),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.place_outlined, size: 24, color: c.onPrimaryContainer),
    );
  }

  void _openExpanded(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.only(top: topInset),
          child: _ExpandedPanel(
            addressText: addressText,
            onOpenMap: onOpenMap,
            onCopy: onCopy,
          ),
        );
      },
    );
  }
}

class _ExpandedPanel extends StatelessWidget {
  final String addressText;
  final VoidCallback onOpenMap;
  final VoidCallback onCopy;

  const _ExpandedPanel({
    required this.addressText,
    required this.onOpenMap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (ctx, scroll) {
        return Material(
          elevation: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 4,
                width: 44,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.place_outlined),
                title: const Text('Address'),
                subtitle: Text(addressText),
              ),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withAlpha(24),
                            theme.colorScheme.secondary.withAlpha(18),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.map_outlined,
                        size: 64,
                        color: theme.colorScheme.primary.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    FilledButton.icon(
                      onPressed: onOpenMap,
                      icon: const Icon(Icons.directions_outlined),
                      label: const Text('Open on map'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onCopy,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  children: [
                    Text(
                      'Tip: Once you open the address, you can get directions, share it, or add it to your favorites.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
