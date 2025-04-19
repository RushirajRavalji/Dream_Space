import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../utils/firebase_collections.dart';

class ProductFirebaseService {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections from utility class
  CollectionReference get _productsCollection =>
      FirebaseCollections.productsCollection;
  CollectionReference get _productImagesCollection =>
      FirebaseCollections.productImagesCollection;
  CollectionReference get _productImagesChunksCollection =>
      FirebaseCollections.productImagesChunksCollection;

  // Get current user ID
  String get currentUserId => _auth.currentUser?.uid ?? '';

  // CRUD OPERATIONS

  // Get all products
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final QuerySnapshot snapshot = await _productsCollection.get();
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  // Get products by category
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final QuerySnapshot snapshot =
          await _productsCollection
              .where('category', isEqualTo: category)
              .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching products by category: $e');
      return [];
    }
  }

  // Get featured products
  Future<List<ProductModel>> getFeaturedProducts() async {
    try {
      final QuerySnapshot snapshot =
          await _productsCollection.where('isFeatured', isEqualTo: true).get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching featured products: $e');
      return [];
    }
  }

  // Get product by ID
  Future<ProductModel?> getProductById(String productId) async {
    try {
      final DocumentSnapshot doc =
          await _productsCollection.doc(productId).get();
      if (!doc.exists) {
        return null;
      }
      return ProductModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error fetching product by ID: $e');
      return null;
    }
  }

  // Add product
  Future<String> addProduct(ProductModel product) async {
    try {
      // Generate a new ID
      final String productId = const Uuid().v4();

      // Create a new product with the generated ID
      final ProductModel newProduct = product.copyWith(
        id: productId,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _productsCollection.doc(productId).set(newProduct.toMap());

      return productId;
    } catch (e) {
      debugPrint('Error adding product: $e');
      throw Exception('Failed to add product: $e');
    }
  }

  // Update product
  Future<void> updateProduct(ProductModel product) async {
    try {
      // Update with current timestamp
      final ProductModel updatedProduct = product.copyWith(
        updatedAt: DateTime.now(),
      );

      await _productsCollection.doc(product.id).update(updatedProduct.toMap());
    } catch (e) {
      debugPrint('Error updating product: $e');
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      // Get the product to find image IDs
      final ProductModel? product = await getProductById(productId);

      // Delete the product document
      await _productsCollection.doc(productId).delete();

      // Delete associated images
      if (product != null) {
        for (final String imageId in product.imageUrls) {
          await _deleteImage(imageId);
        }
      }
    } catch (e) {
      debugPrint('Error deleting product: $e');
      throw Exception('Failed to delete product: $e');
    }
  }

  // IMAGE HANDLING

  // Convert file to base64
  Future<String> fileToBase64(File file) async {
    try {
      final List<int> bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('Error converting file to base64: $e');
      throw Exception('Failed to convert file to base64: $e');
    }
  }

  // Convert base64 to file
  Future<File> base64ToFile(String base64String, String fileName) async {
    try {
      final List<int> bytes = base64Decode(base64String);
      final Directory tempDir = await Directory.systemTemp.createTemp();
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      debugPrint('Error converting base64 to file: $e');
      throw Exception('Failed to convert base64 to file: $e');
    }
  }

  // Upload image file
  Future<String> uploadImage(File imageFile) async {
    try {
      // Convert file to base64
      final String base64String = await fileToBase64(imageFile);

      // Generate unique ID
      final String imageId = const Uuid().v4();

      // Store in Firestore
      await _productImagesCollection.doc(imageId).set({
        'id': imageId,
        'type': 'single',
        'base64': base64String,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return imageId;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload multiple images
  Future<List<String>> uploadImages(List<File> imageFiles) async {
    final List<String> imageIds = [];

    for (final File file in imageFiles) {
      final String imageId = await uploadImage(file);
      imageIds.add(imageId);
    }

    return imageIds;
  }

  // Get image as base64
  Future<String> getImageBase64(String imageId) async {
    try {
      final DocumentSnapshot doc =
          await _productImagesCollection.doc(imageId).get();

      if (!doc.exists) {
        throw Exception('Image not found');
      }

      final data = doc.data() as Map<String, dynamic>;

      // Handle chunked images
      if (data['type'] == 'chunked') {
        return await _getChunkedImageBase64(imageId, data['totalChunks']);
      }

      return data['base64'] as String;
    } catch (e) {
      debugPrint('Error getting image: $e');
      throw Exception('Failed to get image: $e');
    }
  }

  // Get chunked image as base64
  Future<String> _getChunkedImageBase64(String imageId, int totalChunks) async {
    String fullBase64 = '';

    for (int i = 0; i < totalChunks; i++) {
      final chunkDoc =
          await _productImagesChunksCollection.doc('${imageId}$i').get();

      if (!chunkDoc.exists) {
        throw Exception('Image chunk not found');
      }

      final data = chunkDoc.data() as Map<String, dynamic>;
      fullBase64 += data['data'];
    }

    return fullBase64;
  }

  // Get image as File
  Future<File> getImageFile(String imageId) async {
    try {
      final String base64String = await getImageBase64(imageId);
      return await base64ToFile(base64String, '$imageId.jpg');
    } catch (e) {
      debugPrint('Error getting image file: $e');
      throw Exception('Failed to get image file: $e');
    }
  }

  // Delete image
  Future<void> _deleteImage(String imageId) async {
    try {
      final doc = await _productImagesCollection.doc(imageId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;

        // Delete base image document
        await _productImagesCollection.doc(imageId).delete();

        // Delete chunks if it's a chunked image
        if (data != null && data['type'] == 'chunked') {
          final int totalChunks = data['totalChunks'];

          for (int i = 0; i < totalChunks; i++) {
            await _productImagesChunksCollection.doc('${imageId}$i').delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
      // Continue even if image deletion fails
    }
  }

  // Get categories
  Future<List<CategoryModel>> getCategories() async {
    try {
      final QuerySnapshot snapshot =
          await FirebaseCollections.categoriesCollection.get();
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }
}
