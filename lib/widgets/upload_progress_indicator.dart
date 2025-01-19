import 'package:flutter/material.dart';

class UploadProgressIndicator extends StatelessWidget {
  final double progress;

  const UploadProgressIndicator({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(value: progress),
            const SizedBox(height: 10),
            Text("Yükleme işlemi devam ediyor... %${(progress * 100).toInt()}"),
          ],
        ),
      ),
    );
  }
}