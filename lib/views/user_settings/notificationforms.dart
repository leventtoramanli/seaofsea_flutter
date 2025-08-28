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
  String? _error;

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
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await api.call(
        module: 'settings',
        action: 'get_notification_settings',
      );

      if (res['success'] == true) {
        final data = res['data'] ?? {};
        if (!mounted) return;
        setState(() {
          _emailNotifications = _toBool(data['email_notifications']);
          _appNotifications = _toBool(data['app_notifications']);
          _weeklySummary = _toBool(data['weekly_summary']);
          _isLoading = false;
          _dirty = false;
        });
      } else {
        throw res['message'] ?? 'Unknown error';
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load settings';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ $e')),
      );
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Notification preferences saved')),
        );
        setState(() => _dirty = false);
      } else {
        throw res['message'] ?? 'Unknown error';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to save settings: $e')),
      );
    }
  }

  // ---- Theme-aware glass switch tile
  Widget _buildGlassSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? subtitle,
    IconData? leadingIcon,
  }) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bg =
        isDark ? c.surface.withOpacity(0.16) : c.surface.withOpacity(0.85);
    final border = c.outlineVariant.withOpacity(isDark ? .28 : .42);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: SwitchListTile.adaptive(
        secondary: leadingIcon == null ? null : Icon(leadingIcon),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: (subtitle == null) ? null : Text(subtitle),
        value: value,
        onChanged: (v) {
          onChanged(v);
          // her değişimde "dirty" işaretle
          setState(() => _dirty = true);
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadNotificationSettings,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final glassBg =
        isDark ? c.surface.withAlpha(46) : c.surface.withAlpha(220);
    final glassBorder = c.outlineVariant.withAlpha(isDark ? 90 : 217);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: glassBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifications',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 12),
                _buildGlassSwitchTile(
                  title: 'Email Notifications',
                  subtitle: 'Get important updates via email.',
                  leadingIcon: Icons.email_outlined,
                  value: _emailNotifications,
                  onChanged: (v) => setState(() => _emailNotifications = v),
                ),
                _buildGlassSwitchTile(
                  title: 'App Notifications',
                  subtitle: 'Receive in-app alerts and push notifications.',
                  leadingIcon: Icons.notifications_none_outlined,
                  value: _appNotifications,
                  onChanged: (v) => setState(() => _appNotifications = v),
                ),
                _buildGlassSwitchTile(
                  title: 'Weekly Summary',
                  subtitle: 'A weekly digest sent once a week.',
                  leadingIcon: Icons.calendar_month_outlined,
                  value: _weeklySummary,
                  onChanged: (v) => setState(() => _weeklySummary = v),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: _dirty ? _saveNotificationSettings : null,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Settings'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _dirty
                          ? () async {
                              // Eski değerleri tekrar yükle
                              await _loadNotificationSettings();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Changes reverted')),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.undo),
                      label: const Text('Revert'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
