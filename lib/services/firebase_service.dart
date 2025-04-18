import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

class FirebaseService {
  // Firebase instances - lazy initialized
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Collections - lazy initialized
  CollectionReference get _usersCollection =>
      FirebaseFirestore.instance.collection('users');
  CollectionReference get _productsCollection =>
      FirebaseFirestore.instance.collection('products');
  CollectionReference get _categoriesCollection =>
      FirebaseFirestore.instance.collection('categories');

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check connectivity before operations
  Future<bool> checkConnectivity() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();

      // With newer connectivity_plus, connectivityResult might be a list
      if (connectivityResult is List) {
        // If it's a list, check if any result indicates connectivity
        return connectivityResult.isNotEmpty &&
            connectivityResult.first != ConnectivityResult.none;
      } else {
        // Legacy behavior
        return connectivityResult != ConnectivityResult.none;
      }
    } catch (e) {
      print('Warning: Connectivity check failed: $e');
      // If we can't check connectivity, assume we're online
      return true;
    }
  }

  // Initialize Firebase Auth persistence
  Future<void> initializeAuthPersistence() async {
    try {
      // Set persistence to LOCAL (survives app restarts)
      await _auth.setPersistence(Persistence.LOCAL);
    } catch (e) {
      print('Warning: Could not set auth persistence: ${e.toString()}');
      // Continue anyway as this is not critical
    }
  }

  // Register with email and password
  Future<UserModel> registerWithEmailAndPassword(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      // Create user with email and password
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Safety check
      if (result.user == null) {
        throw Exception(
          'User registration failed: User is null after registration',
        );
      }

      // Update display name
      await result.user!.updateDisplayName(fullName);

      // Create user in Firestore
      UserModel user = UserModel(
        id: result.user!.uid,
        email: email,
        fullName: fullName,
        wishlist: [],
        createdAt: DateTime.now(),
      );

      // Save to Firestore with a retry mechanism in case of network issues
      await _saveUserDataWithRetry(result.user!.uid, user.toMap());

      return user;
    } on FirebaseAuthException catch (e) {
      // Throw more user-friendly error messages
      String message = 'Registration failed';

      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email address is already in use';
          break;
        case 'invalid-email':
          message = 'The email address is not valid';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled';
          break;
        case 'weak-password':
          message = 'Password is too weak';
          break;
        default:
          message = 'Registration error: ${e.message}';
      }

      throw Exception(message);
    } catch (e) {
      throw Exception('Registration error: ${e.toString()}');
    }
  }

  // Save user data with retry mechanism
  Future<void> _saveUserDataWithRetry(
    String uid,
    Map<String, dynamic> userData,
  ) async {
    int maxRetries = 3;

    for (int i = 0; i < maxRetries; i++) {
      try {
        await _usersCollection.doc(uid).set(userData);
        return;
      } catch (e) {
        if (i == maxRetries - 1) {
          throw Exception(
            'Failed to save user data to Firestore after multiple attempts',
          );
        }
        // Wait a bit before retrying
        await Future.delayed(Duration(seconds: 1));
      }
    }
  }

  // Login with email and password
  Future<UserModel> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Check connectivity first
      bool isConnected = await checkConnectivity();
      if (!isConnected) {
        throw Exception(
          'No internet connection. Please check your network settings and try again.',
        );
      }

      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Safety check
      if (result.user == null) {
        throw Exception('Login failed: User is null after login');
      }

      return await getUserData();
    } on FirebaseAuthException catch (e) {
      // Throw more user-friendly error messages
      String message = 'Login failed';

      switch (e.code) {
        case 'invalid-email':
          message = 'The email address is not valid';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled';
          break;
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        default:
          message = 'Login error: ${e.message}';
      }

      throw Exception(message);
    } catch (e) {
      throw Exception('Login error: ${e.toString()}');
    }
  }

  // Logout with retry
  Future<void> logout() async {
    int retries = 0;
    Exception? lastError;

    while (retries < 3) {
      try {
        await _auth.signOut();
        return; // Success
      } catch (e) {
        retries++;
        lastError = Exception('Logout error: ${e.toString()}');
        await Future.delayed(Duration(milliseconds: 500)); // Wait before retry
      }
    }

    // If we got here, all retries failed
    throw lastError ?? Exception('Logout failed after multiple attempts');
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Error resetting password: ${e.toString()}');
    }
  }

  // Get user data
  Future<UserModel> getUserData() async {
    try {
      User? user = _auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user document with retry
      DocumentSnapshot? userDoc;
      int retries = 0;
      while (retries < 3 && (userDoc == null || !userDoc.exists)) {
        try {
          userDoc = await _usersCollection.doc(user.uid).get();

          if (!userDoc.exists) {
            // Create a basic user document if it doesn't exist
            UserModel newUser = UserModel(
              id: user.uid,
              email: user.email ?? '',
              fullName: user.displayName ?? 'User',
              wishlist: [],
              createdAt: DateTime.now(),
            );

            await _usersCollection.doc(user.uid).set(newUser.toMap());
            // Fetch the document again
            userDoc = await _usersCollection.doc(user.uid).get();
          }

          break; // Success, exit the retry loop
        } catch (e) {
          retries++;
          if (retries >= 3) throw e; // Re-throw after max retries
          await Future.delayed(Duration(seconds: 1)); // Wait before retry
        }
      }

      if (userDoc == null || !userDoc.exists) {
        throw Exception('Failed to get user data after multiple attempts');
      }

      return UserModel.fromFirestore(userDoc);
    } on FirebaseException catch (e) {
      throw Exception('Error getting user data: ${e.message}');
    } catch (e) {
      throw Exception('Error getting user data: ${e.toString()}');
    }
  }

  // Update user data
  Future<void> updateUserData(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).update(user.toMap());
    } catch (e) {
      throw Exception('Error updating user data: ${e.toString()}');
    }
  }

  // Update user display name
  Future<void> updateDisplayName(String fullName) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(fullName);
      }
    } catch (e) {
      throw Exception('Error updating display name: ${e.toString()}');
    }
  }

  // Upload user profile image (as Base64)
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      // Convert file to base64 string
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Get current user
      User? user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Update user data with base64 image
      await _usersCollection.doc(user.uid).update({
        'profileImageUrl': base64Image,
      });

      return base64Image;
    } catch (e) {
      throw Exception('Error uploading profile image: ${e.toString()}');
    }
  }

  // Add to wishlist
  Future<void> addToWishlist(String productId) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _usersCollection.doc(user.uid).update({
        'wishlist': FieldValue.arrayUnion([productId]),
      });
    } catch (e) {
      throw Exception('Error adding to wishlist: ${e.toString()}');
    }
  }

  // Remove from wishlist
  Future<void> removeFromWishlist(String productId) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _usersCollection.doc(user.uid).update({
        'wishlist': FieldValue.arrayRemove([productId]),
      });
    } catch (e) {
      throw Exception('Error removing from wishlist: ${e.toString()}');
    }
  }

  // Check if product is in wishlist
  Future<bool> isInWishlist(String productId) async {
    try {
      DocumentSnapshot userDoc =
          await _usersCollection.doc(currentUser!.uid).get();
      UserModel user = UserModel.fromFirestore(userDoc);
      return user.wishlist.contains(productId);
    } catch (e) {
      return false;
    }
  }

  // Get wishlist products
  Future<List<dynamic>> getWishlistProducts() async {
    try {
      UserModel user = await getUserData();

      if (user.wishlist.isEmpty) {
        return [];
      }

      QuerySnapshot querySnapshot =
          await _productsCollection
              .where(FieldPath.documentId, whereIn: user.wishlist)
              .get();

      return querySnapshot.docs;
    } catch (e) {
      throw Exception('Error getting wishlist: ${e.toString()}');
    }
  }

  // Get products by category
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      QuerySnapshot querySnapshot =
          await _productsCollection
              .where('category', isEqualTo: category)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get featured products
  Future<List<ProductModel>> getFeaturedProducts() async {
    try {
      print("TRYING TO GET FEATURED PRODUCTS");

      // First, get all products to check them
      final allProducts = await _productsCollection.get();
      print("Total products found: ${allProducts.docs.length}");

      // Debug output for all products
      for (var doc in allProducts.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          print(
            "Product: ${data['name'] ?? 'Unknown'} | isFeatured: ${data['isFeatured']} | Type: ${data['isFeatured']?.runtimeType}",
          );
        }
      }

      // Try multiple query approaches to catch type mismatches
      List<ProductModel> featuredProducts = [];

      // Approach 1: Boolean true
      final querySnapshotBool =
          await _productsCollection.where('isFeatured', isEqualTo: true).get();
      print("Boolean query found: ${querySnapshotBool.docs.length}");

      // Approach 2: String "true"
      final querySnapshotString =
          await _productsCollection
              .where('isFeatured', isEqualTo: "true")
              .get();
      print("String query found: ${querySnapshotString.docs.length}");

      // Add both results (will handle duplicates later)
      for (var doc in querySnapshotBool.docs) {
        featuredProducts.add(ProductModel.fromFirestore(doc));
      }

      for (var doc in querySnapshotString.docs) {
        final model = ProductModel.fromFirestore(doc);
        if (!featuredProducts.any((p) => p.id == model.id)) {
          featuredProducts.add(model);
        }
      }

      // If still no products, check all products and manually filter for isFeatured
      if (featuredProducts.isEmpty) {
        for (var doc in allProducts.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final isFeatured = data['isFeatured'];

            // Try various types of "true" values
            if (isFeatured == true ||
                isFeatured == "true" ||
                isFeatured == 1 ||
                isFeatured == "1") {
              final model = ProductModel.fromFirestore(doc);
              featuredProducts.add(model);
            }
          }
        }
      }

      print("Final featured products count: ${featuredProducts.length}");

      return featuredProducts;
    } catch (e) {
      print("Error getting featured products: $e");
      return [];
    }
  }

  // Get all categories
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      QuerySnapshot querySnapshot = await _categoriesCollection.get();

      return querySnapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get product by id
  Future<ProductModel?> getProductById(String productId) async {
    try {
      DocumentSnapshot productDoc =
          await _productsCollection.doc(productId).get();

      if (!productDoc.exists) {
        return null;
      }

      return ProductModel.fromFirestore(productDoc);
    } catch (e) {
      return null;
    }
  }

  // Create initial categories and products (for demo purposes)
  Future<void> createInitialData() async {
    // Check if there are already categories
    QuerySnapshot categoriesCheck = await _categoriesCollection.limit(1).get();
    if (categoriesCheck.docs.isNotEmpty) {
      return; // Data already exists
    }

    // Create categories
    List<Map<String, dynamic>> categories = [
      {
        'name': 'Accent Chairs',
        'imageUrl': 'assets/5.png',
        'itemCount': '24 items',
        'color': '0xFFD8A17E', // Using theme secondary color
        'description': 'Stylish accent chairs to complement your living space',
      },
      {
        'name': 'Living Room',
        'imageUrl': 'assets/1.png',
        'itemCount': '36 items',
        'color': '0xFF555B6E', // Using a color from theme gradient
        'description': 'Beautiful furniture for your living room',
      },
      {
        'name': 'Dining',
        'imageUrl': 'assets/3.png',
        'itemCount': '18 items',
        'color': '0xFFE8D4C3', // Using theme accent color
        'description': 'Elegant dining tables and chairs',
      },
      {
        'name': 'Office',
        'imageUrl': 'assets/4.png',
        'itemCount': '15 items',
        'color': '0xFF2D3142', // Using theme primary color
        'description': 'Comfortable and productive office furniture',
      },
      {
        'name': 'Bedroom',
        'imageUrl': 'assets/1.png',
        'itemCount': '22 items',
        'color': '0xFF9CA0AB', // Using theme text light color
        'description': 'Peaceful and restful bedroom furniture',
      },
    ];

    // Add categories to Firestore
    for (var category in categories) {
      await _categoriesCollection.add(category);
    }

    // Create sample products (2 per category)
    List<Map<String, dynamic>> products = [];

    // Accent Chairs products
    products.add({
      'name': 'Modern Accent Chair',
      'description':
          'A beautiful modern accent chair with premium materials and sleek design.',
      'price': 870.0,
      'category': 'Accent Chairs',
      'imageUrls': ['assets/10.png'],
      'isAvailable': true,
      'rating': 4.5,
      'reviewCount': 12,
      'createdAt': Timestamp.now(),
      'specifications': {
        'dimensions': '30"W x 32"D x 34"H',
        'weight': '25 lbs',
        'material': 'Leather, Wood',
        'color': 'Gray',
      },
    });

    products.add({
      'name': 'Luxurious Velvet Chair',
      'description':
          'Elegant velvet chair perfect for any living room or bedroom setting.',
      'price': 1250.0,
      'category': 'Accent Chairs',
      'imageUrls': ['assets/5.png'],
      'isAvailable': true,
      'rating': 4.8,
      'reviewCount': 18,
      'createdAt': Timestamp.now(),
      'specifications': {
        'dimensions': '32"W x 34"D x 36"H',
        'weight': '28 lbs',
        'material': 'Velvet, Steel',
        'color': 'Blue',
      },
    });

    // Living Room products
    products.add({
      'name': 'Sectional Sofa',
      'description': 'Modern L-shaped sectional sofa with premium comfort.',
      'price': 2450.0,
      'category': 'Living Room',
      'imageUrls': ['assets/6.jpg'],
      'isAvailable': true,
      'rating': 4.7,
      'reviewCount': 32,
      'createdAt': Timestamp.now(),
      'specifications': {
        'dimensions': '112"W x 85"D x 38"H',
        'weight': '180 lbs',
        'material': 'Fabric, Wood',
        'color': 'Gray',
      },
    });

    products.add({
      'name': 'Coffee Table',
      'description': 'Minimalist coffee table with glass top and wooden legs.',
      'price': 650.0,
      'category': 'Living Room',
      'imageUrls': ['assets/7.jpg'],
      'isAvailable': true,
      'rating': 4.4,
      'reviewCount': 15,
      'createdAt': Timestamp.now(),
      'specifications': {
        'dimensions': '48"W x 24"D x 18"H',
        'weight': '45 lbs',
        'material': 'Glass, Wood',
        'color': 'Natural',
      },
    });

    // Add products to Firestore
    for (var product in products) {
      await _productsCollection.add(product);
    }
  }

  // Upload base64 image to Firestore
  Future<String> uploadBase64Image(
    String base64Image,
    String collectionName,
  ) async {
    try {
      bool isConnected = await checkConnectivity();
      if (!isConnected) {
        throw Exception(
          'No internet connection. Please check your network settings.',
        );
      }

      // Create a unique ID for the image
      String imageId = const Uuid().v4();

      // Check if base64 string is too large for a single document (Firestore limit is 1MB)
      // Split into chunks if needed
      const int maxChunkSize = 750000; // Safely under 1MB limit

      if (base64Image.length > maxChunkSize) {
        // Create a reference document that points to the chunks
        await _firestore.collection(collectionName).doc(imageId).set({
          'id': imageId,
          'type': 'chunked',
          'totalChunks': (base64Image.length / maxChunkSize).ceil(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Split the base64 string into chunks and store each chunk
        int totalChunks = (base64Image.length / maxChunkSize).ceil();
        for (int i = 0; i < totalChunks; i++) {
          int start = i * maxChunkSize;
          int end = (i + 1) * maxChunkSize;
          if (end > base64Image.length) end = base64Image.length;

          String chunk = base64Image.substring(start, end);

          await _firestore
              .collection('${collectionName}_chunks')
              .doc('${imageId}_$i')
              .set({
                'imageId': imageId,
                'chunkIndex': i,
                'data': chunk,
                'createdAt': FieldValue.serverTimestamp(),
              });
        }
      } else {
        // Store the base64 image in a single document
        await _firestore.collection(collectionName).doc(imageId).set({
          'id': imageId,
          'type': 'single',
          'base64': base64Image,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return imageId;
    } catch (e) {
      throw Exception('Failed to upload base64 image: ${e.toString()}');
    }
  }

  // Get base64 image from Firestore
  Future<String> getBase64Image(String imageId, String collectionName) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(collectionName).doc(imageId).get();

      if (!doc.exists) {
        throw Exception('Image not found');
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Check if the image is stored as chunks
      if (data['type'] == 'chunked') {
        // Reconstruct from chunks
        int totalChunks = data['totalChunks'];
        String fullBase64 = '';

        for (int i = 0; i < totalChunks; i++) {
          DocumentSnapshot chunkDoc =
              await _firestore
                  .collection('${collectionName}_chunks')
                  .doc('${imageId}_$i')
                  .get();

          if (!chunkDoc.exists) {
            throw Exception('Image chunk not found');
          }

          Map<String, dynamic> chunkData =
              chunkDoc.data() as Map<String, dynamic>;
          fullBase64 += chunkData['data'];
        }

        return fullBase64;
      } else {
        // Single document storage
        return data['base64'] as String;
      }
    } catch (e) {
      throw Exception('Failed to get base64 image: ${e.toString()}');
    }
  }

  // Convert assets to base64 and upload to Firestore
  Future<List<String>> uploadAssetImagesToFirebase(
    List<String> assetPaths,
  ) async {
    try {
      List<String> imageIds = [];

      for (String assetPath in assetPaths) {
        String base64Image = await _convertAssetToBase64(assetPath);
        String imageId = await uploadBase64Image(base64Image, 'product_images');
        imageIds.add(imageId);
      }

      return imageIds;
    } catch (e) {
      throw Exception('Failed to upload asset images: ${e.toString()}');
    }
  }

  // Helper method to convert asset to base64
  Future<String> _convertAssetToBase64(String assetPath) async {
    try {
      ByteData data = await rootBundle.load(assetPath);
      List<int> bytes = data.buffer.asUint8List();
      return base64Encode(bytes);
    } catch (e) {
      throw Exception('Failed to convert asset to base64: ${e.toString()}');
    }
  }

  // Upload multiple base64 images and return their IDs
  Future<List<String>> uploadMultipleBase64Images(
    List<String> base64Images,
  ) async {
    List<String> imageIds = [];

    for (String base64Image in base64Images) {
      String imageId = await uploadBase64Image(base64Image, 'product_images');
      imageIds.add(imageId);
    }

    return imageIds;
  }

  // Fix all products to ensure their isFeatured field is a boolean
  Future<void> fixAllProductsFeaturedStatus() async {
    try {
      print("Starting database fix for featured products...");

      // Get all products
      final querySnapshot = await _productsCollection.get();
      print("Found ${querySnapshot.docs.length} products to check");

      int fixedCount = 0;

      // Check each product
      for (var doc in querySnapshot.docs) {
        try {
          final docData = doc.data() as Map<String, dynamic>?;
          if (docData != null) {
            // Print raw data for debugging
            print("Doc ${doc.id} raw data: $docData");

            final dynamic isFeatured =
                docData.containsKey('isFeatured')
                    ? docData['isFeatured']
                    : false;
            print(
              "Doc ${doc.id} isFeatured value: $isFeatured (type: ${isFeatured?.runtimeType})",
            );

            // Always fix every product (more aggressive approach)
            bool featuredValue;

            // Determine featured value based on current data
            if (isFeatured == true ||
                isFeatured == "true" ||
                isFeatured == 1 ||
                isFeatured == "1" ||
                isFeatured == "yes") {
              featuredValue = true;
            } else {
              featuredValue = false;
            }

            // Always update with boolean value
            print(
              "Updating product ${doc.id} (${docData['name'] ?? 'unknown'}) - setting isFeatured to $featuredValue",
            );
            await _productsCollection.doc(doc.id).update({
              'isFeatured': featuredValue,
            });

            fixedCount++;
          }
        } catch (docError) {
          print("Error processing document ${doc.id}: $docError");
        }
      }

      print("Database fix complete. Fixed $fixedCount products.");

      // Run a check after fixing
      final checkSnapshot =
          await _productsCollection.where('isFeatured', isEqualTo: true).get();
      print(
        "After fix: Found ${checkSnapshot.docs.length} products with isFeatured=true",
      );

      // List featured products for verification
      for (var doc in checkSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          print("Featured product: ${data['name'] ?? doc.id}");
        }
      }

      return;
    } catch (e) {
      print("Error fixing products: $e");
      return;
    }
  }
}
