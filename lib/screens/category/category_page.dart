import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../utils/app_theme.dart';
import '../product/product_detail_page.dart';

class CategoryPage extends StatefulWidget {
  final CategoryModel category;

  const CategoryPage({super.key, required this.category});

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  String _sortBy = 'newest'; // newest, price_low, price_high, rating

  @override
  void initState() {
    super.initState();
    // Fetch products for this category
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(
        context,
        listen: false,
      ).fetchProductsByCategory(widget.category.name);
    });
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
                        widget.category.itemCount,
                        style: AppTheme.labelMedium.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

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

                // Product grid
                productProvider.isLoading
                    ? Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                    : sortedProducts.isEmpty
                    ? Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: AppTheme.textLightColor,
                            ),
                            SizedBox(height: AppTheme.spacing_m),
                            Text(
                              'No products found',
                              style: AppTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    )
                    : Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing_m,
                        ),
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.7,
                                crossAxisSpacing: AppTheme.spacing_m,
                                mainAxisSpacing: AppTheme.spacing_m,
                              ),
                          itemCount: sortedProducts.length,
                          itemBuilder: (context, index) {
                            final product = sortedProducts[index];
                            return _buildProductCard(context, product);
                          },
                        ),
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
                        ? Image.asset(
                          product.imageUrls.first,
                          fit: BoxFit.cover,
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
}
