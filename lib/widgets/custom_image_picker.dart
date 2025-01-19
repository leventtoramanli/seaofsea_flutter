import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'package:crop_image/crop_image.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/auth_provider.dart';

class CustomImagePicker extends StatefulWidget {
  final double aspectRatio;
  final Function(File? file, String? base64) onImagePicked;
  final Map<String, String> meta;

  const CustomImagePicker({
    super.key,
    required this.aspectRatio,
    required this.onImagePicked,
    required this.meta,
  });

  @override
  State<CustomImagePicker> createState() => _CustomImagePickerState();
}

class _CustomImagePickerState extends State<CustomImagePicker> {
  dynamic _selectedImage;
  Uint8List? _selectedImageBytes;
  late CropController _cropController;

  @override
  void initState() {
    super.initState();
    _cropController = CropController(
      aspectRatio: widget.aspectRatio,
    );
  }

  Future<void> _pickAndCropImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    // ignore: use_build_context_synchronously
    var authProvider = Provider.of<AuthProvider>(context, listen: false);
    var userId = authProvider.userInfo!['id'];

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = null;
          _selectedImageBytes = bytes;
        });
      } else {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _selectedImageBytes = null;
        });
      }

      await showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        barrierDismissible: false,
        builder: (context) {
          double progress = 0.0;
          bool isCropping = true;

          return StatefulBuilder(
            builder: (context, dialogSetState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                title: Text(isCropping ? "Crop Image" : "Image Uploading..."),
                content: isCropping
                    ? AspectRatio(
                        aspectRatio: widget.aspectRatio,
                        child: CropImage(
                          controller: _cropController,
                          image: _selectedImage != null
                              ? Image.file(_selectedImage!, fit: BoxFit.contain)
                              : Image.memory(_selectedImageBytes!,
                                  fit: BoxFit.contain),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(value: progress),
                          const SizedBox(height: 10),
                          Text(
                              "Upload in progress... %${(progress * 100).toInt()}"),
                        ],
                      ),
                actions: isCropping
                    ? [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () async {
                            final croppedImage =
                                await _cropController.croppedBitmap();
                            // ignore: unnecessary_null_comparison
                            if (croppedImage != null) {
                              final byteData = await croppedImage.toByteData(
                                  format: ui.ImageByteFormat.png);
                              if (byteData != null) {
                                final croppedBytes =
                                    byteData.buffer.asUint8List();

                                if (!kIsWeb) {
                                  // Mobil platformda dosya kaydı
                                  final tempDir = Directory.systemTemp;
                                  final file = File(
                                      '${tempDir.path}/${userId}_${DateTime.now().millisecondsSinceEpoch}.png');
                                  await file.writeAsBytes(croppedBytes);

                                  setState(() {
                                    _selectedImage = file;
                                  });
                                  widget.onImagePicked(file, null);
                                } else {
                                  // Web platformunda base64 formatına dönüştürme
                                  final base64Image =
                                      base64Encode(croppedBytes);

                                  setState(() {
                                    _selectedImageBytes = croppedBytes;
                                  });
                                  widget.onImagePicked(null, base64Image);
                                }

                                dialogSetState(() {
                                  isCropping = false;
                                });

                                for (int i = 0; i < 99; i++) {
                                  await Future.delayed(
                                      const Duration(milliseconds: 50));
                                  dialogSetState(() {
                                    progress = i / 100.0;
                                  });
                                }

                                dialogSetState(() {
                                  progress = 1.0;
                                });
                                await Future.delayed(
                                    const Duration(seconds: 1));
                                // ignore: use_build_context_synchronously
                                Navigator.pop(context);
                              }
                            }
                          },
                          child: const Text("Crop"),
                        ),
                      ]
                    : null,
              );
            },
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
        height: (MediaQuery.of(context).size.width / (widget.aspectRatio)) < 150
            ? 150
            : (MediaQuery.of(context).size.width / (widget.aspectRatio)),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          image: _selectedImage != null
              ? DecorationImage(
                  image: FileImage(_selectedImage!),
                  fit: BoxFit.cover,
                )
              : _selectedImageBytes != null
                  ? DecorationImage(
                      image: MemoryImage(_selectedImageBytes!),
                      fit: BoxFit.cover,
                    )
                  : null,
        ),
        child: (_selectedImage == null && _selectedImageBytes == null)
            ? const Center(
                child: Icon(Icons.add_a_photo, size: 40, color: Colors.white),
              )
            : null,
      ),
    );
  }
}
