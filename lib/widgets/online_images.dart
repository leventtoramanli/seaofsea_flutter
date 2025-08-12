import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';

class OnlineImage extends StatelessWidget {
  final String imagePath;
  final String imageName;
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

  String buildImageUrl(String baseUrl, String imagePath) {
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final cleanPath =
        imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    return '$cleanBaseUrl$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiManager>();
    final double finalSizeH = sizeH ?? sizeW;

    // fallback durum kontrolü
    if (imageName.isEmpty || imageName == 'null') {
      return Container(
        width: sizeW,
        height: finalSizeH,
        decoration: BoxDecoration(
          border: border
              ? (borderSpecs ??
                  Border.all(color: Theme.of(context).dividerColor))
              : null,
          shape: rounded ? BoxShape.circle : BoxShape.rectangle,
        ),
        child: fallbackAsset != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(rounded ? sizeW / 2 : 0),
                child: Image.asset(
                  fallbackAsset!,
                  width: sizeW,
                  height: finalSizeH,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.image_not_supported,
                size: 24, color: Colors.grey),
      );
    }

    final imageUrl = buildImageUrl(api.baseUrl, '$imagePath$imageName');

    Widget image = Image.network(
      imageUrl,
      width: sizeW,
      height: finalSizeH,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return fallbackAsset != null
            ? Image.asset(
                fallbackAsset!,
                width: sizeW,
                height: finalSizeH,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.image_not_supported,
                size: 24, color: Colors.grey);
      },
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
}
