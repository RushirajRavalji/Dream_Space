import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageUtils {
  /// Converts a File to base64 string with compression
  static Future<String> fileToBase64(File file) async {
    try {
      // Compress the image first
      final Uint8List? compressedBytes =
          await FlutterImageCompress.compressWithFile(
            file.absolute.path,
            minWidth: 1024,
            minHeight: 1024,
            quality: 85,
          );

      if (compressedBytes == null) {
        // Fallback to original if compression fails
        final bytes = await file.readAsBytes();
        return base64Encode(bytes);
      }

      return base64Encode(compressedBytes);
    } catch (e) {
      // If compression fails, use the original file
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    }
  }

  /// Converts a XFile to base64 string with compression
  static Future<String> xFileToBase64(XFile file) async {
    try {
      // Compress the image first
      final Uint8List? compressedBytes =
          await FlutterImageCompress.compressWithFile(
            file.path,
            minWidth: 1024,
            minHeight: 1024,
            quality: 85,
          );

      if (compressedBytes == null) {
        // Fallback to original if compression fails
        final bytes = await file.readAsBytes();
        return base64Encode(bytes);
      }

      return base64Encode(compressedBytes);
    } catch (e) {
      // If compression fails, use the original file
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    }
  }

  /// Converts an asset image to base64 string
  static Future<String> assetToBase64(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final bytes = byteData.buffer.asUint8List();
    return base64Encode(bytes);
  }

  /// Decodes a base64 string to memory
  static Uint8List base64ToBytes(String base64String) {
    return base64Decode(base64String);
  }
}
