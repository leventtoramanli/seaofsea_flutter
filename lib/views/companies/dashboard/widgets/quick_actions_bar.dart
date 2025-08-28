import 'package:flutter/material.dart';

class QuickActionsBar extends StatelessWidget {
  final bool canManage;
  final VoidCallback onOpenJobs;
  final VoidCallback onPeople;
  final VoidCallback onMessages;
  final VoidCallback onContact;
  final VoidCallback? onInvite;
  final VoidCallback? onSettings;

  const QuickActionsBar({
    super.key,
    required this.canManage,
    required this.onOpenJobs,
    required this.onPeople,
    required this.onMessages,
    required this.onContact,
    this.onInvite,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_QAItem>[
      _QAItem(Icons.badge_outlined, 'Open Jobs', onOpenJobs),
      _QAItem(Icons.people_alt_outlined, 'People', onPeople),
      _QAItem(Icons.message_outlined, 'Messages', onMessages),
      _QAItem(Icons.contact_mail_outlined, 'Contact', onContact),
      if (onInvite != null) _QAItem(Icons.person_add_alt, 'Invite', onInvite!),
      if (onSettings != null) _QAItem(Icons.settings, 'Settings', onSettings!),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items
            .map((i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(i.icon, size: 18),
                    label: Text(i.label),
                    onPressed: i.onTap,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _QAItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _QAItem(this.icon, this.label, this.onTap);
}
