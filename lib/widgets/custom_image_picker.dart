import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_image/crop_image.dart';

class CustomImagePicker extends StatefulWidget {
  final double aspectRatio;
  final Function(File?) onImagePicked;

  const CustomImagePicker({
    super.key,
    required this.aspectRatio,
    required this.onImagePicked,
  });

  @override
  State<CustomImagePicker> createState() => _CustomImagePickerState();
}

class _CustomImagePickerState extends State<CustomImagePicker> {
  File? _selectedImage;
  final CropController _cropController = CropController();

  Future<void> _pickAndCropImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      // Açılır bir modalda kırpma işlemini gerçekleştirin
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Crop Image"),
            content: AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: CropImage(
                controller: _cropController,
                image: Image.file(
                  _selectedImage!, // FileImage yerine Image.file
                  fit: BoxFit.cover,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // İptal
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Kırpılmış resmi al
                  final croppedImage = await _cropController.croppedBitmap();
                  if (croppedImage != null) {
                    // Kırpılmış resmi ByteData'ya çevir
                    final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);


                    if (byteData != null) {
                      // ByteData'dan Uint8List oluştur
                      final croppedBytes = byteData.buffer.asUint8List();

                      // Geçici bir dosyaya kaydet
                      final tempDir = Directory.systemTemp;
                      final file = File(
                          '${tempDir.path}/cropped_image_${DateTime.now().millisecondsSinceEpoch}.png');
                      await file
                          .writeAsBytes(croppedBytes); // Uint8List kaydediliyor

                      setState(() {
                        _selectedImage =
                            file; // Yeni kırpılmış resmi seçili olarak ayarla
                      });

                      widget.onImagePicked(file); // Callback'i çağır
                      Navigator.pop(context); // Kırpma tamamlandı
                    }
                  }
                },
                child: const Text("Crop"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickAndCropImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          image: _selectedImage != null
              ? DecorationImage(
                  image: FileImage(_selectedImage!), // FileImage kullanımı
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _selectedImage == null
            ? const Center(
                child: Icon(Icons.add_a_photo, size: 40, color: Colors.white),
              )
            : null,
      ),
    );
  }
}
