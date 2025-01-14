import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ManualCropper extends StatefulWidget {
  final File imageFile;
  final double aspectRatio;

  const ManualCropper({
    super.key,
    required this.imageFile,
    this.aspectRatio = 1.0,
  });

  @override
  _ManualCropperState createState() => _ManualCropperState();
}

class _ManualCropperState extends State<ManualCropper> {
  late File _imageFile;
  late Rect _cropRect;
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Size? _imageDisplaySize;

  @override
  @override
void initState() {
  super.initState();
  _imageFile = widget.imageFile;

  // Ekran boyutlarını alın
  final screenSize = WidgetsBinding.instance.window.physicalSize /
      WidgetsBinding.instance.window.devicePixelRatio;
  final double cropWidth = screenSize.width * 0.5; // %50 genişlik
  final double cropHeight = cropWidth / widget.aspectRatio;

  // Başlangıçta crop alanını merkezleyin
  _cropRect = Rect.fromCenter(
    center: Offset(screenSize.width / 2, screenSize.height / 2),
    width: cropWidth,
    height: cropHeight,
  );
}


  void _updateImageDisplaySize(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final image = Image.file(_imageFile);
    final completer = Completer<void>();

    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (info, _) {
          final imageSize = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
          final aspectRatio = imageSize.width / imageSize.height;
          final double displayWidth = screenSize.width;
          final double displayHeight = displayWidth / aspectRatio;

          setState(() {
            _imageDisplaySize = Size(displayWidth, displayHeight);
          });

          completer.complete();
        },
      ),
    );
  }

  Future<void> _cropImage() async {
    if (_cropRect == null || _imageDisplaySize == null) return;

    final image = await decodeImageFromList(await _imageFile.readAsBytes());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // Crop alanını görüntüye göre ayarla
    final adjustedCropRect = Rect.fromLTWH(
      (_cropRect.left - _offset.dx) / _scale,
      (_cropRect.top - _offset.dy) / _scale,
      _cropRect.width / _scale,
      _cropRect.height / _scale,
    );

    final srcRect = Rect.fromLTWH(
      adjustedCropRect.left.clamp(0, image.width.toDouble()),
      adjustedCropRect.top.clamp(0, image.height.toDouble()),
      adjustedCropRect.width.clamp(0, image.width.toDouble()),
      adjustedCropRect.height.clamp(0, image.height.toDouble()),
    );

    final dstRect = Rect.fromLTWH(0, 0, _cropRect.width, _cropRect.height);
    canvas.drawImageRect(image, srcRect, dstRect, paint);

    final croppedImage = await recorder.endRecording().toImage(
          _cropRect.width.toInt(),
          _cropRect.height.toInt(),
        );

    final byteData =
        await croppedImage.toByteData(format: ui.ImageByteFormat.png);

    Navigator.of(context).pop(byteData!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    _updateImageDisplaySize(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Manual Cropper")),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _offset += details.delta;
                });
              },
              child: Stack(
                children: [
                  // Görüntüyü ölçekleyip taşı
                  Positioned.fill(
                    child: Transform.translate(
                      offset: _offset,
                      child: Transform.scale(
                        scale: _scale,
                        child: Image.file(
                          _imageFile,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  // Maske ve Çerçeve
                  if (_cropRect != null) ...[
                    CustomPaint(
                      painter: _CropMaskPainter(
                        cropRect: _cropRect,
                        maskColor: Colors.black54,
                      ),
                      size: MediaQuery.of(context).size,
                    ),

                    Positioned.fromRect(
                      rect: _cropRect,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Slider ile ölçek kontrolü
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                Text("Scale: ${(_scale * 100).toInt()}%"),
                Slider(
                  value: _scale,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  onChanged: (value) {
                    setState(() {
                      final oldScale = _scale;
                      _offset = Offset(
                        _offset.dx * value / oldScale,
                        _offset.dy * value / oldScale,
                      );
                      _scale = value;
                    });
                  },
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _cropImage,
            child: const Text("Crop Image"),
          ),
        ],
      ),
    );
  }
}

class _CropMaskPainter extends CustomPainter {
  final Rect cropRect;
  final Color maskColor;

  _CropMaskPainter({
    required this.cropRect,
    this.maskColor = Colors.black54,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = maskColor;

    // Maske ve crop alanını çiz
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cropPath = Path()..addRect(cropRect);

    final maskPath =
        Path.combine(PathOperation.difference, overlayPath, cropPath);

    canvas.drawPath(maskPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
