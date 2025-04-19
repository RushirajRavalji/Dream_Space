import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../utils/app_theme.dart';
import '../product/product_detail_page.dart';
import '../../services/firebase_service.dart';
import '../../components/firebase_base64_image.dart';

class CategoryPage extends StatefulWidget {
  final CategoryModel category;

  const CategoryPage({super.key, required this.category});

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  String _sortBy = 'newest'; // newest, price_low, price_high, rating
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Fetch products for this category
    _loadCategoryProducts();
  }

  // Load category products with loading state
  Future<void> _loadCategoryProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );

      // First, run diagnostics to identify any category issues
      await productProvider.diagnoseCategoryIssues();

      print(
        "CategoryPage: Loading products for category: '${widget.category.name}'",
      );

      // Fetch products for this specific category
      await productProvider.fetchProductsByCategory(widget.category.name);

      // If we found no products, try to troubleshoot
      if (productProvider.categoryProducts[widget.category.name]?.isEmpty ??
          true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No products found. Checking database...'),
            duration: Duration(seconds: 2),
          ),
        );

        // Try to fix any data issues in Firestore
        final firebaseService = FirebaseService();

        // Try to detect and fix category inconsistencies
        print("CategoryPage: Attempting to fix category data issues");
        int fixedCount = await firebaseService.fixCategoryInconsistencies(
          widget.category.name,
        );

        if (fixedCount > 0) {
          print(
            "CategoryPage: Fixed $fixedCount products with category issues",
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fixed $fixedCount products. Reloading...'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Refresh again after fixes
        await productProvider.fetchProductsByCategory(
          widget.category.name,
          forceRefresh: true,
        );
      }
    } catch (e) {
      print('Error loading category products: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Sort products based on the current sort option
  List<ProductModel> _getSortedProducts(List<ProductModel> products) {
    switch (_sortBy) {
      case 'newest':
        return products..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case 'price_low':
        return products..sort((a, b) => a.price.compareTo(b.price));
      case 'price_high':
        return products..sort((a, b) => b.price.compareTo(a.price));
      case 'rating':
        return products..sort((a, b) => b.rating.compareTo(a.rating));
      default:
        return products;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        // Get products for this category
        final products =
            productProvider.categoryProducts[widget.category.name] ?? [];
        final sortedProducts = _getSortedProducts(List.from(products));

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: Text(widget.category.name, style: AppTheme.headingSmall),
            backgroundColor: AppTheme.surfaceColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: AppTheme.textPrimaryColor,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Refresh button
              IconButton(
                icon: Icon(Icons.refresh, color: AppTheme.textPrimaryColor),
                onPressed: () {
                  // Show refresh message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Refreshing products...'),
                      duration: Duration(seconds: 1),
                    ),
                  );

                  // Reload products
                  _loadCategoryProducts();
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
                // Category description
                Container(
                  width: double.infinity,
                  color: widget.category.color.withOpacity(0.1),
                  padding: const EdgeInsets.all(AppTheme.spacing_l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.category.name, style: AppTheme.headingMedium),
                      SizedBox(height: AppTheme.spacing_xs),
                      Text(
                        widget.category.description,
                        style: AppTheme.bodyMedium,
                      ),
                      SizedBox(height: AppTheme.spacing_s),
                      Text(
                        "Found ${products.length} products",
                        style: AppTheme.labelMedium.copyWith(
                          color:
                              products.isEmpty
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
                          Text(
                            'Loading products...',
                            style: AppTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                // If no products found, show empty state
                else if (products.isEmpty)
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
                            'No products found in this category',
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
                            onPressed: () => _loadCategoryProducts(),
                          ),
                          SizedBox(height: AppTheme.spacing_m),
                          TextButton(
                            child: Text('Diagnose Category Issues'),
                            onPressed: () async {
                              final productProvider =
                                  Provider.of<ProductProvider>(
                                    context,
                                    listen: false,
                                  );
                              await productProvider.diagnoseCategoryIssues();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Check console logs for diagnostic info',
                                  ),
                                ),
                              );
                            },
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
                        Expanded(child: buildProductsGrid(sortedProducts)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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

  // Helper method to get appropriate asset image based on category
  String _getCategoryImage(String category) {
    // Map of category names to asset images
    final Map<String, String> categoryImages = {
      'Accent Chairs': 'assets/5.png',
      'Living Room': 'assets/6.jpg',
      'Dining': 'assets/3.png',
      'Office': 'assets/4.png',
      'Bedroom': 'assets/1.png',
    };

    // Return matching image or default
    return categoryImages[category] ?? 'assets/1.png';
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
              // Filter options would go here
              // This is a placeholder for future implementation
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

  void _showSortOptions(BuildContext context) {
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
              Text('Sort Options', style: AppTheme.headingSmall),
              SizedBox(height: AppTheme.spacing_m),
              // Sort options would go here
              // This is a placeholder for future implementation
              Text(
                'No sort options available yet.',
                style: AppTheme.bodyMedium,
              ),
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

  // Build products grid
  Widget buildProductsGrid(List<ProductModel> products) {
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
}
