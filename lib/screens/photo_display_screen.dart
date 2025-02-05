import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PhotoDisplayScreen extends StatelessWidget {
  final String imagePath;

  const PhotoDisplayScreen({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Captured Photo'),
        actions: [
          if (!kIsWeb)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final file = File(imagePath);
                if (await file.exists()) {
                  await file.delete();
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Hero(
          tag: 'capturedImage',
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: _buildImageWidget(),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Image saved at: $imagePath',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    if (kIsWeb) {
      // For web platform, use Image.network
      return Image.network(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              'Error loading image: $error',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
    } else {
      // For mobile platforms, use Image.file
      return Image.file(
        File(imagePath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              'Error loading image: $error',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
    }
  }
}
