import 'package:flutter/material.dart';

class PublicContactStrip extends StatelessWidget {
  final Map<String, List<Map<String, String>>> contact;
  final void Function(Map<String, String>) onPhoneTap;
  final void Function(Map<String, String>) onEmailTap;
  final void Function(Map<String, String>) onWebsiteTap;

  const PublicContactStrip({
    super.key,
    required this.contact,
    required this.onPhoneTap,
    required this.onEmailTap,
    required this.onWebsiteTap,
  });

  @override
  Widget build(BuildContext context) {
    final phones = contact['phones'] ?? const <Map<String, String>>[];
    final emails = contact['emails'] ?? const <Map<String, String>>[];
    final webs = contact['websites'] ?? const <Map<String, String>>[];

    final chips = <Widget>[
      _chip(
        context,
        icon: Icons.phone_outlined,
        label: _formatFirst(phones, placeholder: 'Phone'),
        onTap: phones.isEmpty ? null : () => onPhoneTap(phones.first),
        moreCount: phones.length > 1 ? phones.length - 1 : 0,
        onSeeAll: phones.length > 1
            ? () => _showAll(
                context, 'Phone', Icons.phone_outlined, phones, onPhoneTap)
            : null,
      ),
      _chip(
        context,
        icon: Icons.email_outlined,
        label: _formatFirst(emails, placeholder: 'Email'),
        onTap: emails.isEmpty ? null : () => onEmailTap(emails.first),
        moreCount: emails.length > 1 ? emails.length - 1 : 0,
        onSeeAll: emails.length > 1
            ? () => _showAll(
                context, 'Email', Icons.email_outlined, emails, onEmailTap)
            : null,
      ),
      _chip(
        context,
        icon: Icons.language,
        label: _formatFirst(webs, placeholder: 'Website'),
        onTap: webs.isEmpty ? null : () => onWebsiteTap(webs.first),
        moreCount: webs.length > 1 ? webs.length - 1 : 0,
        onSeeAll: webs.length > 1
            ? () =>
                _showAll(context, 'Website', Icons.language, webs, onWebsiteTap)
            : null,
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  String _formatFirst(List<Map<String, String>> items,
      {required String placeholder}) {
    if (items.isEmpty) return placeholder;
    final m = items.first;
    final label = (m['label'] ?? '').trim();
    final value = (m['value'] ?? '').trim();
    return label.isEmpty ? value : '$label: $value';
  }

  Widget _chip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required int moreCount,
    required VoidCallback? onSeeAll,
  }) {
    final theme = Theme.of(context);
    final base = ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );

    if (moreCount <= 0 || onSeeAll == null) return base;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        base,
        const SizedBox(width: 4),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onSeeAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              '+$moreCount',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  void _showAll(
    BuildContext context,
    String title,
    IconData icon,
    List<Map<String, String>> items,
    void Function(Map<String, String>) onTap,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: Icon(icon), title: Text(title)),
            const Divider(height: 1),
            ...items.map((m) {
              final label = (m['label'] ?? '').trim();
              final value = (m['value'] ?? '').trim();
              return ListTile(
                leading: const Icon(Icons.open_in_new),
                title: Text(value),
                subtitle: label.isEmpty ? null : Text(label),
                onTap: () {
                  Navigator.pop(context);
                  onTap(m);
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
