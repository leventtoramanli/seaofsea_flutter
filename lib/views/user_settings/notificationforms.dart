// lib/views/user_settings/notificationforms.dart
// ignore_for_file: use_build_context_synchronously
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';

class NotificationsForm extends StatefulWidget {
  const NotificationsForm({super.key});

  @override
  State<NotificationsForm> createState() => _NotificationsFormState();
}

class _NotificationsFormState extends State<NotificationsForm> {
  bool _emailNotifications = true;
  bool _appNotifications = true;
  bool _weeklySummary = false;
  bool _isLoading = true;
  bool _dirty = false;

  bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v == 1;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final api = Provider.of<V1ApiManager>(context, listen: false);
    try {
      final res = await api.call(
        module: 'settings',
        action: 'get_notification_settings',
      );

      if (res['success'] == true) {
        final data = res['data'] ?? {};
        setState(() {
          _emailNotifications = _toBool(data['email_notifications']);
          _appNotifications   = _toBool(data['app_notifications']);
          _weeklySummary      = _toBool(data['weekly_summary']);
          _isLoading = false;
          _dirty = false;
        });
      } else {
        throw res['message'] ?? 'Unknown error';
      }
    } catch (e) {
      debugPrint('⚠️ Fetch error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNotificationSettings() async {
    final api = Provider.of<V1ApiManager>(context, listen: false);
    try {
      final res = await api.call(
        module: 'settings',
        action: 'save_notification_settings',
        params: {
          'email_notifications': _emailNotifications,
          'app_notifications': _appNotifications,
          'weekly_summary': _weeklySummary,
        },
      );

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Notification preferences saved')),
        );
        setState(() => _dirty = false);
      } else {
        throw res['message'] ?? 'Unknown error';
      }
    } catch (e) {
      debugPrint('❌ Save error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to save settings: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.15 * 255).round()),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha((0.20 * 255).round())),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGlassSwitchTile(
                  title: 'Email Notifications',
                  value: _emailNotifications,
                  onChanged: (v) => setState(() { _emailNotifications = v; _dirty = true; }),
                ),
                _buildGlassSwitchTile(
                  title: 'App Notifications',
                  value: _appNotifications,
                  onChanged: (v) => setState(() { _appNotifications = v; _dirty = true; }),
                ),
                _buildGlassSwitchTile(
                  title: 'Weekly Summary',
                  value: _weeklySummary,
                  onChanged: (v) => setState(() { _weeklySummary = v; _dirty = true; }),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _dirty ? _saveNotificationSettings : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildGlassSwitchTile({
  required String title,
  required bool value,
  required ValueChanged<bool> onChanged,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withAlpha((0.15 * 255).round()),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.white.withAlpha((0.20 * 255).round())),
    ),
    child: SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    ),
  );
}
