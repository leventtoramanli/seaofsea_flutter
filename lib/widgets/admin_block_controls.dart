import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/utils/permission_provider.dart';

class AdminBlockControls extends StatefulWidget {
  final int targetUserId;
  const AdminBlockControls({super.key, required this.targetUserId});

  @override
  State<AdminBlockControls> createState() => _AdminBlockControlsState();
}

class _AdminBlockControlsState extends State<AdminBlockControls> {
  bool loading = true;
  String? blockedUntil;
  String? blockReason;
  final TextEditingController _reasonCtrl = TextEditingController();

  bool get isBlocked => blockedUntil != null && blockedUntil!.isNotEmpty;

  Future<void> _load() async {
    final api = context.read<V1ApiManager>();
    final res = await api.moderationGetBlockStatus(targetUserId: widget.targetUserId);
    if (mounted) {
      setState(() {
        loading = false;
        if (res['success'] == true) {
          blockedUntil = res['blocked_until']?.toString();
          blockReason  = res['block_reason']?.toString();
          _reasonCtrl.text = blockReason ?? '';
        } else {
          blockedUntil = null;
          blockReason  = null;
        }
      });
    }
  }

  Future<void> _blockWithHours(int hours) async {
    setState(() => loading = true);
    final api = context.read<V1ApiManager>();
    final res = await api.moderationBlockUser(
      targetUserId: widget.targetUserId,
      durationHours: hours,
      reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
    );
    if (mounted) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['success'] == true ? 'User blocked.' : (res['message'] ?? 'Block failed'))),
      );
      await _load();
    }
  }

  Future<void> _unblock() async {
    setState(() => loading = true);
    final api = context.read<V1ApiManager>();
    final res = await api.moderationUnblockUser(targetUserId: widget.targetUserId);
    if (mounted) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['success'] == true ? 'User unblocked.' : (res['message'] ?? 'Unblock failed'))),
      );
      await _load();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthProvider>().userInfo?['id'];
    final canAdmin = context.select<PermissionProvider, bool>((p) => p.can('admin.access'));

    // kendine işlem gizli
    if (!canAdmin || me == widget.targetUserId) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin • Block Controls', style: TextStyle(fontWeight: FontWeight.bold)),
            if (loading) const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: LinearProgressIndicator(),
            ),
            if (!loading) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isBlocked
                          ? 'Blocked until: $blockedUntil'
                          : 'Not blocked',
                      style: TextStyle(color: isBlocked ? Colors.red : Colors.green),
                    ),
                  ),
                  if (isBlocked)
                    TextButton.icon(
                      onPressed: _unblock,
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Unblock'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () => _blockWithHours(24),
                    child: const Text('Block 24h'),
                  ),
                  ElevatedButton(
                    onPressed: () => _blockWithHours(72),
                    child: const Text('Block 72h'),
                  ),
                  ElevatedButton(
                    onPressed: () => _blockWithHours(24 * 7),
                    child: const Text('Block 7d'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
