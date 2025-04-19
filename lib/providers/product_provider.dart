import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/product_firebase_service.dart';
import 'package:image_picker/image_picker.dart';

class ProductProvider with ChangeNotifier {
  // Service
  final ProductFirebaseService _productService = ProductFirebaseService();

  // State
  List<ProductModel> _allProducts = [];
  List<ProductModel> _featuredProducts = [];
  Map<String, List<ProductModel>> _categoryProducts = {};
  List<CategoryModel> _categories = [];
  List<ProductModel> _wishlistProducts = [];
  ProductModel? _selectedProduct;

  // Loading and error states
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ProductModel> get allProducts => _allProducts;
  List<ProductModel> get featuredProducts => _featuredProducts;
  Map<String, List<ProductModel>> get categoryProducts => _categoryProducts;
  List<CategoryModel> get categories => _categories;
  List<ProductModel> get wishlistProducts => _wishlistProducts;
  ProductModel? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize
  Future<void> initialize() async {
    try {
      print("ProductProvider: Starting initialization");
      await loadAllProducts();
      print("ProductProvider: Loaded ${_allProducts.length} products");
      await loadFeaturedProducts();
      print(
        "ProductProvider: Loaded ${_featuredProducts.length} featured products",
      );
      await loadCategories();
      print("ProductProvider: Loaded ${_categories.length} categories");
      print("ProductProvider: Initialization complete");
    } catch (e) {
      print("ProductProvider: Error during initialization: $e");
      _setError(e.toString());
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Load all products
  Future<void> loadAllProducts() async {
    try {
      _setLoading(true);
      _allProducts = await _productService.getAllProducts();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Load featured products
  Future<void> loadFeaturedProducts() async {
    try {
      _setLoading(true);
      _featuredProducts = await _productService.getFeaturedProducts();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Load products by category
  Future<void> loadProductsByCategory(String category) async {
    try {
      _setLoading(true);

      if (!_categoryProducts.containsKey(category)) {
        final products = await _productService.getProductsByCategory(category);
        _categoryProducts[category] = products;
      }

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Load categories
  Future<void> loadCategories() async {
    // This would typically fetch from Firebase
    // Using hardcoded values for now - replace with actual service
    _categories = [
      CategoryModel(
        id: '1',
        name: 'Living Room',
        imageUrl: 'assets/6.jpg',
        itemCount: '24 items',
        color: Color(0xFFD8A17E),
        description: 'Beautiful furniture for your living room',
      ),
      CategoryModel(
        id: '2',
        name: 'Bedroom',
        imageUrl: 'assets/1.png',
        itemCount: '18 items',
        color: Color(0xFF555B6E),
        description: 'Comfortable furniture for your bedroom',
      ),
      CategoryModel(
        id: '3',
        name: 'Dining',
        imageUrl: 'assets/3.png',
        itemCount: '12 items',
        color: Color(0xFFE8D4C3),
        description: 'Elegant dining tables and chairs',
      ),
      CategoryModel(
        id: '4',
        name: 'Office',
        imageUrl: 'assets/4.png',
        itemCount: '15 items',
        color: Color(0xFF2D3142),
        description: 'Productive furniture for your workspace',
      ),
      CategoryModel(
        id: '5',
        name: 'Accent Chairs',
        imageUrl: 'assets/5.png',
        itemCount: '8 items',
        color: Color(0xFF9CA0AB),
        description: 'Stylish accent chairs to complement your space',
      ),
    ];
    notifyListeners();
  }

  // Get product by ID
  Future<void> getProductById(String productId) async {
    try {
      _setLoading(true);
      _selectedProduct = await _productService.getProductById(productId);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Add product
  Future<String> addProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required List<File> imageFiles,
    required Map<String, dynamic> specifications,
    Map<String, dynamic>? dimensions,
    List<String>? colors,
    List<String>? materials,
    String? brand,
    double? discountPrice,
    int? stockQuantity,
    bool isFeatured = false,
  }) async {
    try {
      _setLoading(true);

      // Upload images first
      final List<String> imageUrls = await _productService.uploadImages(
        imageFiles,
      );

      // Create product model
      final ProductModel product = ProductModel(
        id: '', // This will be set by the service
        name: name,
        description: description,
        price: price,
        category: category,
        imageUrls: imageUrls,
        isAvailable: true,
        rating: 0.0,
        reviewCount: 0,
        specifications: specifications,
        dimensions: dimensions,
        colors: colors,
        materials: materials,
        brand: brand,
        discountPrice: discountPrice,
        stockQuantity: stockQuantity,
        isFeatured: isFeatured,
        createdAt: DateTime.now(),
      );

      // Add product to Firestore
      final String productId = await _productService.addProduct(product);

      // Refresh product lists
      await _refreshAfterProductChange(category, isFeatured);

      _setLoading(false);
      return productId;
    } catch (e) {
      _setError(e.toString());
      throw Exception('Failed to add product: $e');
    }
  }

  // Update product
  Future<void> updateProduct({
    required String id,
    required String name,
    required String description,
    required double price,
    required String category,
    required List<String> currentImageUrls,
    List<File>? newImageFiles,
    required Map<String, dynamic> specifications,
    Map<String, dynamic>? dimensions,
    List<String>? colors,
    List<String>? materials,
    String? brand,
    double? discountPrice,
    int? stockQuantity,
    bool isFeatured = false,
  }) async {
    try {
      _setLoading(true);

      // Keep track of the original product to detect changes
      final ProductModel? originalProduct = await _productService
          .getProductById(id);
      final String originalCategory = originalProduct?.category ?? category;
      final bool wasFeatureChanged = originalProduct?.isFeatured != isFeatured;

      // Handle image uploads if there are new images
      List<String> imageUrls = List<String>.from(currentImageUrls);
      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        final List<String> newImageUrls = await _productService.uploadImages(
          newImageFiles,
        );
        imageUrls.addAll(newImageUrls);
      }

      // Create updated product
      final ProductModel updatedProduct = ProductModel(
        id: id,
        name: name,
        description: description,
        price: price,
        category: category,
        imageUrls: imageUrls,
        isAvailable: originalProduct?.isAvailable ?? true,
        rating: originalProduct?.rating ?? 0.0,
        reviewCount: originalProduct?.reviewCount ?? 0,
        specifications: specifications,
        dimensions: dimensions,
        colors: colors,
        materials: materials,
        brand: brand,
        discountPrice: discountPrice,
        stockQuantity: stockQuantity,
        isFeatured: isFeatured,
        createdAt: originalProduct?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Update in Firestore
      await _productService.updateProduct(updatedProduct);

      // Refresh product lists as needed
      final bool wasCategoryChanged = originalCategory != category;

      if (wasCategoryChanged) {
        // Clear category caches that need refreshing
        _categoryProducts.remove(originalCategory);
        _categoryProducts.remove(category);
      }

      await _refreshAfterProductChange(
        wasCategoryChanged ? originalCategory : category,
        wasCategoryChanged || wasFeatureChanged || isFeatured,
      );

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      _setLoading(true);

      // Get product first to know which lists to refresh
      final ProductModel? product = await _productService.getProductById(
        productId,
      );
      final String category = product?.category ?? '';
      final bool isFeatured = product?.isFeatured ?? false;

      // Delete from Firestore
      await _productService.deleteProduct(productId);

      // Refresh lists
      await _refreshAfterProductChange(category, isFeatured);

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      throw Exception('Failed to delete product: $e');
    }
  }

  // Helper to refresh product lists after a change
  Future<void> _refreshAfterProductChange(
    String category,
    bool refreshFeatured,
  ) async {
    // Clear caches
    if (category.isNotEmpty) {
      _categoryProducts.remove(category);
    }

    // Reload affected lists
    await loadAllProducts();
    if (refreshFeatured) {
      await loadFeaturedProducts();
    }
    if (category.isNotEmpty) {
      await loadProductsByCategory(category);
    }
  }

  // Image picker helpers
  Future<List<File>> pickImages({bool multiple = true}) async {
    try {
      final ImagePicker picker = ImagePicker();

      if (multiple) {
        final List<XFile> pickedFiles = await picker.pickMultiImage();
        return pickedFiles.map((xFile) => File(xFile.path)).toList();
      } else {
        final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
        );
        return pickedFile != null ? [File(pickedFile.path)] : [];
      }
    } catch (e) {
      _setError('Error picking images: $e');
      return [];
    }
  }

  Future<File?> pickCameraImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.camera,
      );
      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      _setError('Error capturing image: $e');
      return null;
    }
  }

  // --- Wishlist functions ---

  // This is a placeholder for wishlist functionality
  // Implement based on your auth service/user data
  Future<void> toggleWishlist(String productId) async {
    // Implementation would depend on your auth/user system
    // This is just a placeholder
    debugPrint('Toggle wishlist for product: $productId');
  }

  // Wishlist functionality
  Future<bool> isInWishlist(String productId) async {
    try {
      // Check if product is in wishlist
      return _wishlistProducts.any((product) => product.id == productId);
    } catch (e) {
      _setError('Error checking wishlist: $e');
      return false;
    }
  }

  Future<void> addToWishlist(String productId) async {
    try {
      // If product is already in wishlist, do nothing
      if (await isInWishlist(productId)) {
        return;
      }

      // Get product details if not already loaded
      ProductModel? product;
      if (_allProducts.any((p) => p.id == productId)) {
        product = _allProducts.firstWhere((p) => p.id == productId);
      } else {
        product = await _productService.getProductById(productId);
      }

      // Add to wishlist if product is not null
      if (product != null) {
        _wishlistProducts.add(product);
        notifyListeners();
      }
    } catch (e) {
      _setError('Error adding to wishlist: $e');
    }
  }

  Future<void> removeFromWishlist(String productId) async {
    try {
      _wishlistProducts.removeWhere((product) => product.id == productId);
      notifyListeners();
    } catch (e) {
      _setError('Error removing from wishlist: $e');
    }
  }

  // Category functionality
  Future<void> fetchProductsByCategory(
    String category, {
    bool forceRefresh = false,
  }) async {
    try {
      _setLoading(true);

      if (!_categoryProducts.containsKey(category) || forceRefresh) {
        final products = await _productService.getProductsByCategory(category);
        _categoryProducts[category] = products;
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Error fetching products by category: $e');
    }
  }

  Future<void> diagnoseCategoryIssues() async {
    try {
      _setLoading(true);

      // This would typically check for category data issues in the database
      // For now, just simulate the diagnostic process
      print('Diagnosing category issues...');
      await Future.delayed(const Duration(seconds: 1));

      _setLoading(false);
    } catch (e) {
      _setError('Error diagnosing category issues: $e');
    }
  }

  Future<void> fetchCategories() async {
    try {
      _setLoading(true);

      // In a real app, we would fetch categories from the database
      // For now, just use the hardcoded categories
      await loadCategories();

      _setLoading(false);
    } catch (e) {
      _setError('Error fetching categories: $e');
    }
  }

  Future<void> fetchFeaturedProducts() async {
    try {
      _setLoading(true);
      await loadFeaturedProducts();
      _setLoading(false);
    } catch (e) {
      _setError('Error fetching featured products: $e');
    }
  }

  // Admin functionality
  Future<void> refreshProductsAfterAdd(String category, bool isFeatured) async {
    try {
      // Refresh the appropriate category
      await fetchProductsByCategory(category, forceRefresh: true);

      // If product is featured, refresh featured products
      if (isFeatured) {
        await loadFeaturedProducts();
      }

      // Refresh all products
      await loadAllProducts();
    } catch (e) {
      _setError('Error refreshing products: $e');
    }
  }

  Future<void> checkProductImages() async {
    try {
      _setLoading(true);

      // Simulate checking product images
      print('Checking product images...');
      await Future.delayed(const Duration(seconds: 2));

      _setLoading(false);
    } catch (e) {
      _setError('Error checking product images: $e');
    }
  }

  Future<void> fixProductImages() async {
    try {
      _setLoading(true);

      // Simulate fixing product images
      print('Fixing product images...');
      await Future.delayed(const Duration(seconds: 3));

      _setLoading(false);
    } catch (e) {
      _setError('Error fixing product images: $e');
    }
  }

  Future<void> fixCategoryImages() async {
    try {
      _setLoading(true);

      // Simulate fixing category images
      print('Fixing category images...');
      await Future.delayed(const Duration(seconds: 2));

      _setLoading(false);
    } catch (e) {
      _setError('Error fixing category images: $e');
    }
  }

  Future<void> updateCategoriesToUseAssets() async {
    try {
      _setLoading(true);

      // Simulate updating categories to use assets
      print('Updating categories to use assets...');
      await Future.delayed(const Duration(seconds: 2));

      // Refresh categories
      await loadCategories();

      _setLoading(false);
    } catch (e) {
      _setError('Error updating categories: $e');
    }
  }

  Future<void> initializeData() async {
    return initialize();
  }
}
