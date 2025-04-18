import 'package:flutter/material.dart';
import 'app_theme.dart';

// Premium Button with gradient background
class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isOutlined;
  final IconData? icon;
  final bool isFullWidth;
  final double? width;
  final double height;

  const PremiumButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
    this.icon,
    this.isFullWidth = true,
    this.width,
    this.height = 54.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          SizedBox(width: AppTheme.spacing_s),
        ],
        Text(text),
      ],
    );

    if (isOutlined) {
      return SizedBox(
        width: isFullWidth ? double.infinity : width,
        height: height,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppTheme.primaryColor),
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
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius_m),
            ),
          ),
          child: buttonContent,
        ),
      );
    }
  }
}

// Premium Card for product items
class ProductCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            // Product image with favorite button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.borderRadius_m),
                    topRight: Radius.circular(AppTheme.borderRadius_m),
                  ),
                  child: Image.asset(
                    imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: AppTheme.spacing_s,
                  right: AppTheme.spacing_s,
                  child: GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Container(
                      padding: EdgeInsets.all(AppTheme.spacing_xs),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.shadowColor,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color:
                            isFavorite
                                ? Colors.red
                                : AppTheme.textSecondaryColor,
                        size: 20,
                      ),
                    ),
                  ),
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
                    name,
                    style: AppTheme.labelLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppTheme.spacing_s),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rs ${price.toStringAsFixed(2)}',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          SizedBox(width: 4),
                          Text(rating.toString(), style: AppTheme.bodySmall),
                        ],
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

// Category Item with premium look
class CategoryItem extends StatelessWidget {
  final String imagePath;
  final String name;
  final String itemCount;
  final Color color;
  final VoidCallback onTap;

  const CategoryItem({
    super.key,
    required this.imagePath,
    required this.name,
    required this.itemCount,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing_s),
        width: 120,
        child: Column(
          children: [
            // Category image container
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius_l),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(imagePath, height: 70, width: 70),
              ),
            ),
            const SizedBox(height: AppTheme.spacing_s),
            // Category name
            Text(
              name,
              style: AppTheme.labelLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            // Item count
            Text(
              itemCount,
              style: AppTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Premium search bar
class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String)? onChanged;
  final String hintText;
  final Function()? onTap;
  final bool readOnly;
  final VoidCallback? onClear;

  const CustomSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.hintText = 'Search...',
    this.onTap,
    this.readOnly = false,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius_m),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textLightColor,
          ),
          prefixIcon: Icon(Icons.search, color: AppTheme.textSecondaryColor),
          suffixIcon:
              controller.text.isNotEmpty
                  ? IconButton(
                    icon: Icon(Icons.clear, color: AppTheme.textSecondaryColor),
                    onPressed: () {
                      controller.clear();
                      if (onClear != null) {
                        onClear!();
                      }
                      if (onChanged != null) {
                        onChanged!('');
                      }
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 4),
        ),
      ),
    );
  }
}

// Premium SearchBar with simplified implementation
class PremiumSearchBar extends StatelessWidget {
  final String hintText;
  final Function(String)? onChanged;

  const PremiumSearchBar({
    super.key,
    required this.hintText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius_m),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textLightColor,
          ),
          prefixIcon: Icon(Icons.search, color: AppTheme.textSecondaryColor),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        ),
      ),
    );
  }
}

// Custom app bar with minimal design
class MinimalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const MinimalAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.surfaceColor,
      elevation: 0,
      centerTitle: true,
      leading:
          showBackButton
              ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              )
              : null,
      title: Text(title, style: AppTheme.headingSmall),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Badge for cart icon
class CartBadge extends StatelessWidget {
  final int count;
  final Widget child;

  const CartBadge({super.key, required this.count, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count.toString(),
                style: AppTheme.labelSmall.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final Color color;
  final String itemCount;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.color,
    required this.itemCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacing_m),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius_m),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(child: Image.asset(imageUrl, fit: BoxFit.contain)),
            ),
            SizedBox(height: AppTheme.spacing_s),
            Text(
              name,
              style: AppTheme.labelLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: AppTheme.spacing_xs),
            Text(
              itemCount,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing_l),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppTheme.textLightColor),
            SizedBox(height: AppTheme.spacing_l),
            Text(
              title,
              style: AppTheme.headingSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spacing_m),
            Text(
              message,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              SizedBox(height: AppTheme.spacing_xl),
              PremiumButton(
                text: buttonText!,
                onPressed: onButtonPressed!,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing_m,
        vertical: AppTheme.spacing_s,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTheme.headingSmall),
          if (actionText != null && onActionTap != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionText!,
                style: AppTheme.labelMedium.copyWith(
                  color: AppTheme.secondaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
