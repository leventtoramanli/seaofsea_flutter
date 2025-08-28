// lib/views/user_settings/language_settings.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class LanguageSettings extends StatelessWidget {
  const LanguageSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Glass panel renkleri (alpha tabanlı)
    final glassBg = c.surface.withAlpha(220); // ~86% opak
    final glassBorder = c.outlineVariant.withAlpha(120); // ince kenar

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
                color: glassBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: glassBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.language,
                    size: 48,
                    color: c.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Language Settings',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: c.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Only English language is currently supported.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: c.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // İstersen ileride buraya bir "Change language" butonu eklenebilir.
                  // Şimdilik bilgi amaçlı bırakıyoruz.
                  if (isDark) const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
