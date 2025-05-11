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

  const OnlineImage({
    super.key,
    required this.imagePath,
    required this.imageName,
    required this.sizeW,
    this.sizeH,
    this.rounded = false,
    this.border = false,
    this.borderSpecs,
  });

  String buildImageUrl(String baseUrl, String imagePath) {
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    return '$cleanBaseUrl$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiManager>();
    final double finalSizeH = sizeH ?? sizeW;

    final imageUrl = buildImageUrl(api.baseUrl, '$imagePath$imageName');
debugPrint('Image URL: $imageUrl');
    Widget image = Image.network(
      imageUrl,
      width: sizeW,
      height: finalSizeH,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: sizeW,
          height: finalSizeH,
          color: Colors.grey[200],
          child: const Icon(Icons.image_not_supported, size: 24, color: Colors.grey),
        );
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