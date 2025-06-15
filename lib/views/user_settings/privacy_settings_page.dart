// ignore_for_file: use_build_context_synchronously

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/utils/auth_provider.dart';

class PrivacySettings extends StatefulWidget {
  const PrivacySettings({super.key});

  @override
  State<PrivacySettings> createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends State<PrivacySettings> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

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
                border: Border.all(
                  color: Colors.white.withAlpha(20),
                ),
              ),
              child: SingleChildScrollView(
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
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your data is handled with utmost care. Future privacy features are listed below.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // 🔒 Inactive Privacy Settings
                    _disabledSwitch('2-Factor Authentication'),
                    _disabledSwitch('Biometric Login'),
                    _disabledSwitch('Hide activity from others'),
                    _disabledSwitch('Data usage reports'),
                    _disabledSwitch('Auto-delete history after 30 days'),

                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),
                    const Text(
                      'Change Password',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    _glassField(_currentPasswordController, 'Current Password'),
                    const SizedBox(height: 8),
                    _glassField(_newPasswordController, 'New Password'),
                    const SizedBox(height: 8),
                    _glassField(_confirmPasswordController, 'Confirm Password'),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final current = _currentPasswordController.text.trim();
                        final newPass = _newPasswordController.text.trim();
                        final confirm = _confirmPasswordController.text.trim();

                        if (current.isEmpty ||
                            newPass.isEmpty ||
                            confirm.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please fill all fields')),
                          );
                          return;
                        }

                        if (newPass != confirm) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Passwords do not match')),
                          );
                          return;
                        }

                        final apiManager =
                            Provider.of<ApiManager>(context, listen: false);
                        final response =
                            await apiManager.post(context, 'change_password', {
                          'current_password': current,
                          'new_password': newPass,
                        });

                        if (response != null && response['success'] == true) {
                          // 🔐 Oturumu sonlandır
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Password updated. Please login again.')),
                            );
                            await Future.delayed(const Duration(seconds: 2));

                            final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false);
                            await authProvider.v1logout();
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(context, '/');
                            }
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(response?['message'] ??
                                    'Failed to update password')),
                          );
                        }
                      },
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('Update Password'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),

                    const Text(
                      'Session Control',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        // 🔐 TODO: Tüm cihazlardan çıkış
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Log out from all devices'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      'These features will be active in a future release.',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white54,
                          fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
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

  Widget _disabledSwitch(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Opacity(
        opacity: 0.5,
        child: IgnorePointer(
          child: SwitchListTile(
            value: false,
            onChanged: (_) {},
            title: Text(
              title,
              style: const TextStyle(color: Colors.white),
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
        fillColor: Colors.white.withValues(alpha: 0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}
