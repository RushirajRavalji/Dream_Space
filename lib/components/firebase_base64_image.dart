import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/firebase_service.dart';

class FirebaseBase64Image extends StatefulWidget {
  final String imageId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final String collectionName;

  const FirebaseBase64Image({
    Key? key,
    required this.imageId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.collectionName = 'product_images',
  }) : super(key: key);

  @override
  _FirebaseBase64ImageState createState() => _FirebaseBase64ImageState();
}

class _FirebaseBase64ImageState extends State<FirebaseBase64Image> {
  final FirebaseService _firebaseService = FirebaseService();
  String? _base64String;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(FirebaseBase64Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageId != widget.imageId) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageId.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Invalid image ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final base64String = await _firebaseService.getBase64Image(
        widget.imageId,
        widget.collectionName,
      );

      setState(() {
        _base64String = base64String;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          );
    }

    if (_hasError || _base64String == null) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[200],
            child: Center(child: Icon(Icons.error, color: Colors.red[300])),
          );
    }

    try {
      return Image.memory(
        base64Decode(_base64String!),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return widget.errorWidget ??
              Container(
                width: widget.width,
                height: widget.height,
                color: Colors.grey[200],
                child: Center(
                  child: Icon(Icons.broken_image, color: Colors.red[300]),
                ),
              );
        },
      );
    } catch (e) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[200],
            child: Center(
              child: Icon(Icons.broken_image, color: Colors.red[300]),
            ),
          );
    }
  }
}
