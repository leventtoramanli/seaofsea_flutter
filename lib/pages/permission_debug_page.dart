import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/permission_provider.dart';

class PermissionDebugPage extends StatefulWidget {
  const PermissionDebugPage({super.key});

  @override
  State<PermissionDebugPage> createState() => _PermissionDebugPageState();
}

class _PermissionDebugPageState extends State<PermissionDebugPage> {
  List<Map<String, dynamic>> dict = [];
  List<String> effective = [];
  String lastCheck = '-';

  Future<void> _load() async {
    final p = context.read<PermissionProvider>();
    await p.fetchUserPermissions();
    setState(() {
      dict = p.dictionary;
      effective = p.effective.toList()..sort();
    });
  }

  Future<void> _check(String code) async {
    final ok = await context.read<PermissionProvider>().check(code);
    setState(() => lastCheck = '$code → ${ok ? "ALLOWED" : "DENIED"}');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PermissionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Permission Debug')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            if (p.isLoading) const LinearProgressIndicator(),
            Text('Last check: $lastCheck'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _check('settings.general_update'),
              child: const Text('check("settings.general_update")'),
            ),
            ElevatedButton(
              onPressed: () => _check('admin.access'),
              child: const Text('check("admin.access")'),
            ),
            const Divider(height: 24),
            const Text('Effective permissions (grant + role - revoke):',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: effective
                  .map((e) => Chip(label: Text(e)))
                  .toList(),
            ),
            const Divider(height: 24),
            const Text('Dictionary (permissions table):',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...dict.map((m) => ListTile(
                  dense: true,
                  title: Text(m['code'] ?? ''),
                  subtitle: Text((m['description'] ?? '').toString()),
                  trailing: Text((m['scope'] ?? '').toString()),
                )),
          ],
        ),
      ),
    );
  }
}
