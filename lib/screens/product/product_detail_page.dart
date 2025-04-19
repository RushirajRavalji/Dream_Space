import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/ui_components.dart';
import '../../components/firebase_base64_image.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  bool _isFavorite = false;
  int _currentImageIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius_m),
          ),
          action: SnackBarAction(
            label: 'Login',
            textColor: Colors.white,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added to wishlist'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius_m),
          ),
        ),
      );
    } else {
      await productProvider.removeFromWishlist(widget.productId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed from wishlist'),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius_m),
          ),
        ),
      );
    }
  }

  void _simulateAddToCart() {
    setState(() => _isAddingToCart = true);
    _animationController.forward();

    // Simulate API call
    Future.delayed(Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _isAddingToCart = false);
        _animationController.reverse();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added to cart successfully'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius_m),
            ),
          ),
        );
      }
    });
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
                  ? const LoadingIndicator(
                    message: 'Loading product details...',
                  )
                  : product == null
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: AppTheme.errorColor.withOpacity(0.5),
                        ),
                        SizedBox(height: AppTheme.spacing_m),
                        Text('Product not found', style: AppTheme.headingSmall),
                        SizedBox(height: AppTheme.spacing_s),
                        Text(
                          'The product you\'re looking for doesn\'t exist or has been removed.',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                  : _buildProductDetails(context, product),
          bottomNavigationBar:
              product == null || productProvider.isLoading
                  ? null
                  : _buildBottomBar(context, product),
        );
      },
    );
  }

  Widget _buildProductDetails(BuildContext context, ProductModel product) {
    return CustomScrollView(
      physics: BouncingScrollPhysics(),
      slivers: [
        // Image carousel
        SliverToBoxAdapter(
          child: Stack(
            children: [
              // Image carousel
              _buildImageCarousel(product),

              // Back button
              Positioned(
                top: MediaQuery.of(context).padding.top + AppTheme.spacing_m,
                left: AppTheme.spacing_m,
                child: _buildCircleButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ),

              // Favorite button
              Positioned(
                top: MediaQuery.of(context).padding.top + AppTheme.spacing_m,
                right: AppTheme.spacing_m,
                child: _buildCircleButton(
                  icon:
                      _isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                  color: _isFavorite ? Colors.red : null,
                  onTap: _toggleFavorite,
                ),
              ),
            ],
          ),
        ),

        // Product details
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadius_xl),
                topRight: Radius.circular(AppTheme.borderRadius_xl),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            padding: EdgeInsets.all(AppTheme.spacing_l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category and name
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing_s,
                        vertical: AppTheme.spacing_xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLightColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadius_s,
                        ),
                      ),
                      child: Text(
                        product.category,
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppTheme.spacing_s),

                // Product name
                Text(product.name, style: AppTheme.headingLarge),

                SizedBox(height: AppTheme.spacing_m),

                // Price and rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price
                    Text(
                      'Rs ${product.price.toStringAsFixed(2)}',
                      style: AppTheme.priceText,
                    ),

                    // Rating
                    Row(
                      children: [
                        RatingDisplay(rating: product.rating),
                        SizedBox(width: AppTheme.spacing_xs),
                        Text(
                          '(${product.reviewCount})',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textLightColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: AppTheme.spacing_xl),

                // Description title
                Text('Description', style: AppTheme.headingSmall),

                SizedBox(height: AppTheme.spacing_m),

                // Description
                Text(
                  product.description,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
                    height: 1.6,
                  ),
                ),

                SizedBox(height: AppTheme.spacing_xl),

                // Specifications
                Text('Specifications', style: AppTheme.headingSmall),

                SizedBox(height: AppTheme.spacing_m),

                // Specifications list
                _buildSpecificationsList(product),

                SizedBox(height: AppTheme.spacing_xl),

                // Related products (placeholder)
                if (product.isAvailable)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('You may also like', style: AppTheme.headingSmall),
                      SizedBox(height: AppTheme.spacing_m),
                      _buildRelatedProductsPlaceholder(),
                      SizedBox(height: AppTheme.spacing_l),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageCarousel(ProductModel product) {
    // Use placeholder if no images
    final List<String> imageUrls =
        product.imageUrls.isEmpty ? ['placeholder'] : product.imageUrls;

    return Column(
      children: [
        Container(
          height: 350,
          child: CarouselSlider(
            options: CarouselOptions(
              height: 350,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              enableInfiniteScroll: imageUrls.length > 1,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
            ),
            items:
                imageUrls.map((url) {
                  return Builder(
                    builder: (BuildContext context) {
                      if (url == 'placeholder') {
                        return Container(
                          width: double.infinity,
                          color: AppTheme.backgroundColor,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 64,
                              color: AppTheme.textLightColor,
                            ),
                          ),
                        );
                      }

                      return Hero(
                        tag: 'product_image_${product.id}',
                        child: FirebaseBase64Image(
                          imageId: url,
                          width: double.infinity,
                          height: 350,
                          fit: BoxFit.cover,
                          placeholder: Container(
                            color: AppTheme.backgroundColor,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          errorWidget: Container(
                            color: AppTheme.backgroundColor,
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 64,
                                color: AppTheme.textLightColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
          ),
        ),

        // Image indicators
        if (imageUrls.length > 1)
          Container(
            padding: EdgeInsets.symmetric(vertical: AppTheme.spacing_m),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  imageUrls.asMap().entries.map((entry) {
                    return Container(
                      width: _currentImageIndex == entry.key ? 16 : 8,
                      height: 8,
                      margin: EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadius_circle,
                        ),
                        color:
                            _currentImageIndex == entry.key
                                ? AppTheme.primaryColor
                                : AppTheme.dividerColor,
                      ),
                    );
                  }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    VoidCallback? onTap,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashColor: AppTheme.primaryLightColor.withOpacity(0.3),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacing_s),
              child: Icon(
                icon,
                size: 24,
                color: color ?? AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecificationsList(ProductModel product) {
    // Sample specifications with default values for properties that may not exist in the model
    final specs = [
      {
        'name': 'Dimensions',
        'value': '100cm x 80cm x 60cm',
      }, // Default dimensions
      {'name': 'Weight', 'value': '15 kg'}, // Default weight
      {'name': 'Material', 'value': 'Wood'}, // Default material
      {'name': 'Color', 'value': 'Natural'}, // Default color
      {
        'name': 'Stock',
        'value': product.isAvailable ? 'In Stock' : 'Out of Stock',
      },
    ];

    return Column(
      children:
          specs.map((spec) {
            return Padding(
              padding: EdgeInsets.only(bottom: AppTheme.spacing_s),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${spec['name']}: ',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      spec['value'] ?? 'N/A',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildRelatedProductsPlaceholder() {
    return Container(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 160,
            margin: EdgeInsets.only(right: AppTheme.spacing_m),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius_l),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.borderRadius_l),
                      topRight: Radius.circular(AppTheme.borderRadius_l),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: AppTheme.textLightColor,
                      size: 32,
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: EdgeInsets.all(AppTheme.spacing_s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 100,
                        color: AppTheme.dividerColor,
                      ),
                      SizedBox(height: AppTheme.spacing_xs),
                      Container(
                        height: 14,
                        width: 60,
                        color: AppTheme.dividerColor,
                      ),
                      SizedBox(height: AppTheme.spacing_s),
                      Container(
                        height: 20,
                        width: 80,
                        color: AppTheme.dividerColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ProductModel product) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacing_m),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Price
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Price',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textLightColor,
                      ),
                    ),
                    Text(
                      'Rs ${product.price.toStringAsFixed(2)}',
                      style: AppTheme.priceText,
                    ),
                  ],
                ),
              ),

              // Add to cart button
              Expanded(
                child: PremiumButton(
                  text: 'Add to Cart',
                  icon: Icons.shopping_cart_outlined,
                  onPressed: _simulateAddToCart,
                  isLoading: _isAddingToCart,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
