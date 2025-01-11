class RoleManager {
  static const String anonymous = 'Anonymous';
  static const String user = 'User';
  static const String admin = 'Admin';
  static const String moderator = 'Moderator';

  static String getRoleDescription(String role) {
    switch (role) {
      case admin:
        return 'Admin';
      case moderator:
        return 'Moderator';
      case user:
        return 'Standard User';
      case anonymous:
      default:
        return 'Guest';
    }
  }

  static bool hasAccess(String role, String requiredRole) {
    const roleHierarchy = [anonymous, user, moderator, admin];
    return roleHierarchy.indexOf(role) >= roleHierarchy.indexOf(requiredRole);
  }
}
