import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_manager.dart';

class RoleProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _roles = [];

  List<Map<String, dynamic>> get roles => _roles;

  static RoleProvider of(BuildContext context, {bool listen = false}) =>
      Provider.of<RoleProvider>(context, listen: listen);

  Future<void> fetchRoles(BuildContext context) async {
    try {
      final apiManager = Provider.of<ApiManager>(context, listen: false);
      final response = await apiManager.get(context, 'roles');

      if (response['success']) {
        _roles.clear(); // Mevcut rolleri temizle
        _roles.addAll(List<Map<String, dynamic>>.from(response['data']));
        notifyListeners();
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      debugPrint('Error fetching roles: $e');
    }
  }

  String getRoleNameById(int id) {
    final role = _roles.firstWhere((role) => role['id'] == id,
        orElse: () => {'name': 'Guest'});
    return role['name'];
  }
}
