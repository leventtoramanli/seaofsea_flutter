// lib/views/user_settings/privacy_settings.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/screensaver_service.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/utils/auth_provider.dart';

class PrivacySettings extends StatefulWidget {
  const PrivacySettings({super.key});

  @override
  State<PrivacySettings> createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends State<PrivacySettings> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Anchor hedefleri
  final _screenSaverKey = GlobalKey();
  final _changePwdKey = GlobalKey();
  final _sessionCtrlKey = GlobalKey();

  final _scrollController = ScrollController();

  bool _busy = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollTo(GlobalKey key, {double alignment = 0.05}) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: alignment,
    );
  }

  Future<void> _changePassword() async {
    final current = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    if (newPass.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be at least 8 characters'),
        ),
      );
      return;
    }

    setState(() => _busy = true);
    final v1 = Provider.of<V1ApiManager>(context, listen: false);
    final resp = await v1.call(
      module: 'auth',
      action: 'change_password',
      params: {
        'current_password': current,
        'new_password': newPass,
      },
    );
    setState(() => _busy = false);

    if (resp['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please login again.')),
      );
      await Future.delayed(const Duration(seconds: 1));
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.v1logout(allDevices: true);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resp['message'] ?? 'Failed to update password'),
        ),
      );
    }
  }

  Future<void> _logoutAllDevices() async {
    setState(() => _busy = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.v1logout(allDevices: true);
    setState(() => _busy = false);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  // ------- Screensaver helpers -------
  List<Duration> _buildTimeoutOptions(ScreenSaverService svc) {
    final base = <Duration>{
      const Duration(minutes: 1),
      const Duration(minutes: 5),
      const Duration(minutes: 10),
      const Duration(minutes: 15),
      const Duration(minutes: 30),
      const Duration(hours: 1),
    };
    base.add(svc.timeout); // mevcut değer listede yoksa ekle
    final list = base.toList()
      ..sort((a, b) => a.inSeconds.compareTo(b.inSeconds));
    return list;
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    final hours = d.inHours;
    final mins = d.inMinutes % 60;
    if (mins == 0) return '$hours h';
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final ss = context.watch<ScreenSaverService>();

    // Glass panel renkleri — alpha (0–255) ile
    final glassBg = c.surface.withAlpha(220);           // ~86% opak
    final glassBorder = c.outlineVariant.withAlpha(100);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: glassBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: glassBorder),
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.privacy_tip_outlined, size: 48, color: c.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Privacy and Security',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: c.onSurface,
                      ),
                    ),

                    // -------- Anchor buttons --------
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _scrollTo(_screenSaverKey),
                          icon: const Icon(Icons.tv_outlined, size: 18),
                          label: const Text('Screen Saver'),
                          style: _anchorStyle(context),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _scrollTo(_changePwdKey),
                          icon: const Icon(Icons.lock_reset, size: 18),
                          label: const Text('Change Password'),
                          style: _anchorStyle(context),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _scrollTo(_sessionCtrlKey),
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Session Control'),
                          style: _anchorStyle(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // -------------------- Screen Saver --------------------
                    Container(
                      key: _screenSaverKey,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Screen Saver',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SwitchListTile(
                      title: Text('Enable screen saver',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: c.onSurface,
                          )),
                      value: ss.enabled,
                      onChanged: (v) => ss.setEnabled(v),
                    ),
                    const SizedBox(height: 8),

                    // Row: Timeout + Dropdown
                    Row(
                      children: [
                        const SizedBox(width: 18),
                        Text(
                          'Timeout',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: c.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 140),
                          child: DropdownButtonHideUnderline(
                            child: SizedBox(
                              height: 42,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  // Tema ile uyumlu hafif arka plan
                                  filled: true,
                                  fillColor: c.surfaceContainerHighest.withAlpha(60),
                                ),
                                child: DropdownButton<Duration>(
                                  isExpanded: true,
                                  value: ss.timeout,
                                  items: _buildTimeoutOptions(ss)
                                      .map(
                                        (d) => DropdownMenuItem<Duration>(
                                          value: d,
                                          child: Text(_formatDuration(d)),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: ss.enabled
                                      ? (d) {
                                          if (d != null) ss.setTimeout(d);
                                        }
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    SwitchListTile(
                      title: Text(
                        'Require password to unlock',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: c.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        ss.hasPassword()
                            ? 'Password is set'
                            : 'No password set — unlock will dismiss on tap/move',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: c.onSurfaceVariant,
                        ),
                      ),
                      value: ss.lockEnabled,
                      onChanged: (v) => ss.setLockEnabled(v),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () async {
                              final ok = await _showSetScreensaverPasswordDialog(
                                  context, ss);
                              if (ok == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Screen saver password updated')),
                                );
                              }
                            },
                            icon: const Icon(Icons.lock),
                            label: Text(
                              ss.hasPassword()
                                  ? 'Change unlock password'
                                  : 'Set unlock password',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (ss.hasPassword())
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: c.error,
                              foregroundColor: c.onError,
                            ),
                            onPressed: () async {
                              await ss.setPassword('');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Screen saver password cleared')),
                              );
                            },
                            icon: const Icon(Icons.lock_open),
                            label: const Text('Clear password'),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Divider(color: c.outlineVariant.withAlpha(80)),
                    const SizedBox(height: 12),

                    // -------------------- Change Password --------------------
                    Container(
                      key: _changePwdKey,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Change Password',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _glassPasswordField(
                        context, _currentPasswordController, 'Current Password'),
                    const SizedBox(height: 8),
                    _glassPasswordField(
                        context, _newPasswordController, 'New Password'),
                    const SizedBox(height: 8),
                    _glassPasswordField(
                        context, _confirmPasswordController, 'Confirm Password'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _busy ? null : _changePassword,
                      icon: _busy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_reset),
                      label: const Text('Update Password'),
                    ),

                    const SizedBox(height: 24),
                    Divider(color: c.outlineVariant.withAlpha(80)),
                    const SizedBox(height: 12),

                    // -------------------- Session Control --------------------
                    Container(
                      key: _sessionCtrlKey,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Session Control',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: c.error,
                        foregroundColor: c.onError,
                      ),
                      onPressed: _busy ? null : _logoutAllDevices,
                      icon: _busy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.logout),
                      label: const Text('Log out from all devices'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _anchorStyle(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return OutlinedButton.styleFrom(
      foregroundColor: c.primary,
      side: BorderSide(color: c.outlineVariant.withAlpha(100)),
      backgroundColor: c.surfaceContainerHighest.withAlpha(40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _glassPasswordField(
      BuildContext context, TextEditingController controller, String hintText) {
    final c = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      obscureText: true,
      style: TextStyle(color: c.onSurface),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: c.onSurfaceVariant),
        filled: true,
        fillColor: c.surfaceContainerHighest.withAlpha(60),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.outlineVariant.withAlpha(120)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.outlineVariant.withAlpha(120)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.primary),
        ),
      ),
    );
  }

  Future<bool?> _showSetScreensaverPasswordDialog(
      BuildContext context, ScreenSaverService ss) async {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    String p1 = '';
    String p2 = '';
    String? err;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Set unlock password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  obscureText: true,
                  onChanged: (v) => p1 = v,
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  obscureText: true,
                  onChanged: (v) => p2 = v,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (err != null) ...[
                  const SizedBox(height: 8),
                  Text(err!, style: TextStyle(color: c.error)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (p1.isEmpty || p2.isEmpty) {
                    setState(() => err = 'Fill both fields');
                    return;
                  }
                  if (p1 != p2) {
                    setState(() => err = 'Passwords do not match');
                    return;
                  }
                  await ss.setPassword(p1);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
