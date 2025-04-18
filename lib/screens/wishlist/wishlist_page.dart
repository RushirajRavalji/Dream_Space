import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/ui_components.dart';
import '../product/product_detail_page.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text('My Wishlist', style: AppTheme.headingMedium),
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 80,
                color: AppTheme.textSecondaryColor,
              ),
              SizedBox(height: AppTheme.spacing_m),
              Text(
                'Please sign in to view your wishlist',
                style: AppTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppTheme.spacing_l),
              PremiumButton(
                text: 'Sign In',
                onPressed: () {
                  // Navigate to login page
                },
                width: 200,
                isFullWidth: false,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('My Wishlist', style: AppTheme.headingMedium),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return const LoadingIndicator();
          }

          final wishlistProducts = productProvider.wishlistProducts;

          if (wishlistProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: AppTheme.textSecondaryColor,
                  ),
                  SizedBox(height: AppTheme.spacing_m),
                  Text('Your wishlist is empty', style: AppTheme.bodyLarge),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppTheme.spacing_m),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              mainAxisSpacing: AppTheme.spacing_m,
              crossAxisSpacing: AppTheme.spacing_m,
            ),
            itemCount: wishlistProducts.length,
            itemBuilder: (context, index) {
              final product = wishlistProducts[index];
              return ProductCard(
                id: product.id,
                name: product.name,
                imageUrl: product.imageUrls.first,
                price: product.price,
                rating: product.rating,
                isFavorite: true,
                onFavoriteToggle: () async {
                  await productProvider.removeFromWishlist(product.id);
                },
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ProductDetailPage(productId: product.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
