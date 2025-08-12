// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'package:crop_image/crop_image.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/utils/auth_provider.dart';

class CustomImagePicker extends StatefulWidget {
  final double aspectRatio;
  final Function(File? file, String? base64) onImagePicked;
  final Map<String, String> meta;
  final double iwidth;
  final double iheight;
  final double iradius;
  final dynamic ishadow;
  final String? existingImageUrl;
  final bool canEdit;
  final bool doUpload;
  final bool deleteOld;
  final bool addWatermark;
  final String? uploadEndpoint;
  final Map<String, String>? uploadMeta;
  final void Function(String fileName)? onUploaded;

  const CustomImagePicker({
    super.key,
    required this.aspectRatio,
    required this.onImagePicked,
    required this.meta,
    required this.deleteOld,
    required this.addWatermark,
    this.iwidth = 0.0,
    this.iheight = 0.0,
    this.iradius = 0.0,
    this.ishadow = false,
    this.existingImageUrl,
    this.canEdit = true,
    this.doUpload = false,
    this.uploadEndpoint,
    this.uploadMeta,
    this.onUploaded,
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
                                  debugPrint(
                                      "📸 User found: ${userId.toString()}");
                                  final v1api = V1ApiManager();
                                  final uploadResponse = await v1api.call(
                                    module: 'user',
                                    action: 'upload_image',
                                    file: file,
                                    fileType: 'image/png',
                                    fileName: 'user_${userId}_profile.png',
                                    params: {
                                      'type': 'user',
                                      'user_id': userId.toString(),
                                      'deleteOld': widget.deleteOld.toString(),
                                      'addWatermark':
                                          widget.addWatermark.toString(),
                                    },
                                    onProgress: (progress) {
                                      dialogSetState(() {
                                        // yükleme animasyonunu göster
                                      });
                                    },
                                  );

                                  if (uploadResponse['success'] == true) {
                                    if (widget.onUploaded != null) {
                                      widget.onUploaded!(
                                          uploadResponse['data']['file_name']);
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              "Upload failed: ${uploadResponse['message']}")),
                                    );
                                  }

                                  widget.onImagePicked(file, null);
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
    final fitMode = widget.aspectRatio >= 2 ? BoxFit.fitHeight : BoxFit.cover;
    final double cWidth =
        widget.iwidth != 0.0 ? widget.iwidth : double.infinity;
    final double cHeight = widget.iheight != 0.0
        ? widget.iheight
        : (MediaQuery.of(context).size.width / widget.aspectRatio) < 150
            ? 150
            : (MediaQuery.of(context).size.width / widget.aspectRatio);
    final double bRadius = widget.iradius;
    String? imageUrl = widget.existingImageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = "assets/cover.jpg";
    }
    return Stack(
      children: [
        Container(
          width: cWidth,
          height: cHeight,
          decoration: BoxDecoration(
            boxShadow: widget.ishadow
                ? const [
                    BoxShadow(
                        color: Colors.black54,
                        blurRadius: 5,
                        offset: Offset(0, 0))
                  ]
                : [],
            color: Colors.white,
            borderRadius: BorderRadius.circular(bRadius),
            image: _selectedImage != null
                ? DecorationImage(
                    image: FileImage(_selectedImage!),
                    fit: fitMode,
                  )
                : _selectedImageBytes != null
                    ? DecorationImage(
                        image: MemoryImage(_selectedImageBytes!),
                        fit: fitMode,
                      )
                    : imageUrl.contains("assets/")
                        ? DecorationImage(
                            image: AssetImage(imageUrl) as ImageProvider,
                            fit: fitMode,
                          )
                        : DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: fitMode,
                          ),
          ),
        ),
        if (widget.canEdit)
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: _pickAndCropImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(60),
                  shape: BoxShape.circle,
                ),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: const Icon(
                    Icons.add_a_photo,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
