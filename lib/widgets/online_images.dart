// widgets/online_images.dart
import 'package:flutter/material.dart';
import 'package:seaofsea/services/v1/v1_config.dart';

class OnlineImage extends StatelessWidget {
  final String imagePath; // örn: 'images/user/user/'
  final String imageName; // örn: 'abc.png'
  final double sizeW;
  final double? sizeH;
  final bool rounded;
  final bool border;
  final BoxBorder? borderSpecs;
  final String? fallbackAsset;

  const OnlineImage({
    super.key,
    required this.imagePath,
    required this.imageName,
    required this.sizeW,
    this.sizeH,
    this.rounded = false,
    this.border = false,
    this.borderSpecs,
    this.fallbackAsset,
  });

  String _buildImageUrl() {
    final base = V1Config.baseUrl.endsWith('/')
        ? V1Config.baseUrl
        : '${V1Config.baseUrl}';
    final cleanPath =
        imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    return '${base}uploads/$cleanPath$imageName';
  }

  @override
  Widget build(BuildContext context) {
    final double finalSizeH = sizeH ?? sizeW;

    if (imageName.isEmpty || imageName == 'null') {
      return _fallback(context, finalSizeH);
    }

    Widget image = Image.network(
      _buildImageUrl(),
      width: sizeW,
      height: finalSizeH,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallbackChild(),
    );

    if (rounded) {
      image = ClipRRect(
        borderRadius: BorderRadius.circular(sizeW / 2),
        child: image,
      );
    }

    return Container(
      width: sizeW,
      height: finalSizeH,
      decoration: BoxDecoration(
        border: border
            ? (borderSpecs ?? Border.all(color: Theme.of(context).dividerColor))
            : null,
        shape: rounded ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: image,
    );
  }

  Widget _fallback(BuildContext context, double h) {
    return Container(
      width: sizeW,
      height: h,
      decoration: BoxDecoration(
        border: border
            ? (borderSpecs ?? Border.all(color: Theme.of(context).dividerColor))
            : null,
        shape: rounded ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: _fallbackChild(),
    );
  }

  Widget _fallbackChild() {
    return fallbackAsset != null
        ? Image.asset(fallbackAsset!, fit: BoxFit.cover)
        : const Icon(Icons.image_not_supported, size: 24, color: Colors.grey);
  }
}
