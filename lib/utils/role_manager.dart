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

  /// **🔍 API için erişim kontrolü**
  static bool isAuthorized(String role, String endpoint) {
    final restrictedEndpoints = {
      'update_user': user,
      'upload_image': user,
      'admin_dashboard': admin,
    };

    if (!restrictedEndpoints.containsKey(endpoint)) {
      return true; // Genel erişime açık endpointler
    }

    return hasAccess(role, restrictedEndpoints[endpoint]!);
  }
}
