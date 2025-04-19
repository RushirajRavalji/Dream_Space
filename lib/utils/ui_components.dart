import 'package:flutter/material.dart';
import 'app_theme.dart';
import '../components/firebase_base64_image.dart';

// Premium Button with gradient background
class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isOutlined;
  final IconData? icon;
  final bool isFullWidth;
  final double? width;
  final double height;
  final bool isLoading;

  const PremiumButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
    this.icon,
    this.isFullWidth = true,
    this.width,
    this.height = 54.0,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget buttonContent = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child:
          isLoading
              ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: isOutlined ? AppTheme.primaryColor : Colors.white,
                ),
              )
              : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    SizedBox(width: AppTheme.spacing_s),
                  ],
                  Text(
                    text,
                    style:
                        isOutlined
                            ? null
                            : TextStyle(
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w600,
                            ),
                  ),
                ],
              ),
    );

    if (isOutlined) {
      return SizedBox(
        width: isFullWidth ? double.infinity : width,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppTheme.primaryColor, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius_m),
            ),
          ),
          child: buttonContent,
        ),
      );
    } else {
      return SizedBox(
        width: isFullWidth ? double.infinity : width,
        height: height,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius_m),
            ),
            elevation: 0,
          ),
          child: buttonContent,
        ),
      );
    }
  }
}

// Premium Product Card with enhanced visual design
class ProductCard extends StatefulWidget {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final double rating;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final bool isFavorite;

  const ProductCard({
    super.key,
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.isFavorite,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius_l),
            boxShadow:
                _isPressed
                    ? AppTheme.shadowElevation1
                    : AppTheme.shadowElevation2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image with favorite button
              Stack(
                children: [
                  Hero(
                    tag: 'product_image_${widget.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppTheme.borderRadius_l),
                        topRight: Radius.circular(AppTheme.borderRadius_l),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1.2,
                        child: FirebaseBase64Image(
                          imageId: widget.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: _buildShimmerPlaceholder(),
                          errorWidget: _buildErrorPlaceholder(),
                        ),
                      ),
                    ),
                  ),
                  // Rating badge
                  Positioned(
                    top: AppTheme.spacing_s,
                    left: AppTheme.spacing_s,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing_s,
                        vertical: AppTheme.spacing_xxs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadius_m,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: AppTheme.secondaryColor,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            widget.rating.toStringAsFixed(1),
                            style: AppTheme.labelSmall.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Favorite button
                  Positioned(
                    top: AppTheme.spacing_s,
                    right: AppTheme.spacing_s,
                    child: _buildFavoriteButton(),
                  ),
                ],
              ),

              // Product details
              Padding(
                padding: EdgeInsets.all(AppTheme.spacing_m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: AppTheme.labelLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppTheme.spacing_xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rs ${widget.price.toStringAsFixed(2)}',
                          style: AppTheme.priceText,
                        ),
                        _buildAddToCartButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: Colors.grey[400],
              size: 32,
            ),
            SizedBox(height: AppTheme.spacing_xs),
            Text(
              'Image not available',
              style: AppTheme.bodySmall.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: widget.onFavoriteToggle,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.8, end: widget.isFavorite ? 1.0 : 0.8),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: Container(
          padding: EdgeInsets.all(AppTheme.spacing_xs),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            widget.isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: widget.isFavorite ? Colors.red : AppTheme.textSecondaryColor,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildAddToCartButton() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius_m),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.add_shopping_cart_rounded,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () {
          // Add to cart functionality
        },
      ),
    );
  }
}

// Category Card
class CategoryCard extends StatelessWidget {
  final String title;
  final String imageUrl; // This will now be an asset path or category name
  final VoidCallback onTap;
  final String? name;
  final Color? color;
  final String? itemCount;

  const CategoryCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.onTap,
    this.name,
    this.color,
    this.itemCount,
  });

  // Get local asset path based on category title
  String _getCategoryAssetPath(String categoryName) {
    // Map category names to asset paths
    final Map<String, String> categoryImages = {
      'Accent Chairs': 'assets/5.png',
      'Living Room': 'assets/6.jpg',
      'Dining': 'assets/3.png',
      'Office': 'assets/4.png',
      'Bedroom': 'assets/1.png',
    };

    // Return matching image or default
    return categoryImages[categoryName] ?? 'assets/1.png';
  }

  @override
  Widget build(BuildContext context) {
    // Determine the asset path to use
    final assetPath =
        imageUrl.startsWith('assets/')
            ? imageUrl // Use directly if it's already an asset path
            : _getCategoryAssetPath(
              title,
            ); // Otherwise use the category title to find the right asset

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: EdgeInsets.only(right: AppTheme.spacing_m),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius_l),
          boxShadow: AppTheme.shadowElevation1,
        ),
        child: Stack(
          children: [
            // Category image - using local asset
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius_l),
              child: Image.asset(
                assetPath,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if asset not found
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.category_outlined,
                      size: 40,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius_l),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  stops: [0.6, 1.0],
                ),
              ),
            ),
            // Category title
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacing_m),
                child: Text(
                  title,
                  style: AppTheme.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Premium Section Header
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onViewAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing_m,
        vertical: AppTheme.spacing_s,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(title, style: AppTheme.headingSmall),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing_s,
                      vertical: AppTheme.spacing_xxs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            SizedBox(height: AppTheme.spacing_xxs),
            Text(subtitle!, style: AppTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

// Loading Indicator
class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            strokeWidth: 3,
          ),
          if (message != null) ...[
            SizedBox(height: AppTheme.spacing_m),
            Text(
              message!,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// Custom TextField with floating label and animation
class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final bool readOnly;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onTap,
    this.readOnly = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isFocused ? Colors.white : AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius_m),
        border: Border.all(
          color: _isFocused ? AppTheme.primaryColor : Colors.transparent,
          width: 1.5,
        ),
        boxShadow:
            _isFocused
                ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
                : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        onTap: widget.onTap,
        readOnly: widget.readOnly,
        style: AppTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius_m),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius_m),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius_m),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius_m),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius_m),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing_m,
            vertical: AppTheme.spacing_m,
          ),
          labelStyle:
              _isFocused
                  ? AppTheme.labelMedium.copyWith(color: AppTheme.primaryColor)
                  : AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
          hintStyle: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textLightColor,
          ),
          errorStyle: AppTheme.bodySmall.copyWith(color: AppTheme.errorColor),
        ),
      ),
    );
  }
}

// Featured Product Banner for Home Screen
class FeaturedProductBanner extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl; // Kept for compatibility
  final VoidCallback onTap;

  const FeaturedProductBanner({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Reduce height to avoid overflow
        height: 150,
        margin: EdgeInsets.symmetric(horizontal: AppTheme.spacing_m),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius_l),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppTheme.primaryDarkColor, AppTheme.primaryColor],
          ),
          boxShadow: AppTheme.shadowElevation2,
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius_l),
                child: Opacity(
                  opacity: 0.1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: PatternPainter(),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Content - Text only, taking full width
            Padding(
              padding: EdgeInsets.all(AppTheme.spacing_m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'New Arrival',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.secondaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing_xxs),
                  Text(
                    title,
                    style: AppTheme.headingMedium.copyWith(
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppTheme.spacing_xxs),
                  Text(
                    description,
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppTheme.spacing_s),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All Products',
                        style: AppTheme.labelMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: AppTheme.spacing_xs),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 16,
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
}

// Pattern Painter for banner backgrounds
class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    // Draw diagonal pattern
    for (double i = -size.height; i < size.width + size.height; i += 20) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Rating Display
class RatingDisplay extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;

  const RatingDisplay({
    super.key,
    required this.rating,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starColor = color ?? AppTheme.secondaryColor;
        if (index < rating.floor()) {
          // Full star
          return Icon(Icons.star_rounded, color: starColor, size: size);
        } else if (index == rating.floor() && rating % 1 > 0) {
          // Half star
          return Icon(Icons.star_half_rounded, color: starColor, size: size);
        } else {
          // Empty star
          return Icon(Icons.star_border_rounded, color: starColor, size: size);
        }
      }),
    );
  }
}
