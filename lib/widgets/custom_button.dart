import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? backgroundColor; // Özel arka plan rengi
  final Color? textColor; // Özel yazı rengi
  final Color? borderColor; // Özel kenarlık rengi
  final IconData? icon; // Opsiyonel simge
  final bool iconOnRight; // Simge yazının sağında mı olmalı?

  const CustomButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.icon,
    this.iconOnRight = false, // Varsayılan olarak simge solda
  }) : super(key: key);

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
            : null, // Kenarlık rengi opsiyonel
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0), // Yuvarlatılmış köşeler
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
              mainAxisSize: MainAxisSize.min, // İçerik genişliği kadar
              mainAxisAlignment: MainAxisAlignment.center, // Ortalanmış içerik
              children: [
                if (icon != null && !iconOnRight) // Simge soldaysa
                  Icon(icon, size: 20.0, color: textColor ?? theme.colorScheme.onPrimary),
                if (icon != null && !iconOnRight) const SizedBox(width: 8.0), // Simge ve yazı arası boşluk
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textColor ?? theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600, // Hafif kalın yazı
                    ),
                  ),
                ),
                if (icon != null && iconOnRight) const SizedBox(width: 8.0), // Yazı ve simge arası boşluk
                if (icon != null && iconOnRight) // Simge sağdaysa
                  Icon(icon, size: 20.0, color: textColor ?? theme.colorScheme.onPrimary),
              ],
            ),
    );
  }
}
