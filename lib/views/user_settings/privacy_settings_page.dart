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
      alignment: alignment, // 0.0 başa yapıştırır; 0.05 az boşluk bırakır
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
            content: Text('New password must be at least 8 characters')),
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
        SnackBar(content: Text(resp['message'] ?? 'Failed to update password')),
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
    final ss = context.watch<ScreenSaverService>();

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
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.privacy_tip_outlined,
                        size: 48, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'Privacy and Security',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),

                    // -------- Anchor butonları --------
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _scrollTo(_screenSaverKey),
                          icon: const Icon(Icons.tv_outlined, size: 18),
                          label: const Text('Screen Saver'),
                          style: _anchorStyle(),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _scrollTo(_changePwdKey),
                          icon: const Icon(Icons.lock_reset, size: 18),
                          label: const Text('Change Password'),
                          style: _anchorStyle(),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _scrollTo(_sessionCtrlKey),
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Session Control'),
                          style: _anchorStyle(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // -------------------- Screen Saver --------------------
                    Container(
                      key: _screenSaverKey,
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Screen Saver',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SwitchListTile(
                      title: const Text('Enable screen saver',
                          style: TextStyle(color: Colors.white)),
                      value: ss.enabled,
                      onChanged: (v) => ss.setEnabled(v),
                    ),
                    const SizedBox(height: 8),

                    // Row: solda başlık, sağda dropdown (sabit genişlik)
                    Row(
                      children: [
                        const SizedBox(width: 18),
                        const Text('Timeout',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500)),
                        const Spacer(),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: DropdownButtonHideUnderline(
                            child: Container(
                              height: 42,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(),
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
                      title: const Text('Require password to unlock',
                          style: TextStyle(color: Colors.white)),
                      subtitle: Text(
                        ss.hasPassword()
                            ? 'Password is set'
                            : 'No password set — unlock will dismiss on tap/move',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      value: ss.lockEnabled,
                      onChanged: (v) => ss.setLockEnabled(v),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final ok =
                                  await _showSetScreensaverPasswordDialog(
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
                            label: Text(ss.hasPassword()
                                ? 'Change unlock password'
                                : 'Set unlock password'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (ss.hasPassword())
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent),
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
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),

                    // -------------------- Change Password --------------------
                    Container(
                      key: _changePwdKey,
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Change Password',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _glassField(_currentPasswordController, 'Current Password'),
                    const SizedBox(height: 8),
                    _glassField(_newPasswordController, 'New Password'),
                    const SizedBox(height: 8),
                    _glassField(_confirmPasswordController, 'Confirm Password'),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _busy ? null : _changePassword,
                      icon: const Icon(Icons.lock_reset),
                      label: _busy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Update Password'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent),
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),

                    // -------------------- Session Control --------------------
                    Container(
                      key: _sessionCtrlKey,
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Session Control',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _busy ? null : _logoutAllDevices,
                      icon: const Icon(Icons.logout),
                      label: _busy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Log out from all devices'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent),
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

  ButtonStyle _anchorStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: BorderSide(color: Colors.white.withOpacity(0.25)),
      backgroundColor: Colors.white.withOpacity(0.06),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _glassField(TextEditingController controller, String hintText) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withAlpha((0.15 * 255).round()),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withAlpha((0.3 * 255).round())),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withAlpha((0.3 * 255).round())),
        ),
      ),
    );
  }

  Future<bool?> _showSetScreensaverPasswordDialog(
      BuildContext context, ScreenSaverService ss) async {
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
                  Text(err!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
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
