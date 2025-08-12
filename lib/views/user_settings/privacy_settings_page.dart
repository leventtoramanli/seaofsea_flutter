// ignore_for_file: use_build_context_synchronously

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/utils/auth_provider.dart';

class PrivacySettings extends StatefulWidget {
  const PrivacySettings({super.key});

  @override
  State<PrivacySettings> createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends State<PrivacySettings> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController     = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _busy = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
        const SnackBar(content: Text('New password must be at least 8 characters')),
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
      await auth.v1logout(allDevices: true); // güvenlik için tüm cihazlardan çık
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

  @override
  Widget build(BuildContext context) {
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.privacy_tip_outlined, size: 48, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'Privacy and Security',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Change Password',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
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
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Update Password'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Session Control',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _busy ? null : _logoutAllDevices,
                      icon: const Icon(Icons.logout),
                      label: _busy
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Log out from all devices'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
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
          borderSide: BorderSide(color: Colors.white.withAlpha((0.3 * 255).round())),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withAlpha((0.3 * 255).round())),
        ),
      ),
    );
  }
}
