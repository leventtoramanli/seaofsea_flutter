import 'package:flutter/material.dart';
import 'package:seaofsea/views/companies/dashboard/widgets/contact_line.dart';

class ContactSummaryCard extends StatelessWidget {
  final Map<String, List<Map<String, String>>> contact;
  final VoidCallback? onEdit;

  // Callbacks:
  final void Function(Map<String, String>) onPhoneTap;
  final void Function(Map<String, String>) onEmailTap;
  final void Function(Map<String, String>) onWebsiteTap;
  final void Function(Map<String, String>) onAddressTap;

  const ContactSummaryCard({
    super.key,
    required this.contact,
    this.onEdit,
    required this.onPhoneTap,
    required this.onEmailTap,
    required this.onWebsiteTap,
    required this.onAddressTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget section(
      String title,
      IconData icon,
      List<Map<String, String>> items,
      void Function(Map<String, String>) onTap,
    ) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 6),
            if (items.isEmpty)
              Text('—', style: theme.textTheme.bodyMedium)
            else
              Column(
                children: items.take(6).map((m) {
                  final label = (m['label'] ?? '').trim();
                  final value = (m['value'] ?? '').trim();
                  return ContactLine(
                    label: label,
                    value: value,
                    onTap: () => onTap(m),
                  );
                }).toList(),
              ),
          ],
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.contact_mail_outlined),
                const SizedBox(width: 8),
                Text('Contact', style: theme.textTheme.titleMedium),
                const Spacer(),
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            section('Phone', Icons.phone_outlined,
                contact['phones'] ?? const [], onPhoneTap),
            section('Email', Icons.email_outlined,
                contact['emails'] ?? const [], onEmailTap),
            section('Website', Icons.language, contact['websites'] ?? const [],
                onWebsiteTap),
            section('Address', Icons.place_outlined,
                contact['addresses'] ?? const [], onAddressTap),
          ],
        ),
      ),
    );
  }
}
