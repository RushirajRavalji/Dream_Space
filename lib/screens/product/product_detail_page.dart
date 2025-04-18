import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/ui_components.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    await productProvider.getProductById(widget.productId);
    _checkIfInWishlist();
  }

  Future<void> _checkIfInWishlist() async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final isInWishlist = await productProvider.isInWishlist(widget.productId);

    if (mounted) {
      setState(() {
        _isFavorite = isInWishlist;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to add items to your wishlist'),
          action: SnackBarAction(
            label: 'Login',
            onPressed: () {
              // Navigate to login page
              // This would be implemented in a real app
            },
          ),
        ),
      );
      return;
    }

    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (_isFavorite) {
      await productProvider.addToWishlist(widget.productId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Added to wishlist')));
    } else {
      await productProvider.removeFromWishlist(widget.productId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Removed from wishlist')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final product = productProvider.selectedProduct;

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body:
              productProvider.isLoading
                  ? Center(child: CircularProgressIndicator())
                  : product == null
                  ? Center(child: Text('Product not found'))
                  : _buildProductDetails(context, product),
        );
      },
    );
  }

  Widget _buildProductDetails(BuildContext context, ProductModel product) {
    return CustomScrollView(
      slivers: [
        // App bar with product image
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background:
                product.imageUrls.isNotEmpty
                    ? Image.asset(product.imageUrls.first, fit: BoxFit.cover)
                    : Container(
                      color: AppTheme.dividerColor,
                      child: Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: AppTheme.textLightColor,
                      ),
                    ),
          ),
          leading: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.9),
            radius: 18,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: AppTheme.textPrimaryColor,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          actions: [
            CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.9),
              radius: 18,
              child: IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : AppTheme.textPrimaryColor,
                  size: 20,
                ),
                onPressed: _toggleFavorite,
              ),
            ),
            SizedBox(width: AppTheme.spacing_m),
          ],
        ),

        // Product details
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing_l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name and price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(product.name, style: AppTheme.headingMedium),
                    ),
                    Text(
                      'Rs ${product.price.toStringAsFixed(2)}',
                      style: AppTheme.headingSmall.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppTheme.spacing_s),

                // Rating
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    SizedBox(width: 4),
                    Text(
                      '${product.rating.toStringAsFixed(1)} (${product.reviewCount} reviews)',
                      style: AppTheme.bodyMedium,
                    ),
                  ],
                ),

                SizedBox(height: AppTheme.spacing_m),

                // Divider
                Divider(),

                SizedBox(height: AppTheme.spacing_m),

                // Description
                Text('Description', style: AppTheme.labelLarge),
                SizedBox(height: AppTheme.spacing_s),
                Text(product.description, style: AppTheme.bodyMedium),

                SizedBox(height: AppTheme.spacing_l),

                // Specifications
                if (product.specifications != null) ...[
                  Text('Specifications', style: AppTheme.labelLarge),
                  SizedBox(height: AppTheme.spacing_s),
                  ...product.specifications!.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacing_s,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              '${entry.key}:',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${entry.value}',
                              style: AppTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: AppTheme.spacing_l),
                ],

                // Add to cart button
                PremiumButton(
                  text: 'Add to Cart',
                  onPressed: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Added to cart')));
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
