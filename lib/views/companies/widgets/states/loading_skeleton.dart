import 'package:flutter/material.dart';

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});

  Widget _bar(BuildContext context,
      {double h = 16, double w = double.infinity}) {
    final c = Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(150);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(height: h, width: w, color: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Basit, paket yok; hafif bir iskelet
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // logo skeleton
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Theme.of(context)
                      .colorScheme.surfaceContainerHighest.withAlpha(150),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(context, h: 18, w: 240),
                    const SizedBox(height: 8),
                    _bar(context, h: 14, w: 180),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: _bar(context, h: 16, w: 160),
          ),
          const SizedBox(height: 12),
          _bar(context, h: 14),
          const SizedBox(height: 8),
          _bar(context, h: 14),
          const SizedBox(height: 8),
          _bar(context, h: 14, w: 260),
        ],
      ),
    );
  }
}
