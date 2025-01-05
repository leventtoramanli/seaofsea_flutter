import 'package:flutter/material.dart';

class InsImage extends StatelessWidget {
  const InsImage({
    super.key,
    required this.wideScreen,
  });

  final bool wideScreen;

  @override
  Widget build(BuildContext context) {
    double imgSize = 150;
    wideScreen ? imgSize = 300 : imgSize = 150;
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 12,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          clipBehavior: Clip.antiAlias,
          child: Image(
            image: const AssetImage('assets/logo.png'),
            height: imgSize,
          ),
        ),
      ),
    );
  }
}