import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/screensaver_service.dart';

class ScreenSaverGate extends StatefulWidget {
  final Widget child;
  const ScreenSaverGate({super.key, required this.child});

  @override
  State<ScreenSaverGate> createState() => _ScreenSaverGateState();
}

class _ScreenSaverGateState extends State<ScreenSaverGate> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // İlk frame’den sonra focus iste
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.read<ScreenSaverService>();

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent e) {
        svc.recordActivity();
      },
      child: Listener(
        onPointerDown: (_) => svc.recordActivity(),
        onPointerSignal: (_) => svc.recordActivity(),
        onPointerHover: (_) => svc.recordActivity(),
        child: widget.child,
      ),
    );
  }
}
