import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';
import 'image_utils.dart';

class AssetUploader {
  final FirebaseService _firebaseService = FirebaseService();

  // List of all asset images to be uploaded
  final List<String> _assetImages = [
    'assets/1.png',
    'assets/2.png',
    'assets/3.png',
    'assets/4.png',
    'assets/5.png',
    'assets/6.jpg',
    'assets/7.jpg',
    'assets/8.jpg',
    'assets/9.jpg',
    'assets/10.png',
    'assets/11.png',
    'assets/12.png',
    'assets/13.png',
    'assets/14.png',
    'assets/15.png',
    'assets/16.png',
    'assets/17.png',
  ];

  // Map of asset file names to their Firebase IDs
  Map<String, String> assetToIdMap = {};

  // Upload all asset images to Firebase
  Future<Map<String, String>> uploadAllAssets(
    BuildContext context, {
    bool showProgress = true,
  }) async {
    try {
      OverlayEntry? loader;

      if (showProgress) {
        loader = _createProgressOverlay(context);
        Overlay.of(context).insert(loader);
      }

      for (String assetPath in _assetImages) {
        String assetName = assetPath.split('/').last;

        // Convert asset to base64
        String base64Image = await ImageUtils.assetToBase64(assetPath);

        // Upload to Firebase
        String imageId = await _firebaseService.uploadBase64Image(
          base64Image,
          'product_images',
        );

        // Store in map
        assetToIdMap[assetName] = imageId;
      }

      if (showProgress && loader != null) {
        loader.remove();
      }

      // Show success message if requested
      if (showProgress) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All assets uploaded successfully!')),
        );
      }

      return assetToIdMap;
    } catch (e) {
      if (showProgress) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading assets: ${e.toString()}')),
        );
      }
      return {};
    }
  }

  // Create a loading overlay
  OverlayEntry _createProgressOverlay(BuildContext context) {
    return OverlayEntry(
      builder:
          (context) => Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Uploading assets...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
