import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/views/companies/announcements/company_announcements_page.dart';
import 'package:seaofsea/views/companies/dashboard/services/announcements_service.dart';
import 'package:seaofsea/views/companies/dashboard/widgets/announcement_form.dart';

class AnnouncementsSection extends StatefulWidget {
  final int companyId;
  final int limit; // kartta kaç kayıt gösterelim (örn. 3)
  final EdgeInsetsGeometry padding;

  const AnnouncementsSection({
    super.key,
    required this.companyId,
    this.limit = 3,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  State<AnnouncementsSection> createState() => _AnnouncementsSectionState();
}

class _AnnouncementsSectionState extends State<AnnouncementsSection> {
  bool _loading = true;
  bool _canCreate = false;
  String? _error;
  List<AnnouncementItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = context.announcementsService();

      // Sunucudan 10 çekelim, kartta limit kadar gösterelim
      final items = await svc.fetchLatest(
        companyId: widget.companyId,
        limit: 10,
        context: context,
      );

      // Kullanıcı yeni anons oluşturabilir mi?
      final canCreate = await svc.canCreate(
        companyId: widget.companyId,
        context: context,
      );

      if (!mounted) return;
      setState(() {
        _items = items.where((e) => e.status == 'active').toList();
        _canCreate = canCreate;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load announcements';
        _loading = false;
      });
    }
  }

  void _seeAll() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyAnnouncementsPage(companyId: widget.companyId),
      ),
    );
  }

  void _createNew() async {
    // Yeni duyuru formunu alt sayfa olarak aç
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        return Padding(
          // klavye üstüne düzgün otursun
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: AnnouncementFormCard(
            companyId: widget.companyId,
            onCancel: () => Navigator.of(context).pop(false),
            onCreated: (_) => Navigator.of(context).pop(true),
          ),
        );
      },
    );

    // Başarıyla oluşturulduysa listeyi tazele
    if (!mounted) return;
    if (created == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement published')),
      );
      _load(); // yeniden çek
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final header = Row(
      children: [
        const Icon(Icons.campaign_outlined, size: 20),
        const SizedBox(width: 8),
        Text('Announcements', style: theme.textTheme.titleMedium),
        const Spacer(),
        if (_canCreate)
          IconButton(
            onPressed: _createNew,
            icon: const Icon(Icons.add, size: 18),
          ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: (_items.isNotEmpty && !_loading) ? _seeAll : null,
          child: const Text('See all'),
        ),
      ],
    );

    Widget body;
    if (_loading) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            const SizedBox(width: 8),
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text('Loading…', style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    } else if (_error != null) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(_error!, style: theme.textTheme.bodyMedium)),
            const SizedBox(width: 8),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    } else if (_items.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            const Icon(Icons.notifications_none),
            const SizedBox(width: 8),
            Text('No announcements yet.', style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    } else {
      final shown = _items.take(widget.limit).toList();
      body = Column(
        children: [
          ...List.generate(shown.length, (i) {
            final a = shown[i];
            return _AnnouncementTile(item: a);
          }),
          if (_items.length > shown.length)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '+${_items.length - shown.length} more',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
        ],
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        // min-height: boş/az içerikte bile yüksekliği korur
        constraints: const BoxConstraints(minHeight: 140),
        child: Padding(
          padding: widget.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const Divider(height: 12),
              body,
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final AnnouncementItem item;
  const _AnnouncementTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ts = _relTime(item.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.pinned ? Icons.push_pin : Icons.campaign_outlined,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.pinned)
                      Chip(
                        label: const Text('Pinned'),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                  ],
                ),
                if ((item.body ?? '').trim().isNotEmpty)
                  Text(
                    item.body!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                if (ts != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      ts,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _relTime(DateTime? dt) {
    if (dt == null) return null;
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    String _2(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${_2(dt.month)}-${_2(dt.day)}';
  }
}
