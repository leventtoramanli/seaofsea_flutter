// lib/views/admin/admin_tools_panel.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/utils/secure_storage.dart';
import 'package:seaofsea/widgets/admin_block_controls.dart';

class AdminToolsPanel extends StatefulWidget {
  const AdminToolsPanel({super.key});

  @override
  State<AdminToolsPanel> createState() => _AdminToolsPanelState();
}

class _AdminToolsPanelState extends State<AdminToolsPanel> {
  bool expSoon = V1ApiManager.debugForceExpiringSoon;
  String tokenInfo = '';
  final _userIdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshTokenInfo();
  }

  Future<void> _refreshTokenInfo() async {
    final storage = SecureStorage();
    final token = await storage.readSecureData('authToken') ?? '';
    final remember = (await storage.readSecureData('rememberMe')) == 'true';
    final exp = _decodeExp(token);
    setState(() {
      tokenInfo = token.isEmpty
          ? 'No token'
          : 'JWT exp: ${exp?.toIso8601String() ?? '-'} • rememberMe: $remember';
    });
  }

  DateTime? _decodeExp(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final data = jsonDecode(payload);
      final exp = (data['exp'] as int?);
      if (exp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (_) {
      return null;
    }
  }

  Future<void> _toggleExpSoon(bool v) async {
    setState(() => expSoon = v);
    V1ApiManager.debugForceExpiringSoon = v;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ExpiringSoon simulation: ${v ? 'ON' : 'OFF'}')),
    );
  }

  Future<void> _force401Once() async {
    final storage = SecureStorage();
    final orig = await storage.readSecureData('authToken');
    await storage.writeSecureData('authToken', 'x.y.z'); // bozuk JWT
    final api = context.read<V1ApiManager>();
    await api.call(module: 'user', action: 'get_profile', params: {});
    // test bitti: geri al
    if (orig != null) await storage.writeSecureData('authToken', orig);
    await _refreshTokenInfo();
  }

  Future<void> _nukeRefreshToken() async {
    final storage = SecureStorage();
    await storage.deleteSecureData('refreshToken');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('refreshToken deleted (refresh fail sim)')),
    );
  }

  Future<void> _pingSecureEndpoint() async {
    final api = context.read<V1ApiManager>();
    final res = await api.call(module: 'user', action: 'get_profile', params: {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ping: ${res['success'] == true ? 'OK' : res['message']}')),
      );
    }
    await _refreshTokenInfo();
  }

  Future<void> _hardLogout() async {
    await AuthProvider.instance.v1logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Card(
          child: SwitchListTile(
            title: const Text('Simulate “token expiring soon”'),
            subtitle: const Text('V1ApiManager.debugForceExpiringSoon'),
            value: expSoon,
            onChanged: _toggleExpSoon,
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Force 401 once'),
            subtitle: const Text('Writes a bad authToken, calls /user.get_profile, then restores.'),
            trailing: ElevatedButton(
              onPressed: _force401Once,
              child: const Text('Run'),
            ),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Delete refreshToken'),
            subtitle: const Text('Next refresh will fail → onUnauthorized flow'),
            trailing: ElevatedButton(
              onPressed: _nukeRefreshToken,
              child: const Text('Delete'),
            ),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Ping secure endpoint'),
            subtitle: Text(tokenInfo),
            trailing: ElevatedButton(
              onPressed: _pingSecureEndpoint,
              child: const Text('Ping'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Admin • Block Controls', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _userIdCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Target user id',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final id = int.tryParse(_userIdCtrl.text);
                        if (id == null) return;
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            child: SizedBox(
                              width: 600,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: AdminBlockControls(targetUserId: id),
                              ),
                            ),
                          ),
                        );
                      },
                      child: const Text('Open'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton.icon(
            onPressed: _hardLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Hard Logout'),
          ),
        ),
      ],
    );
  }
}
