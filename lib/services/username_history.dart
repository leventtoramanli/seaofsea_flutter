import 'package:shared_preferences/shared_preferences.dart';

class UsernameHistory {
  static const _kKey = 'username_history';
  static const _maxItems = 10;

  static Future<List<String>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kKey) ?? <String>[];
  }

  static Future<void> add(String username) async {
    final v = username.trim();
    if (v.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kKey) ?? <String>[];
    list.removeWhere((e) => e.toLowerCase() == v.toLowerCase());
    list.insert(0, v);
    if (list.length > _maxItems) {
      list.removeRange(_maxItems, list.length);
    }
    await prefs.setStringList(_kKey, list);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
  }
}
