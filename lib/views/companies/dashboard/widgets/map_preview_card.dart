import 'package:flutter/material.dart';

class MapPreviewCard extends StatelessWidget {
  /// Adresin tek satırlık gösterimi (ör. "Rıhtım Cd. No:12, Karaköy, İstanbul")
  final String addressText;

  /// "Haritada aç" aksiyonu (Google Maps vb. dışa yönlendirme)
  final VoidCallback onOpenMap;

  const MapPreviewCard({
    super.key,
    required this.addressText,
    required this.onOpenMap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenMap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Basit bir harita önizleme alanı (statik placeholder)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withAlpha(24),
                          theme.colorScheme.secondary.withAlpha(18),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.map_outlined,
                      size: 64,
                      color: theme.colorScheme.primary.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Row(
                children: [
                  const Icon(Icons.place_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      addressText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: TextButton.icon(
                  onPressed: onOpenMap,
                  icon: const Icon(Icons.directions_outlined),
                  label: const Text('Haritada aç'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
