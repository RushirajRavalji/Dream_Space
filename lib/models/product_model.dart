import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../services/firebase_service.dart';
import 'package:flutter/services.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String>
  imageUrls; // These are now Firestore document IDs for base64 images
  final bool isAvailable;
  final double rating;
  final int reviewCount;
  final Map<String, dynamic> specifications;
  final Map<String, dynamic>? dimensions;
  final List<String>? colors;
  final List<String>? materials;
  final String? brand;
  final double? discountPrice;
  final int? stockQuantity;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrls,
    required this.isAvailable,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.specifications,
    this.dimensions,
    this.colors,
    this.materials,
    this.brand,
    this.discountPrice,
    this.stockQuantity,
    this.isFeatured = false,
    required this.createdAt,
    this.updatedAt,
  });

  // Copy with method
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    List<String>? imageUrls,
    bool? isAvailable,
    double? rating,
    int? reviewCount,
    Map<String, dynamic>? specifications,
    Map<String, dynamic>? dimensions,
    List<String>? colors,
    List<String>? materials,
    String? brand,
    double? discountPrice,
    int? stockQuantity,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      specifications: specifications ?? this.specifications,
      dimensions: dimensions ?? this.dimensions,
      colors: colors ?? this.colors,
      materials: materials ?? this.materials,
      brand: brand ?? this.brand,
      discountPrice: discountPrice ?? this.discountPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imageUrls': imageUrls,
      'isAvailable': isAvailable,
      'rating': rating,
      'reviewCount': reviewCount,
      'specifications': specifications,
      'dimensions': dimensions,
      'colors': colors,
      'materials': materials,
      'brand': brand,
      'discountPrice': discountPrice,
      'stockQuantity': stockQuantity,
      'isFeatured': isFeatured,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create from Firestore
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      isAvailable: data['isAvailable'] ?? true,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      specifications: data['specifications'] ?? {},
      dimensions: data['dimensions'],
      colors: data['colors'] != null ? List<String>.from(data['colors']) : null,
      materials:
          data['materials'] != null
              ? List<String>.from(data['materials'])
              : null,
      brand: data['brand'],
      discountPrice:
          data['discountPrice'] != null
              ? (data['discountPrice']).toDouble()
              : null,
      stockQuantity: data['stockQuantity'],
      isFeatured: data['isFeatured'] ?? false,
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      updatedAt:
          data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : null,
    );
  }

  // Create from Map
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      category: map['category'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      isAvailable: map['isAvailable'] ?? true,
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      specifications: map['specifications'] ?? {},
      dimensions: map['dimensions'],
      colors: map['colors'] != null ? List<String>.from(map['colors']) : null,
      materials:
          map['materials'] != null ? List<String>.from(map['materials']) : null,
      brand: map['brand'],
      discountPrice:
          map['discountPrice'] != null
              ? (map['discountPrice']).toDouble()
              : null,
      stockQuantity: map['stockQuantity'],
      isFeatured: map['isFeatured'] ?? false,
      createdAt:
          map['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
              : DateTime.now(),
      updatedAt:
          map['updatedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
              : null,
    );
  }

  // Helper method to get image files from image IDs
  Future<List<File>> getImageFiles() async {
    try {
      final firebaseService = FirebaseService();
      return await firebaseService.getProductImagesFromIds(imageUrls);
    } catch (e) {
      print('Error getting image files: $e');
      return [];
    }
  }

  // Get the first image as a File
  Future<File?> getFirstImage() async {
    try {
      print("ProductModel: Getting first image for product ${name} (ID: $id)");
      print("ProductModel: Image URLs: $imageUrls");

      if (imageUrls.isEmpty) {
        print("ProductModel: No image URLs available");
        return null;
      }

      String firstImageId = imageUrls.first;
      print("ProductModel: First image ID: $firstImageId");

      // Check if it's an asset path
      if (firstImageId.startsWith('assets/')) {
        print("ProductModel: Using asset path: $firstImageId");
        // Load as asset and create a temporary file
        final imageData = await rootBundle.load(firstImageId);
        final directory = await Directory.systemTemp.createTemp();
        final file = File('${directory.path}/temp_image.png');
        await file.writeAsBytes(imageData.buffer.asUint8List());
        print("ProductModel: Created temporary file from asset");
        return file;
      }

      // Load from Firebase
      print("ProductModel: Loading image from Firebase");
      final service = FirebaseService();
      final result = await service.getProductImagesFromIds([firstImageId]);

      if (result.isNotEmpty) {
        print("ProductModel: Successfully loaded image from Firebase");
        return result.first;
      } else {
        print("ProductModel: Failed to load image from Firebase");
        return null;
      }
    } catch (e) {
      print("ProductModel: Error getting first image: $e");
      return null;
    }
  }

  // Static helper to upload image files for a product
  static Future<List<String>> uploadProductImages(List<File> imageFiles) async {
    try {
      final firebaseService = FirebaseService();
      return await firebaseService.uploadProductImagesFromFiles(imageFiles);
    } catch (e) {
      print('Error uploading product images: $e');
      return [];
    }
  }
}
