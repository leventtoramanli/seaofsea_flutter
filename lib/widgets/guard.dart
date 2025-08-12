import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/permission_provider.dart';

class Guard extends StatelessWidget {
  final String code;
  final Widget child;
  final Widget? fallback;

  const Guard({
    super.key,
    required this.code,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final can = context.select<PermissionProvider, bool>((p) => p.can(code));
    if (can) return child;
    return fallback ?? const SizedBox.shrink();
  }
}
