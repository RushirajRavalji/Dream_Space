import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../utils/app_theme.dart';
import '../product/product_detail_page.dart';
import '../../components/firebase_base64_image.dart';

class AllProductsPage extends StatefulWidget {
  final String title;

  const AllProductsPage({Key? key, required this.title}) : super(key: key);

  @override
  _AllProductsPageState createState() => _AllProductsPageState();
}

class _AllProductsPageState extends State<AllProductsPage> {
  String _sortBy = 'newest'; // newest, price_low, price_high, rating
  bool _isLoading = false;
  List<ProductModel> _allProducts = [];

  @override
  void initState() {
    super.initState();
    // Fetch all products
    _loadAllProducts();
  }

  // Load all products from all categories
  Future<void> _loadAllProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );

      // Wait for all categories to load if needed
      for (var category in productProvider.categories) {
        await productProvider.fetchProductsByCategory(category.name);
      }

      // Collect products from all categories
      List<ProductModel> products = [];
      productProvider.categoryProducts.forEach((_, categoryProducts) {
        products.addAll(categoryProducts);
      });

      // Remove duplicates (in case a product is in multiple categories)
      final Map<String, ProductModel> uniqueProducts = {};
      for (var product in products) {
        uniqueProducts[product.id] = product;
      }

      setState(() {
        _allProducts = uniqueProducts.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading all products: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading products: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Sort products based on the current sort option
  List<ProductModel> _getSortedProducts(List<ProductModel> products) {
    final sortedProducts = List<ProductModel>.from(products);
    switch (_sortBy) {
      case 'newest':
        sortedProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'price_low':
        sortedProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        sortedProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        sortedProducts.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
    return sortedProducts;
  }

  @override
  Widget build(BuildContext context) {
    final sortedProducts = _getSortedProducts(_allProducts);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.title, style: AppTheme.headingSmall),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.textPrimaryColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Refreshing products...'),
                  duration: Duration(seconds: 1),
                ),
              );
              _loadAllProducts();
            },
          ),
          // Filter button
          IconButton(
            icon: Icon(Icons.filter_list, color: AppTheme.textPrimaryColor),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with count
            Container(
              width: double.infinity,
              color: AppTheme.primaryColor.withOpacity(0.1),
              padding: const EdgeInsets.all(AppTheme.spacing_m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('All Products', style: AppTheme.headingMedium),
                  SizedBox(height: AppTheme.spacing_xs),
                  Text(
                    'Found ${_allProducts.length} products',
                    style: AppTheme.labelMedium.copyWith(
                      color:
                          _allProducts.isEmpty
                              ? AppTheme.errorColor
                              : AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // If loading, show progress indicator
            if (_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: AppTheme.spacing_m),
                      Text('Loading products...', style: AppTheme.bodyMedium),
                    ],
                  ),
                ),
              )
            // If no products found, show empty state
            else if (_allProducts.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: AppTheme.textSecondaryColor,
                      ),
                      SizedBox(height: AppTheme.spacing_m),
                      Text(
                        'No products found',
                        style: AppTheme.headingSmall,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppTheme.spacing_s),
                      Text(
                        'Try refreshing or check back later',
                        style: AppTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppTheme.spacing_l),
                      ElevatedButton.icon(
                        icon: Icon(Icons.refresh),
                        label: Text('Refresh'),
                        style: AppTheme.primaryButtonStyle,
                        onPressed: () => _loadAllProducts(),
                      ),
                    ],
                  ),
                ),
              )
            // If we have products, show them with sort options
            else
              Expanded(
                child: Column(
                  children: [
                    // Sort options
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing_m),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Sort by:', style: AppTheme.labelLarge),
                          DropdownButton<String>(
                            value: _sortBy,
                            underline: Container(
                              height: 1,
                              color: AppTheme.dividerColor,
                            ),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _sortBy = newValue;
                                });
                              }
                            },
                            items: [
                              DropdownMenuItem(
                                value: 'newest',
                                child: Text('Newest First'),
                              ),
                              DropdownMenuItem(
                                value: 'price_low',
                                child: Text('Price: Low to High'),
                              ),
                              DropdownMenuItem(
                                value: 'price_high',
                                child: Text('Price: High to Low'),
                              ),
                              DropdownMenuItem(
                                value: 'rating',
                                child: Text('Highest Rated'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Products grid
                    Expanded(child: _buildProductsGrid(sortedProducts)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid(List<ProductModel> products) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing_m),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: AppTheme.spacing_m,
          mainAxisSpacing: AppTheme.spacing_m,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(context, product);
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(productId: product.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius_m),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadius_m),
                topRight: Radius.circular(AppTheme.borderRadius_m),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child:
                    product.imageUrls.isNotEmpty
                        ? FirebaseBase64Image(
                          imageId: product.imageUrls.first,
                          fit: BoxFit.cover,
                          placeholder: Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: Container(
                            color: AppTheme.dividerColor,
                            child: Icon(
                              Icons.image_not_supported,
                              color: AppTheme.textLightColor,
                            ),
                          ),
                        )
                        : Container(
                          color: AppTheme.dividerColor,
                          child: Icon(
                            Icons.image_not_supported,
                            color: AppTheme.textLightColor,
                          ),
                        ),
              ),
            ),
            // Product details
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing_s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTheme.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppTheme.spacing_xs),
                  Text(
                    'Rs ${product.price.toStringAsFixed(2)}',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing_xs),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '${product.rating.toStringAsFixed(1)} (${product.reviewCount})',
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.borderRadius_l),
        ),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(AppTheme.spacing_l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Filter Options', style: AppTheme.headingSmall),
              SizedBox(height: AppTheme.spacing_m),
              Text('No filters available yet.', style: AppTheme.bodyMedium),
              SizedBox(height: AppTheme.spacing_l),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
                child: Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}
