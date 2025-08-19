// lib/utils/role_caps.dart
class RoleCaps {
  final String role; // admin|editor|viewer|follower|none

  RoleCaps._(this.role);

  factory RoleCaps.from(String? role) {
    final r = (role ?? 'none').toLowerCase().trim();
    switch (r) {
      case 'admin':
      case 'editor':
      case 'viewer':
      case 'follower':
        return RoleCaps._(r);
      default:
        return RoleCaps._('none');
    }
  }

  bool get isAdmin => role == 'admin';
  bool get isEditor => role == 'editor';
  bool get isViewer => role == 'viewer';
  bool get isFollower => role == 'follower';

  bool get isEmployee => isAdmin || isEditor || isViewer;

  // Ekran yetenekleri (UI kilidi)
  bool get canSeeDashboard => isAdmin || isEditor;
  bool get canEditContact => isAdmin || isEditor;
  bool get canEditTypes => isAdmin || isEditor;
  bool get canApplyJob => isViewer || isFollower;
  bool get showWorkspace => isEmployee;
}
