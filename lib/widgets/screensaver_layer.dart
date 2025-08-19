import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/screensaver_service.dart';

class ScreenSaverLayer extends StatefulWidget {
  const ScreenSaverLayer({super.key});
  @override
  State<ScreenSaverLayer> createState() => _ScreenSaverLayerState();
}

class _ScreenSaverLayerState extends State<ScreenSaverLayer>
    with TickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _passCtrl = TextEditingController();

  bool _showUnlock = false;
  bool _busy = false;
  String? _error;

  // Dikey salınım (logo)
  late final AnimationController _floatCtrl;
  // Ekranda gezinme
  late final AnimationController _moveCtrl;
  // Arka plan renk geçişi
  late final AnimationController _bgCtrl;

  // Normalize hareket tween’i (0..1 aralığı)
  Tween<Offset>? _moveTweenN;
  Offset _fromN = const Offset(0.0, 0.5);
  Offset _toN = const Offset(1.0, 0.5);

  bool _moveInited = false;
  final _rng = Random();

  // Arka plan renkleri (mat koyu)
  late Color _bgFrom;
  late Color _bgTo;

  static const double _logoW = 80;
  static const double _pad = 24;

  @override
  void initState() {
    super.initState();

    // Logo salınımı
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Gezinme
    _moveCtrl = AnimationController(vsync: this);

    // Arka plan renk geçişi
    _bgFrom = _randomMatteDark();
    _bgTo = _randomMatteDark();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          // sıradaki geçişe hazırla
          _bgFrom = _bgTo;
          _bgTo = _randomMatteDark();
          _bgCtrl.forward(from: 0);
        }
      })
      ..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      final svc = context.read<ScreenSaverService>();
      if (svc.lockEnabled && svc.hasPassword()) {
        setState(() => _showUnlock = true);
      }
    });
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _moveCtrl.dispose();
    _bgCtrl.dispose();
    _passCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Mat (siyaha yakın) koyu renk üret
  Color _randomMatteDark() {
    final h = _rng.nextDouble() * 360.0; // 0..360
    final s = 0.10 + _rng.nextDouble() * 0.20; // 0.10..0.30 (düşük satürasyon)
    final v = 0.06 + _rng.nextDouble() * 0.18; // 0.06..0.24 (düşük parlaklık)
    return HSVColor.fromAHSV(0.8, h, s, v).toColor();
  }

  Size _measureText(String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return tp.size;
  }

  // İlk adım soldan sağa; sonra rastgele (kenarlara değme garantisi %40)
  void _scheduleNextHopN({required bool first}) {
    if (first) {
      _fromN = const Offset(0.0, 0.5);
      _toN = const Offset(1.0, 0.5);
    } else {
      _fromN = _toN;

      double x;
      final r = _rng.nextDouble();
      if (r < 0.2) {
        x = 0.0; // sol kenar
      } else if (r < 0.4) {
        x = 1.0; // sağ kenar
      } else {
        x = _rng.nextDouble(); // serbest
      }
      final y = _rng.nextDouble();
      _toN = Offset(x, y);
    }

    _moveTweenN = Tween<Offset>(begin: _fromN, end: _toN);

    // Mesafeye göre süre (normalize 0..√2 aralığı)
    final dist = (_toN - _fromN).distance; // 0..1.414
    final seconds = (dist / 0.33).clamp(1.2, 8.0); // ~0.28 unit/sn hız
    _moveCtrl
      ..duration = Duration(milliseconds: (seconds * 1000).round())
      ..forward(from: 0).whenComplete(() {
        if (mounted) _scheduleNextHopN(first: false);
      });
  }

  Future<void> _attemptUnlock() async {
    final svc = context.read<ScreenSaverService>();
    final pwd = _passCtrl.text.trim();
    if (pwd.isEmpty) {
      setState(() => _error = 'Please enter your password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = svc.validatePassword(pwd);
      if (ok) {
        await svc.deactivate();
      } else {
        setState(() => _error = 'Wrong password.');
      }
    } catch (e) {
      setState(() => _error = 'Unlock error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _handleUserActivity() async {
    final svc = context.read<ScreenSaverService>();
    final requiresPwd = (svc.lockEnabled && svc.hasPassword());
    if (requiresPwd) {
      if (!_showUnlock) setState(() => _showUnlock = true);
    } else {
      await svc.deactivate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ScreenSaverService>();

    final label = (svc.lockEnabled && svc.hasPassword())
        ? 'Session locked'
        : 'Screensaver';
    const labelStyle =
        TextStyle(color: Colors.white70, fontSize: 18, letterSpacing: 1.1);
    final labelSize = _measureText(label, labelStyle);

    final contentW = max(_logoW, labelSize.width);
    final contentH = _logoW + 18 + labelSize.height;

    return Material(
      type: MaterialType.transparency,
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (evt) {
          if (evt is KeyDownEvent) _handleUserActivity();
        },
        child: Listener(
          onPointerDown: (_) => _handleUserActivity(),
          onPointerHover: (_) => _handleUserActivity(),
          onPointerSignal: (_) => _handleUserActivity(),
          child: Stack(
            children: [
              // 🔵 Arka plan – koyu, sürekli renk geçişi
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _bgCtrl,
                  builder: (_, __) {
                    final bg = Color.lerp(_bgFrom, _bgTo, _bgCtrl.value)!;
                    return Container(color: bg);
                  },
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: const SizedBox.expand(),
                ),
              ),

              // 🟣 Gezinen + salınan logo
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final canvas = constraints.biggest;

                    if (!_moveInited) {
                      _moveInited = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && !_moveCtrl.isAnimating) {
                          _scheduleNextHopN(first: true);
                        }
                      });
                    }

                    return AnimatedBuilder(
                      animation: Listenable.merge([_moveCtrl, _floatCtrl]),
                      builder: (_, __) {
                        // Dikey salınım
                        final dyFloat =
                            12 * (1 - (2 * (_floatCtrl.value - 0.5)).abs());

                        // Mevcut pencere boyuna göre güvenli alan
                        final maxX =
                            max(0.0, canvas.width - contentW - _pad * 2);
                        final maxY =
                            max(0.0, canvas.height - contentH - _pad * 2);

                        // Normalize konum → piksel
                        Offset n =
                            (_moveCtrl.isAnimating && _moveTweenN != null)
                                ? _moveTweenN!.transform(_moveCtrl.value)
                                : _fromN;

                        // 0..1 aralığına sabitle
                        n = Offset(n.dx.clamp(0.0, 1.0), n.dy.clamp(0.0, 1.0));

                        final basePx = Offset(n.dx * maxX, n.dy * maxY);
                        final offset = Offset(
                          _pad + basePx.dx,
                          _pad + basePx.dy - 10 + dyFloat,
                        );

                        return Transform.translate(
                          offset: offset,
                          child: SizedBox(
                            width: contentW,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    'assets/logo256.png',
                                    width: _logoW,
                                    height: _logoW,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(label, style: labelStyle),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              if (_showUnlock) _buildUnlockCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockCard() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints.tightFor(width: 420),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                border: Border.all(color: Colors.white.withAlpha(20)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, color: Colors.white, size: 28),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter password to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    enabled: !_busy,
                    onSubmitted: (_) => _attemptUnlock(),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: Colors.white.withAlpha(20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withAlpha(62),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withAlpha(62),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_error != null)
                    Text(_error!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _busy ? null : _attemptUnlock,
                          icon: _busy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.login, size: 18),
                          label: const Text('Unlock'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
