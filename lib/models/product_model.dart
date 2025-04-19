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
  final List<String> imageUrls;
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

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;

      // Validate required fields
      if (data['name'] == null ||
          data['description'] == null ||
          data['price'] == null ||
          data['category'] == null) {
        throw Exception('Missing required fields in product document');
      }

      // Parse price with validation
      double parsedPrice;
      try {
        parsedPrice = (data['price'] as num).toDouble();
        if (parsedPrice < 0) {
          throw Exception('Price cannot be negative');
        }
      } catch (e) {
        throw Exception('Invalid price format: $e');
      }

      // Parse imageUrls with validation
      List<String> parsedImageUrls = [];
      if (data['imageUrls'] != null) {
        try {
          parsedImageUrls = List<String>.from(data['imageUrls']);
        } catch (e) {
          throw Exception('Invalid imageUrls format: $e');
        }
      }

      // Parse specifications with validation
      Map<String, dynamic> parsedSpecifications = {};
      if (data['specifications'] != null) {
        try {
          parsedSpecifications = Map<String, dynamic>.from(
            data['specifications'],
          );
        } catch (e) {
          throw Exception('Invalid specifications format: $e');
        }
      }

      return ProductModel(
        id: doc.id,
        name: data['name'] as String,
        description: data['description'] as String,
        price: parsedPrice,
        category: data['category'] as String,
        imageUrls: parsedImageUrls,
        isAvailable: data['isAvailable'] ?? true,
        rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: data['reviewCount'] ?? 0,
        specifications: parsedSpecifications,
        dimensions:
            data['dimensions'] != null
                ? Map<String, dynamic>.from(data['dimensions'])
                : null,
        colors:
            data['colors'] != null ? List<String>.from(data['colors']) : null,
        materials:
            data['materials'] != null
                ? List<String>.from(data['materials'])
                : null,
        brand: data['brand'],
        discountPrice:
            data['discountPrice'] != null
                ? (data['discountPrice'] as num).toDouble()
                : null,
        stockQuantity: data['stockQuantity'],
        isFeatured: data['isFeatured'] ?? false,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt:
            data['updatedAt'] != null
                ? (data['updatedAt'] as Timestamp).toDate()
                : null,
      );
    } catch (e) {
      throw Exception('Failed to create ProductModel: $e');
    }
  }

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

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
