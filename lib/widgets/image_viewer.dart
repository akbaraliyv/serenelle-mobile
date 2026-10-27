import 'package:flutter/material.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageName;

  const ImageViewerScreen({super.key, required this.imageName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: Image.asset(
            'assets/media/photos/$imageName',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
