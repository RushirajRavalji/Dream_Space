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

      // With newer connectivity_plus 6.1.3, it returns a List<ConnectivityResult>
      if (connectivityResult is List<ConnectivityResult>) {
        // If it contains ConnectivityResult.none, then there's no connectivity
        return !connectivityResult.contains(ConnectivityResult.none);
      } else if (connectivityResult is List) {
        // Generic handling for any List type
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

      // Additional check to ensure persistence works even if setPersistence fails silently
      final prefs = await SharedPreferences.getInstance();

      // Get current user
      User? user = _auth.currentUser;

      if (user != null) {
        // Store minimal user info in SharedPreferences as backup
        await prefs.setString('user_email', user.email ?? '');
        await prefs.setString('user_id', user.uid);
        await prefs.setBool('is_logged_in', true);
      }
    } catch (e) {
      print('Warning: Could not set auth persistence: ${e.toString()}');
      // Continue anyway as this is not critical
    }
  }

  // Check if user has valid session
  Future<bool> hasValidSession() async {
    try {
      // First check Firebase Auth
      User? user = _auth.currentUser;
      if (user != null) {
        return true;
      }

      // If Firebase Auth doesn't have a user, check SharedPreferences backup
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final userId = prefs.getString('user_id');

      if (isLoggedIn && userId != null && userId.isNotEmpty) {
        // User was logged in according to SharedPreferences
        // We'll need to fetch a new token, but for now return true
        return true;
      }

      return false;
    } catch (e) {
      print('Error checking session: $e');
      return false;
    }
  }

  // Clear auth data on logout
  Future<void> _clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.remove('user_id');
      await prefs.setBool('is_logged_in', false);
    } catch (e) {
      print('Warning: Could not clear auth data: $e');
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
        await _clearAuthData();
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
      print("FirebaseService: Getting products for category: '$category'");

      // First attempt - standard query
      QuerySnapshot querySnapshot =
          await _productsCollection
              .where('category', isEqualTo: category)
              .get();

      print(
        "FirebaseService: First query returned ${querySnapshot.docs.length} documents",
      );

      List<ProductModel> products =
          querySnapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .toList();

      // If no products found, try a more flexible approach
      if (products.isEmpty) {
        print(
          "FirebaseService: No products with exact match, trying case-insensitive",
        );

        // Get all products
        QuerySnapshot allProductsSnapshot = await _productsCollection.get();
        print(
          "FirebaseService: Found ${allProductsSnapshot.docs.length} total products",
        );

        // Manual filtering for case-insensitive match
        for (var doc in allProductsSnapshot.docs) {
          try {
            Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
            if (data != null && data.containsKey('category')) {
              String productCategory = data['category']?.toString() ?? '';

              // Compare ignoring case
              if (productCategory.trim().toLowerCase() ==
                  category.trim().toLowerCase()) {
                print(
                  "FirebaseService: Adding product with case-insensitive match: ${data['name']}",
                );
                products.add(ProductModel.fromFirestore(doc));
              }
            }
          } catch (e) {
            print("FirebaseService: Error processing document ${doc.id}: $e");
          }
        }
      }

      print(
        "FirebaseService: Returning ${products.length} products for category '$category'",
      );
      return products;
    } catch (e) {
      print("FirebaseService: Error getting products by category: $e");
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

    // First ensure we have a placeholder image for products that may not have images
    try {
      const String placeholderImageId = 'placeholder_product_image';
      DocumentSnapshot placeholderDoc =
          await _firestore
              .collection('product_images')
              .doc(placeholderImageId)
              .get();

      // If placeholder doesn't exist, create one
      if (!placeholderDoc.exists) {
        print('Creating placeholder product image...');

        // Convert a default asset to base64
        String base64Image = await _convertAssetToBase64('assets/1.png');
        if (base64Image.isEmpty) {
          // If asset failed, use a very simple base64 image (1x1 pixel transparent PNG)
          base64Image =
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
        }

        // Store the placeholder
        await _firestore
            .collection('product_images')
            .doc(placeholderImageId)
            .set({
              'id': placeholderImageId,
              'type': 'single',
              'base64': base64Image,
              'createdAt': FieldValue.serverTimestamp(),
            });

        print('✅ Created placeholder image (ID: $placeholderImageId)');
      }
    } catch (e) {
      print('Error creating placeholder image: $e');
    }

    // Create categories with asset paths directly instead of Firebase IDs
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
        'imageUrl': 'assets/6.jpg',
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

  // Fix category inconsistencies in products
  Future<int> fixCategoryInconsistencies(String categoryName) async {
    try {
      print(
        "FirebaseService: Attempting to fix category inconsistencies for '$categoryName'",
      );

      // Get all categories to know valid category names
      final categoriesQuery = await _categoriesCollection.get();
      final List<String> validCategoryNames =
          categoriesQuery.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                return data != null && data.containsKey('name')
                    ? data['name']?.toString() ?? ''
                    : '';
              })
              .where((name) => name.isNotEmpty)
              .toList();

      print("Valid categories: ${validCategoryNames.join(', ')}");

      // Find products with similar but not exactly matching category names
      final productsQuery = await _productsCollection.get();
      int fixedCount = 0;

      for (var doc in productsQuery.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final String productName =
            data['name']?.toString() ?? 'Unnamed product';
        final String productCategory = data['category']?.toString() ?? '';

        // Skip if product doesn't have a category
        if (productCategory.isEmpty) continue;

        // Check if this product needs fixing
        bool needsFix = false;

        // Case 1: Category name matches exactly but with case/whitespace differences
        if (productCategory.trim().toLowerCase() ==
                categoryName.trim().toLowerCase() &&
            productCategory != categoryName) {
          needsFix = true;
          print(
            "Found product '$productName' with case-sensitive mismatch: '$productCategory' vs '$categoryName'",
          );
        }
        // Case 2: Product has misspelled/partial category that should be this category
        else if (productCategory.trim().toLowerCase().contains(
              categoryName.trim().toLowerCase(),
            ) ||
            categoryName.trim().toLowerCase().contains(
              productCategory.trim().toLowerCase(),
            )) {
          needsFix = true;
          print(
            "Found product '$productName' with partial match: '$productCategory' vs '$categoryName'",
          );
        }

        // Fix the product if needed
        if (needsFix) {
          try {
            await _productsCollection.doc(doc.id).update({
              'category': categoryName,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            });
            fixedCount++;
            print(
              "Fixed category for product '$productName' (ID: ${doc.id}) from '$productCategory' to '$categoryName'",
            );
          } catch (e) {
            print("Error updating product ${doc.id}: $e");
          }
        }
      }

      print("Fixed $fixedCount products with category inconsistencies");
      return fixedCount;
    } catch (e) {
      print("Error fixing category inconsistencies: $e");
      return 0;
    }
  }

  // Ensure at least one featured product exists
  Future<void> ensureFeaturedProductExists() async {
    try {
      print("FirebaseService: Checking for featured products...");

      // First check if any featured products already exist
      final featuredSnapshot =
          await _productsCollection
              .where('isFeatured', isEqualTo: true)
              .limit(1)
              .get();

      if (featuredSnapshot.docs.isNotEmpty) {
        print("FirebaseService: Featured product already exists");
        return;
      }

      // No featured products found, mark one existing product as featured
      final allProductsSnapshot = await _productsCollection.limit(1).get();

      if (allProductsSnapshot.docs.isNotEmpty) {
        final productId = allProductsSnapshot.docs.first.id;
        print("FirebaseService: Marking product $productId as featured");

        await _productsCollection.doc(productId).update({
          'isFeatured': true,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });

        print("FirebaseService: Successfully marked product as featured");
      } else {
        // No products at all, create a default featured product
        print(
          "FirebaseService: No products found, creating default featured product",
        );

        final newProductId = const Uuid().v4();
        await _productsCollection.doc(newProductId).set({
          'id': newProductId,
          'name': 'New Arrival Product',
          'description':
              'Check out this beautiful new furniture piece in our collection.',
          'price': 999.0,
          'category': 'Living Room',
          'imageUrls': ['assets/1.png'],
          'isAvailable': true,
          'isFeatured': true,
          'rating': 5.0,
          'reviewCount': 0,
          'specifications': {
            'dimensions': '100cm x 80cm x 60cm',
            'weight': '15 kg',
            'material': 'Premium Wood',
          },
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });

        print("FirebaseService: Created default featured product");
      }
    } catch (e) {
      print("FirebaseService: Error ensuring featured product exists: $e");
    }
  }

  // Diagnostic method to check product images
  Future<void> checkProductImages() async {
    try {
      print('\n===== DIAGNOSTIC: CHECKING PRODUCT IMAGES =====');

      // Get all products
      final productsSnapshot = await _productsCollection.get();
      print('Total products found: ${productsSnapshot.docs.length}');

      // Check each product's images
      int productsWithValidImages = 0;
      int productsWithEmptyImages = 0;
      int productsWithInvalidImages = 0;

      for (var doc in productsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String productName = data['name'] ?? 'Unknown product';
        final List<String> imageUrls = List<String>.from(
          data['imageUrls'] ?? [],
        );

        print('\nChecking product: $productName (ID: ${doc.id})');
        print(
          'Image URLs: ${imageUrls.isEmpty ? "NONE" : imageUrls.join(", ")}',
        );

        if (imageUrls.isEmpty) {
          print('⚠️ WARNING: Product has no images');
          productsWithEmptyImages++;
          continue;
        }

        // Check first image
        try {
          final imageDoc =
              await _firestore
                  .collection('product_images')
                  .doc(imageUrls.first)
                  .get();
          if (imageDoc.exists) {
            print('✅ First image exists in database (ID: ${imageUrls.first})');
            final imageData = imageDoc.data();
            if (imageData != null) {
              print('   Image type: ${imageData['type'] ?? 'unknown'}');
              if (imageData['type'] == 'chunked') {
                print(
                  '   Chunked image with ${imageData['totalChunks']} chunks',
                );
              }
            }
            productsWithValidImages++;
          } else {
            print(
              '❌ ERROR: First image not found in database (ID: ${imageUrls.first})',
            );
            productsWithInvalidImages++;
          }
        } catch (e) {
          print('❌ ERROR checking image: $e');
          productsWithInvalidImages++;
        }
      }

      // Summary
      print('\n===== DIAGNOSTIC SUMMARY =====');
      print('Total products: ${productsSnapshot.docs.length}');
      print('Products with valid images: $productsWithValidImages');
      print('Products with empty image arrays: $productsWithEmptyImages');
      print('Products with invalid images: $productsWithInvalidImages');

      if (productsWithValidImages == 0) {
        print('\n⚠️ CRITICAL ISSUE: No products have valid images!');
        print('This explains why no products are visible in the app.');
      }
    } catch (e) {
      print('Error in diagnostic: $e');
    }
  }

  // Fix products with missing or invalid images
  Future<void> fixProductImages() async {
    try {
      print('\n===== FIXING PRODUCT IMAGES =====');

      // First, check if we have a placeholder image
      const String placeholderImageId = 'placeholder_product_image';
      DocumentSnapshot placeholderDoc =
          await _firestore
              .collection('product_images')
              .doc(placeholderImageId)
              .get();

      // If placeholder doesn't exist, create one
      if (!placeholderDoc.exists) {
        print('Creating placeholder product image...');

        // Convert a default asset to base64
        String base64Image = await _convertAssetToBase64('assets/1.png');
        if (base64Image.isEmpty) {
          // If asset failed, use a very simple base64 image (1x1 pixel transparent PNG)
          base64Image =
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
        }

        // Store the placeholder
        await _firestore
            .collection('product_images')
            .doc(placeholderImageId)
            .set({
              'id': placeholderImageId,
              'type': 'single',
              'base64': base64Image,
              'createdAt': FieldValue.serverTimestamp(),
            });

        print('✅ Created placeholder image (ID: $placeholderImageId)');
      } else {
        print('✅ Placeholder image already exists (ID: $placeholderImageId)');
      }

      // Get all products
      final productsSnapshot = await _productsCollection.get();
      print('Total products found: ${productsSnapshot.docs.length}');

      int fixedProducts = 0;

      // Check and fix each product's images
      for (var doc in productsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String productName = data['name'] ?? 'Unknown product';
        final List<String> imageUrls = List<String>.from(
          data['imageUrls'] ?? [],
        );

        bool needsFix = false;
        List<String> newImageUrls = List<String>.from(imageUrls);

        // Check if product has no images
        if (imageUrls.isEmpty) {
          print('Fixing product with no images: $productName (ID: ${doc.id})');
          newImageUrls.add(placeholderImageId);
          needsFix = true;
        }
        // Check if first image exists
        else {
          try {
            final imageDoc =
                await _firestore
                    .collection('product_images')
                    .doc(imageUrls.first)
                    .get();

            if (!imageDoc.exists) {
              print(
                'Fixing product with invalid image reference: $productName (ID: ${doc.id})',
              );
              newImageUrls[0] =
                  placeholderImageId; // Replace first image with placeholder
              needsFix = true;
            }
          } catch (e) {
            print('Error checking image, will fix: $e');
            newImageUrls[0] = placeholderImageId;
            needsFix = true;
          }
        }

        // Update product if needed
        if (needsFix) {
          await _productsCollection.doc(doc.id).update({
            'imageUrls': newImageUrls,
          });
          fixedProducts++;
          print('✅ Fixed product: $productName (ID: ${doc.id})');
        }
      }

      print('\n===== FIX SUMMARY =====');
      print(
        'Products fixed: $fixedProducts out of ${productsSnapshot.docs.length}',
      );
    } catch (e) {
      print('Error fixing product images: $e');
    }
  }

  // Fix category images that might be using asset paths instead of Firebase IDs
  Future<int> fixCategoryImages() async {
    print('\n===== FIXING CATEGORY IMAGES =====');
    int fixedCount = 0;

    try {
      // Get all categories
      final categoriesSnapshot = await _categoriesCollection.get();
      print('Found ${categoriesSnapshot.docs.length} categories to check');

      for (final doc in categoriesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final String categoryName = data['name'] ?? 'Unknown';
        final String imageUrl = data['imageUrl'] ?? '';
        print('\nChecking category: $categoryName, image: $imageUrl');

        // Check if the imageUrl is an asset path
        if (imageUrl.startsWith('assets/')) {
          print('⚠️ Found asset path in category: $categoryName');

          try {
            // 1. Load the asset and convert to base64
            String base64Image = await _convertAssetToBase64(imageUrl);
            if (base64Image.isEmpty) {
              print('❌ Failed to convert asset to base64 for $categoryName');
              continue;
            }

            // 2. Upload to Firebase
            final imageId = await uploadBase64Image(
              base64Image,
              'category_images',
            );
            print('✅ Uploaded image with ID: $imageId');

            // 3. Update the category in Firestore
            await _categoriesCollection.doc(doc.id).update({
              'imageUrl': imageId,
            });

            print('✅ Updated category: $categoryName with new image ID');
            fixedCount++;
          } catch (e) {
            print('❌ Error fixing category image: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Error in fixCategoryImages: $e');
    }

    print('\n===== FIXED $fixedCount CATEGORY IMAGES =====');
    return fixedCount;
  }

  // Update existing categories to use local asset paths
  Future<int> updateCategoriesToUseAssets() async {
    print('\n===== UPDATING CATEGORIES TO USE LOCAL ASSETS =====');
    int updatedCount = 0;

    try {
      // Get all categories
      final categoriesSnapshot = await _categoriesCollection.get();
      print('Found ${categoriesSnapshot.docs.length} categories to check');

      // Category name to asset path mapping
      final Map<String, String> categoryAssetMap = {
        'Accent Chairs': 'assets/5.png',
        'Living Room': 'assets/6.jpg',
        'Dining': 'assets/3.png',
        'Office': 'assets/4.png',
        'Bedroom': 'assets/1.png',
      };

      // Default asset if category not in map
      const String defaultAsset = 'assets/1.png';

      for (final doc in categoriesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final String categoryName = data['name'] ?? '';
        final String currentImageUrl = data['imageUrl'] ?? '';

        // Skip if already an asset path
        if (currentImageUrl.startsWith('assets/')) {
          print(
            '✅ Category "${categoryName}" already using asset path: ${currentImageUrl}',
          );
          continue;
        }

        // Get appropriate asset path for this category
        final String assetPath = categoryAssetMap[categoryName] ?? defaultAsset;

        // Update the category
        await _categoriesCollection.doc(doc.id).update({'imageUrl': assetPath});

        print(
          '✅ Updated category "${categoryName}" to use asset path: ${assetPath}',
        );
        updatedCount++;
      }
    } catch (e) {
      print('❌ Error updating categories: $e');
    }

    print('\n===== UPDATED $updatedCount CATEGORIES =====');
    return updatedCount;
  }

  // Helper method to convert file to base64
  Future<String> fileToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      throw Exception('Failed to convert file to base64: ${e.toString()}');
    }
  }

  // Helper method to convert base64 string back to file
  Future<File> base64ToFile(String base64String, String fileName) async {
    try {
      final bytes = base64Decode(base64String);
      final directory = await Directory.systemTemp.createTemp();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      throw Exception('Failed to convert base64 to file: ${e.toString()}');
    }
  }

  // Upload product images from files, converting them to base64
  Future<List<String>> uploadProductImagesFromFiles(
    List<File> imageFiles,
  ) async {
    try {
      List<String> imageIds = [];

      for (File file in imageFiles) {
        // Convert file to base64
        String base64Image = await fileToBase64(file);

        // Upload base64 image and get document ID
        String imageId = await uploadBase64Image(base64Image, 'product_images');
        imageIds.add(imageId);
      }

      return imageIds;
    } catch (e) {
      throw Exception('Failed to upload product images: ${e.toString()}');
    }
  }

  // Get product images as Files from a list of image IDs
  Future<List<File>> getProductImagesFromIds(List<String> imageIds) async {
    try {
      List<File> imageFiles = [];

      for (String imageId in imageIds) {
        // Get base64 string from Firestore
        String base64Image = await getBase64Image(imageId, 'product_images');

        // Convert base64 to File
        File imageFile = await base64ToFile(base64Image, '$imageId.jpg');
        imageFiles.add(imageFile);
      }

      return imageFiles;
    } catch (e) {
      print('Error loading product images: ${e.toString()}');
      // Return empty list if error occurs
      return [];
    }
  }
}
