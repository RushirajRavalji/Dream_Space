import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/ui_components.dart';
import '../category/category_page.dart';
import '../product/product_detail_page.dart';
import '../all_products/all_products_page.dart';
import '../product/product_list_screen.dart';
import '../product/product_detail_screen.dart';
import '../product/add_product_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    try {
      print("HomeScreen: Initializing product data");
      await productProvider.initialize();
      print(
        "HomeScreen: ${productProvider.allProducts.length} products loaded",
      );
      print(
        "HomeScreen: ${productProvider.featuredProducts.length} featured products loaded",
      );
    } catch (e) {
      print("HomeScreen: Error initializing data: $e");
    }
  }

  Future<void> _refreshData() async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    try {
      print("HomeScreen: Refreshing product data");
      await productProvider.initialize();
      print(
        "HomeScreen: ${productProvider.allProducts.length} products refreshed",
      );
      print(
        "HomeScreen: ${productProvider.featuredProducts.length} featured products refreshed",
      );
    } catch (e) {
      print("HomeScreen: Error refreshing data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get auth provider to check admin status
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isAdmin = authProvider.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elegance Furniture'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality would go here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // Cart functionality would go here
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Cart coming soon')));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Consumer2<ProductProvider, ConnectivityProvider>(
          builder: (context, productProvider, connectivityProvider, child) {
            final isLoading = productProvider.isLoading;
            final hasError = productProvider.errorMessage != null;
            final isConnected = connectivityProvider.hasConnection;

            if (!isConnected) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No internet connection',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await connectivityProvider.checkConnectivity();
                        if (connectivityProvider.hasConnection) {
                          _refreshData();
                        }
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${productProvider.errorMessage}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner
                  _buildBanner(),

                  // Categories
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  _buildCategoriesSection(productProvider.categories),

                  // Featured Products
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Featured Products',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // View all featured products
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('View all featured products'),
                              ),
                            );
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                  ),

                  _buildFeaturedProductsSection(
                    productProvider.featuredProducts,
                  ),

                  // Spacer at bottom
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
      // Only show add product button for admin users
      floatingActionButton:
          isAdmin
              ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddProductScreen(),
                    ),
                  ).then((_) => _refreshData());
                },
                backgroundColor: AppTheme.primaryColor,
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  Widget _buildBanner() {
    return Container(
      height: 180,
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.2,
              child: Image.asset('assets/1.png', height: 180),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Summer Sale',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Up to 50% off on select items',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    // Sale page navigation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sale page coming soon')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Shop Now'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(List<CategoryModel> categories) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryItem(category);
        },
      ),
    );
  }

  Widget _buildCategoryItem(CategoryModel category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductListScreen(category: category.name),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category image/icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  category.imageUrl,
                  width: 30,
                  height: 30,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          Icon(Icons.category, size: 30, color: category.color),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Category name
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedProductsSection(List<ProductModel> products) {
    if (products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No featured products available'),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildFeaturedProductItem(product);
        },
      ),
    );
  }

  Widget _buildFeaturedProductItem(ProductModel product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: FutureBuilder<dynamic>(
                  future: product.getFirstImage(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data == null) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    return Image.file(snapshot.data, fit: BoxFit.cover);
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Product name
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            // Product price
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
