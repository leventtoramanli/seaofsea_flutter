import 'dart:async';
import 'package:flutter/material.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/utils/secure_storage.dart';
import 'package:seaofsea/widgets/screensaver_layer.dart';

class ScreenSaverService extends ChangeNotifier {
  final SecureStorage _storage = SecureStorage();

  bool initialized = false;

  bool _enabled = false;
  Duration _timeout = const Duration(minutes: 5);
  bool _lockEnabled = false;
  String? _pw; // SecureStorage içinde tutuluyor (gerekirse hash'e çevrilebilir)

  bool get enabled => _enabled;
  Duration get timeout => _timeout;
  bool get lockEnabled => _lockEnabled;

  Timer? _idleTimer;
  OverlayEntry? _entry;
  bool _active = false;
  bool get isActive => _active;

  OverlayState? _rootOverlay() {
    final nav = V1ApiManager.navKey?.currentState;
    // Hem state’in overlay’i hem de gerekirse context üzerinden fallback
    return nav?.overlay ??
        (nav != null ? Overlay.maybeOf(nav.context, rootOverlay: true) : null);
  }

  void _showOverlay() {
    if (_entry != null) return;

    final overlay = _rootOverlay();
    if (overlay == null) {
      // Overlay henüz hazır değilse bir sonraki frame’de tekrar dene
      WidgetsBinding.instance.addPostFrameCallback((_) => _showOverlay());
      return;
    }

    _entry = OverlayEntry(
      builder: (_) => const ScreenSaverLayer(), // kendi overlay widget’ınız
    );

    overlay.insert(_entry!);
  }

  void _hideOverlay() {
    _entry?.remove();
    _entry = null;
  }

  Future<void> init() async {
    _enabled = (await _storage.readSecureData('ss_enabled')) == 'true';
    _lockEnabled = (await _storage.readSecureData('ss_lock_enabled')) == 'true';
    final s = await _storage.readSecureData('ss_timeout_secs');
    if (s != null && int.tryParse(s) != null) {
      _timeout = Duration(seconds: int.parse(s));
    }
    _pw = await _storage
        .readSecureData('ss_pw'); // düz saklıyoruz; istersen hashleyelim

    initialized = true;
    if (_enabled) _restartTimer();
    notifyListeners();
  }

  bool hasPassword() => (_pw != null && _pw!.isNotEmpty);

  Future<void> setEnabled(bool v) async {
    _enabled = v;
    await _storage.writeSecureData('ss_enabled', v ? 'true' : 'false');
    if (!_enabled) {
      _cancelTimer();
      _deactivate();
    } else {
      _restartTimer();
    }
    notifyListeners();
  }

  Future<void> setTimeout(Duration d) async {
    _timeout = d;
    await _storage.writeSecureData('ss_timeout_secs', d.inSeconds.toString());
    if (_enabled) _restartTimer();
    notifyListeners();
  }

  Future<void> setLockEnabled(bool v) async {
    _lockEnabled = v;
    await _storage.writeSecureData('ss_lock_enabled', v ? 'true' : 'false');
    notifyListeners();
  }

  Future<void> setPassword(String pass) async {
    final v = pass.trim();
    if (v.isEmpty) {
      _pw = null;
      await _storage.deleteSecureData('ss_pw');
    } else {
      _pw = v;
      await _storage.writeSecureData('ss_pw', v);
    }
    notifyListeners();
  }

  bool validatePassword(String input) => (input == (_pw ?? ''));

  void recordActivity() {
    if (!_enabled) return;
    if (_active) {
      // aktifken sadece kilit yoksa kapat
      if (!_lockEnabled || !hasPassword()) {
        _deactivate();
        _restartTimer();
      }
    } else {
      _restartTimer();
    }
  }

  void _restartTimer() {
    _cancelTimer();
    _idleTimer = Timer(_timeout, _activate);
  }

  void _cancelTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  void _activate() {
    if (_active) return;

    final overlay = _rootOverlay();
    if (overlay == null) {
      // Overlay henüz hazır değilse bir sonraki frame’de dene
      WidgetsBinding.instance.addPostFrameCallback((_) => _activate());
      return;
    }

    _entry = OverlayEntry(
      builder: (_) => const ScreenSaverLayer(), // ✅ yeni katman
    );

    overlay.insert(_entry!); // ✅ _rootOverlay() kullan
    _active = true;
    notifyListeners();
  }

  void _deactivate() {
    _entry?.remove();
    _entry = null;
    _active = false;
    notifyListeners();
  }

  Future<void> deactivate() async {
    _deactivate();
    _restartTimer();
  }

  Future<bool> _showUnlockDialog(BuildContext context) async {
    String pw = '';
    String? err;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Unlock'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    obscureText: true,
                    autofocus: true,
                    onChanged: (v) => pw = v,
                    onSubmitted: (_) {},
                    decoration: const InputDecoration(
                      labelText: 'Password',
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
                  onPressed: () {
                    if (validatePassword(pw)) {
                      Navigator.pop(ctx, true);
                    } else {
                      setState(() => err = 'Invalid password');
                    }
                  },
                  child: const Text('Unlock'),
                ),
              ],
            );
          },
        );
      },
    );
    return ok == true;
  }
}

class _ScreenSaverOverlay extends StatelessWidget {
  final bool lockEnabled;
  final VoidCallback onWakeRequest;

  const _ScreenSaverOverlay({
    required this.lockEnabled,
    required this.onWakeRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(240),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onWakeRequest,
        onPanDown: (_) => onWakeRequest(),
        child: Stack(
          children: [
            // ortada saat ve ipucu
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                      lockEnabled ? Icons.lock_outline : Icons.nightlight_round,
                      color: Colors.white70,
                      size: 72),
                  const SizedBox(height: 12),
                  Text(
                    lockEnabled ? 'Tap to unlock' : 'Tap to wake',
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
