import 'package:flutter/material.dart';

class ShowDialog {
  static Future<void> showCustomDialog({
    required BuildContext context,
    required String title,
    required String content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: actions ??
              [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
        );
      },
    );
  }
}
