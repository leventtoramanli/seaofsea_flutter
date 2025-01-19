import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final IconData? icon;
  final bool iconOnRight;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.icon,
    this.iconOnRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? theme.colorScheme.primary,
        foregroundColor: textColor ?? theme.colorScheme.onPrimary,
        elevation: 2.0,
        side: borderColor != null
            ? BorderSide(color: borderColor!)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
      ),
      child: isLoading
          ? const SizedBox(
              height: 16.0,
              width: 16.0,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null && !iconOnRight)
                  Icon(icon, size: 20.0, color: textColor ?? theme.colorScheme.onPrimary),
                if (icon != null && !iconOnRight) const SizedBox(width: 8.0),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textColor ?? theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (icon != null && iconOnRight) const SizedBox(width: 8.0),
                if (icon != null && iconOnRight)
                  Icon(icon, size: 20.0, color: textColor ?? theme.colorScheme.onPrimary),
              ],
            ),
    );
  }
}
