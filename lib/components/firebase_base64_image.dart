import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../utils/app_theme.dart';

class FirebaseBase64Image extends StatefulWidget {
  final String imageId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final String collectionName;
  final bool useCaching;
  final bool lazyLoad;
  final BorderRadius? borderRadius;

  const FirebaseBase64Image({
    Key? key,
    required this.imageId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.collectionName = 'product_images',
    this.useCaching = true,
    this.lazyLoad = true,
    this.borderRadius,
  }) : super(key: key);

  @override
  _FirebaseBase64ImageState createState() => _FirebaseBase64ImageState();
}

class _FirebaseBase64ImageState extends State<FirebaseBase64Image> {
  static final Map<String, Uint8List> _imageCache = {};
  bool _isVisible = false;
  bool _isLoading = false;
  bool _hasError = false;
  Uint8List? _imageBytes;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    if (!widget.lazyLoad) {
      _loadImage();
    } else {
      // Use Future.microtask to avoid blocking the UI
      Future.microtask(() {
        if (!_isDisposed) {
          _checkVisibility();
        }
      });
    }
  }

  @override
  void didUpdateWidget(FirebaseBase64Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageId != oldWidget.imageId) {
      _resetState();
      if (!widget.lazyLoad) {
        _loadImage();
      } else {
        _checkVisibility();
      }
    }
  }

  void _resetState() {
    if (_isDisposed) return;
    setState(() {
      _isLoading = false;
      _hasError = false;
      _imageBytes = null;
    });
  }

  void _checkVisibility() {
    // For lazy loading, we'll detect when the widget is visible in the viewport
    // This is a placeholder - actual visibility detection would require a visibility detector
    if (!_isDisposed) {
      setState(() {
        _isVisible = true;
      });

      if (_isVisible && _imageBytes == null && !_isLoading) {
        _loadImage();
      }
    }
  }

  Future<void> _loadImage() async {
    if (_isLoading || _imageBytes != null || _isDisposed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if image is already in memory cache
      if (widget.useCaching && _imageCache.containsKey(widget.imageId)) {
        if (!_isDisposed) {
          setState(() {
            _imageBytes = _imageCache[widget.imageId];
            _isLoading = false;
          });
        }
        return;
      }

      // Check if the image exists in the disk cache
      if (widget.useCaching) {
        try {
          final file = await DefaultCacheManager().getSingleFile(
            'firebase_base64_${widget.imageId}',
          );
          if (file.existsSync()) {
            final bytes = await file.readAsBytes();
            if (bytes.isNotEmpty && !_isDisposed) {
              setState(() {
                _imageBytes = bytes;
                _isLoading = false;
              });

              // Also update memory cache
              _imageCache[widget.imageId] = bytes;
              return;
            }
          }
        } catch (e) {
          // If disk cache fails, continue with Firestore fetch
          print('Cache fetch failed: $e');
        }
      }

      // Fetch from Firestore if not in cache
      final docRef = FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.imageId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        if (!_isDisposed) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
        return;
      }

      final data = docSnapshot.data();
      if (data == null) {
        if (!_isDisposed) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
        return;
      }

      if (data.containsKey('type') && data['type'] == 'chunked') {
        await _handleChunkedImage(data['totalChunks']);
      } else if (data.containsKey('base64')) {
        _processSingleImage(data['base64']);
      } else {
        if (!_isDisposed) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading image: $e');
      if (!_isDisposed) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleChunkedImage(int totalChunks) async {
    try {
      String fullBase64 = '';

      for (int i = 0; i < totalChunks; i++) {
        final chunkDoc =
            await FirebaseFirestore.instance
                .collection('${widget.collectionName}_chunks')
                .doc('${widget.imageId}_$i')
                .get();

        if (!chunkDoc.exists) {
          throw Exception('Image chunk not found');
        }

        final chunkData = chunkDoc.data();
        if (chunkData == null) {
          throw Exception('Chunk data is null');
        }

        fullBase64 += chunkData['data'];
      }

      _processSingleImage(fullBase64);
    } catch (e) {
      print('Error handling chunked image: $e');
      if (!_isDisposed) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _processSingleImage(String base64String) {
    try {
      if (base64String.isEmpty) {
        throw Exception('Base64 string is empty');
      }

      // Process based on string format
      String processedBase64 = base64String;
      if (base64String.contains(',')) {
        processedBase64 = base64String.split(',').last;
      }

      final bytes = base64Decode(processedBase64);

      if (!_isDisposed) {
        setState(() {
          _imageBytes = bytes;
          _isLoading = false;
        });

        // Cache the image
        if (widget.useCaching) {
          _imageCache[widget.imageId] = bytes;
          try {
            DefaultCacheManager().putFile(
              'firebase_base64_${widget.imageId}',
              bytes,
              key: 'firebase_base64_${widget.imageId}',
              fileExtension: 'jpg',
              maxAge: const Duration(days: 30),
            );
          } catch (e) {
            print('Failed to cache image: $e');
          }
        }
      }
    } catch (e) {
      print('Error processing image: $e');
      if (!_isDisposed) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ?? _buildPlaceholder();
    }

    if (_hasError || _imageBytes == null) {
      return widget.errorWidget ?? _buildErrorWidget();
    }

    final imageWidget = Image.memory(
      _imageBytes!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey[500],
          size: 24,
        ),
      ),
    );
  }
}
