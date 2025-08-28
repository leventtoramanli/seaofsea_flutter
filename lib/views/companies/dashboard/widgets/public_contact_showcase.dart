import 'package:flutter/material.dart';

class PublicContactShowcase extends StatelessWidget {
  final Map<String, List<Map<String, String>>> contact;

  final void Function(Map<String, String>) onPhoneTap;
  final void Function(Map<String, String>) onEmailTap;
  final void Function(Map<String, String>) onWebsiteTap;
  final void Function(Map<String, String>) onAddressTap;

  const PublicContactShowcase({
    super.key,
    required this.contact,
    required this.onPhoneTap,
    required this.onEmailTap,
    required this.onWebsiteTap,
    required this.onAddressTap,
  });

  @override
  Widget build(BuildContext context) {
    final phones = contact['phones'] ?? const <Map<String, String>>[];
    final emails = contact['emails'] ?? const <Map<String, String>>[];
    final websites = contact['websites'] ?? const <Map<String, String>>[];
    final addresses = contact['addresses'] ?? const <Map<String, String>>[];

    final cards = <_ContactCardData>[
      _ContactCardData(
        icon: Icons.phone_outlined,
        title: 'Phone',
        items: phones,
        onTap: onPhoneTap,
      ),
      _ContactCardData(
        icon: Icons.email_outlined,
        title: 'Email',
        items: emails,
        onTap: onEmailTap,
      ),
      _ContactCardData(
        icon: Icons.language,
        title: 'Website',
        items: websites,
        onTap: onWebsiteTap,
      ),
      _ContactCardData(
        icon: Icons.place_outlined,
        title: 'Address',
        items: addresses,
        onTap: onAddressTap,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final maxW = c.maxWidth;
        final isTwoCols = maxW >= 640; // genişse 2x2 grid
        return GridView.builder(
          shrinkWrap: true,
          primary: false,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTwoCols ? 2 : 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isTwoCols ? 2.4 : 2.0,
          ),
          itemCount: cards.length,
          itemBuilder: (_, i) => _ContactCard(data: cards[i]),
        );
      },
    );
  }
}

class _ContactCardData {
  final IconData icon;
  final String title;
  final List<Map<String, String>> items;
  final void Function(Map<String, String>) onTap;
  _ContactCardData({
    required this.icon,
    required this.title,
    required this.items,
    required this.onTap,
  });
}

class _ContactCard extends StatelessWidget {
  final _ContactCardData data;
  const _ContactCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = data.items.isNotEmpty ? data.items.first : null;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: first == null ? null : () => data.onTap(first),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _IconBadge(icon: data.icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(data.title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    if (first == null)
                      Text('—', style: theme.textTheme.bodyMedium)
                    else
                      Text(
                        _formatValue(first),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.2,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (first != null)
                    TextButton(
                      onPressed: () => data.onTap(first),
                      child: const Text('Open'),
                    ),
                  if (data.items.length > 1)
                    TextButton(
                      onPressed: () => _showAll(context, data),
                      child: const Text('See all'),
                    ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  static String _formatValue(Map<String, String> item) {
    final label = (item['label'] ?? '').trim();
    final value = (item['value'] ?? '').trim();
    return label.isEmpty ? value : '$label: $value';
  }

  void _showAll(BuildContext context, _ContactCardData d) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title:
                  Text(d.title, style: Theme.of(context).textTheme.titleMedium),
              leading: Icon(d.icon),
            ),
            const Divider(height: 1),
            ...d.items.map((m) {
              final label = (m['label'] ?? '').trim();
              final value = (m['value'] ?? '').trim();

              return ListTile(
                leading: const Icon(Icons.open_in_new),
                title: Text(value),
                subtitle: label.isEmpty ? null : Text(label),
                onTap: () {
                  Navigator.pop(context);
                  d.onTap(m);
                },
              );
            }).toList(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  const _IconBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: c.primaryContainer.withAlpha(140),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: c.primary.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, size: 24, color: c.onPrimaryContainer),
    );
  }
}
