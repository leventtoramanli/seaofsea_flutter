// ignore_for_file: use_build_context_synchronously

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';

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

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final apiManager = Provider.of<ApiManager>(context, listen: false);
    try {
      final response =
          await apiManager.post(context, 'get_notification_settings', {});
      if (response != null && response['success'] == true) {
        final data = response['data'] ?? {};
        bool parseBool(dynamic value) => value == true || value == 1;
        setState(() {
          _emailNotifications = parseBool(data['email_notifications']);
          _appNotifications = parseBool(data['app_notifications']);
          _weeklySummary = parseBool(data['weekly_summary']);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Bildirim ayarlarını çekerken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNotificationSettings() async {
    final apiManager = Provider.of<ApiManager>(context, listen: false);
    try {
      await apiManager.post(context, 'save_notification_settings', {
        'email_notifications': _emailNotifications,
        'app_notifications': _appNotifications,
        'weekly_summary': _weeklySummary,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Notification preferences saved')),
      );
    } catch (e) {
      debugPrint('❌ Ayarlar kaydedilirken hata: $e');
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
              border: Border.all(
                color: Colors.white.withAlpha((0.20 * 255).round()),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGlassSwitchTile(
                  title: 'Email Notifications',
                  value: _emailNotifications,
                  onChanged: (value) =>
                      setState(() => _emailNotifications = value),
                ),
                _buildGlassSwitchTile(
                  title: 'App Notifications',
                  value: _appNotifications,
                  onChanged: (value) =>
                      setState(() => _appNotifications = value),
                ),
                _buildGlassSwitchTile(
                  title: 'Weekly Summary',
                  value: _weeklySummary,
                  onChanged: (value) => setState(() => _weeklySummary = value),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _saveNotificationSettings,
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
  required Function(bool) onChanged,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withAlpha((0.15 * 255).round()),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: Colors.white.withAlpha((0.20 * 255).round()),
      ),
    ),
    child: SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    ),
  );
}
