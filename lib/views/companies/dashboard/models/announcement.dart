class Announcement {
  final int id;
  final int companyId;
  final int? authorUserId;
  final String visibility; // public|followers|internal
  final String status; // active|hidden|archived
  final bool pinned;
  final String title;
  final String? body;
  final Map<String, dynamic>? meta;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime createdAt;

  // (opsiyonel) vitrin için
  final String? authorName;
  final String? authorSurname;
  final String? authorImage;

  Announcement({
    required this.id,
    required this.companyId,
    required this.visibility,
    required this.status,
    required this.pinned,
    required this.title,
    required this.createdAt,
    this.authorUserId,
    this.body,
    this.meta,
    this.startsAt,
    this.endsAt,
    this.authorName,
    this.authorSurname,
    this.authorImage,
  });

  factory Announcement.fromMap(Map<String, dynamic> m) {
    DateTime? _dt(v) => v == null || v.toString().trim().isEmpty
        ? null
        : DateTime.parse(v.toString().replaceFirst(' ', 'T'));
    return Announcement(
      id: int.parse('${m['id']}'),
      companyId: int.parse('${m['company_id']}'),
      authorUserId: m['author_user_id'] == null
          ? null
          : int.tryParse('${m['author_user_id']}'),
      visibility: (m['visibility'] ?? 'public').toString(),
      status: (m['status'] ?? 'active').toString(),
      pinned: (m['pinned'].toString() == '1' ||
          m['pinned'].toString().toLowerCase() == 'true'),
      title: (m['title'] ?? '').toString(),
      body: (m['body'] ?? '').toString().isEmpty
          ? null
          : (m['body'] ?? '').toString(),
      meta: (m['meta'] is Map) ? Map<String, dynamic>.from(m['meta']) : null,
      startsAt: _dt(m['starts_at']),
      endsAt: _dt(m['ends_at']),
      createdAt: _dt(m['created_at']) ?? DateTime.now(),
      authorName: m['author_name']?.toString(),
      authorSurname: m['author_surname']?.toString(),
      authorImage: m['author_image']?.toString(),
    );
  }
}

class AnnouncementListResult {
  final List<Announcement> items;
  final int total;
  AnnouncementListResult(this.items, this.total);
}
