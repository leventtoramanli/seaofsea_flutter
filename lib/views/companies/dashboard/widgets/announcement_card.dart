import 'package:flutter/material.dart';
import 'package:seaofsea/views/companies/dashboard/models/announcement.dart';
import 'package:seaofsea/widgets/online_images.dart';

class AnnouncementCard extends StatelessWidget {
  final Announcement a;
  final bool compact;

  /// Aksiyon callback'leri verildiyse üç nokta menüsü görünür.
  final void Function(Announcement a)? onEdit;
  final void Function(Announcement a, bool toPinned)? onTogglePinned;
  final void Function(Announcement a, bool toHidden)? onToggleHidden;
  final void Function(Announcement a, bool toArchived)? onToggleArchived;

  const AnnouncementCard({
    super.key,
    required this.a,
    this.compact = true,
    this.onEdit,
    this.onTogglePinned,
    this.onToggleHidden,
    this.onToggleArchived,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    final badges = <Widget>[];
    if (a.pinned) {
      badges.add(_chip(context, Icons.push_pin, 'Pinned', c.primary));
    }
    if (a.status != 'active') {
      badges.add(_chip(context, Icons.visibility_off, a.status, c.error));
    }
    if (a.visibility != 'public') {
      badges.add(_chip(context, Icons.lock, a.visibility, c.tertiary));
    }

    final author = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if ((a.authorImage ?? '').isNotEmpty)
          ClipOval(
            child: OnlineImage(
              imagePath: 'images/users/',
              imageName: a.authorImage!,
              sizeW: 20,
              sizeH: 20,
              rounded: true,
            ),
          )
        else
          const CircleAvatar(radius: 10, child: Icon(Icons.person, size: 12)),
        const SizedBox(width: 6),
        Text(
          [a.authorName, a.authorSurname]
              .where((e) => (e ?? '').isNotEmpty)
              .join(' '),
          style: theme.textTheme.labelSmall,
        ),
      ],
    );

    final subtitleText = a.body?.trim().isNotEmpty == true
        ? a.body!.trim()
        : (a.meta?['summary']?.toString() ?? '');

    final hasMenu = onEdit != null ||
        onTogglePinned != null ||
        onToggleHidden != null ||
        onToggleArchived != null;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst satır: başlık + rozetler + menü
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    a.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Wrap(spacing: 6, runSpacing: -6, children: badges),
                if (hasMenu) ...[
                  const SizedBox(width: 4),
                  _MoreMenu(
                    a: a,
                    onEdit: onEdit,
                    onTogglePinned: onTogglePinned,
                    onToggleHidden: onToggleHidden,
                    onToggleArchived: onToggleArchived,
                  ),
                ],
              ],
            ),
            if (subtitleText.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitleText,
                maxLines: compact ? 3 : 6,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                author,
                const Spacer(),
                Text(
                  _formatWhen(a),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.textTheme.bodySmall?.color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label, Color color) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: t.textTheme.labelSmall?.copyWith(color: color)),
      ]),
    );
  }

  String _formatWhen(Announcement a) {
    final d = a.createdAt;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

enum _MenuAction {
  edit,
  pin,
  unpin,
  hide,
  unhide,
  archive,
  unarchive,
}

class _MoreMenu extends StatelessWidget {
  final Announcement a;
  final void Function(Announcement a)? onEdit;
  final void Function(Announcement a, bool toPinned)? onTogglePinned;
  final void Function(Announcement a, bool toHidden)? onToggleHidden;
  final void Function(Announcement a, bool toArchived)? onToggleArchived;

  const _MoreMenu({
    required this.a,
    this.onEdit,
    this.onTogglePinned,
    this.onToggleHidden,
    this.onToggleArchived,
  });

  @override
  Widget build(BuildContext context) {
    final items = <PopupMenuEntry<_MenuAction>>[];

    if (onEdit != null) {
      items.add(
        const PopupMenuItem(
          value: _MenuAction.edit,
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Edit'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
    }

    if (onTogglePinned != null) {
      items.add(
        PopupMenuItem(
          value: a.pinned ? _MenuAction.unpin : _MenuAction.pin,
          child: ListTile(
            leading: Icon(a.pinned ? Icons.push_pin : Icons.push_pin_outlined),
            title: Text(a.pinned ? 'Unpin' : 'Pin'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
    }

    if (onToggleHidden != null) {
      items.add(
        PopupMenuItem(
          value: a.status == 'hidden' ? _MenuAction.unhide : _MenuAction.hide,
          child: ListTile(
            leading: Icon(
                a.status == 'hidden' ? Icons.visibility : Icons.visibility_off),
            title: Text(a.status == 'hidden' ? 'Unhide' : 'Hide'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
    }

    if (onToggleArchived != null) {
      items.add(
        PopupMenuItem(
          value: a.status == 'archived'
              ? _MenuAction.unarchive
              : _MenuAction.archive,
          child: ListTile(
            leading: Icon(a.status == 'archived'
                ? Icons.unarchive
                : Icons.archive_outlined),
            title: Text(a.status == 'archived' ? 'Unarchive' : 'Archive'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
    }

    return PopupMenuButton<_MenuAction>(
      tooltip: 'Actions',
      itemBuilder: (_) => items,
      onSelected: (act) async {
        switch (act) {
          case _MenuAction.edit:
            onEdit?.call(a);
            break;
          case _MenuAction.pin:
            onTogglePinned?.call(a, true);
            break;
          case _MenuAction.unpin:
            onTogglePinned?.call(a, false);
            break;
          case _MenuAction.hide:
            onToggleHidden?.call(a, true);
            break;
          case _MenuAction.unhide:
            onToggleHidden?.call(a, false);
            break;
          case _MenuAction.archive:
            onToggleArchived?.call(a, true);
            break;
          case _MenuAction.unarchive:
            onToggleArchived?.call(a, false);
            break;
        }
      },
      child: const Padding(
        padding: EdgeInsets.only(left: 4),
        child: Icon(Icons.more_vert, size: 20),
      ),
    );
  }
}
