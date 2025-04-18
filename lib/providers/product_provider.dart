import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/firebase_service.dart';

class ProductProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<CategoryModel> _categories = [];
  List<ProductModel> _wishlistProducts = [];
  final Map<String, List<ProductModel>> _categoryProducts = {};
  ProductModel? _selectedProduct;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<CategoryModel> get categories => _categories;
  List<ProductModel> get wishlistProducts => _wishlistProducts;
  Map<String, List<ProductModel>> get categoryProducts => _categoryProducts;
  ProductModel? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize data
  Future<void> initializeData() async {
    await fetchCategories();
    await fetchWishlistProducts();

    // Load products for each category
    for (var category in _categories) {
      await fetchProductsByCategory(category.name);
    }

    // Create initial data if needed
    await _firebaseService.createInitialData();
  }

  // Fetch categories
  Future<void> fetchCategories() async {
    try {
      _setLoading(true);
      _categories = await _firebaseService.getAllCategories();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Fetch products by category
  Future<void> fetchProductsByCategory(String category) async {
    try {
      _setLoading(true);
      List<ProductModel> products =
          await _firebaseService.getProductsByCategory(category);
      _categoryProducts[category] = products;
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Fetch wishlist products
  Future<void> fetchWishlistProducts() async {
    try {
      _setLoading(true);
      final productDocs = await _firebaseService.getWishlistProducts();
      _wishlistProducts =
          productDocs.map((doc) => ProductModel.fromFirestore(doc)).toList();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Get product by id
  Future<void> getProductById(String productId) async {
    try {
      _setLoading(true);
      _selectedProduct = await _firebaseService.getProductById(productId);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Check if product is in wishlist
  Future<bool> isInWishlist(String productId) async {
    return await _firebaseService.isInWishlist(productId);
  }

  // Add to wishlist
  Future<void> addToWishlist(String productId) async {
    try {
      await _firebaseService.addToWishlist(productId);
      await fetchWishlistProducts();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Remove from wishlist
  Future<void> removeFromWishlist(String productId) async {
    try {
      await _firebaseService.removeFromWishlist(productId);
      await fetchWishlistProducts();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
