import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/ui_components.dart';
import '../category/category_page.dart';
import '../product/product_detail_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            if (productProvider.isLoading) {
              return const LoadingIndicator();
            }

            final categories = productProvider.categories;

            // Get featured products (first 5 products from all categories)
            List<ProductModel> featuredProducts = [];
            for (var category in categories) {
              final products =
                  productProvider.categoryProducts[category.name] ?? [];
              if (products.isNotEmpty) {
                featuredProducts.addAll(products.take(2));
                if (featuredProducts.length >= 6) break;
              }
            }

            return CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  floating: true,
                  pinned: false,
                  backgroundColor: AppTheme.backgroundColor,
                  title: Text('Furniture Shop', style: AppTheme.headingMedium),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.shopping_cart_outlined),
                      onPressed: () {
                        // Navigate to cart
                      },
                    ),
                  ],
                ),

                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing_l,
                      vertical: AppTheme.spacing_m,
                    ),
                    child: CustomSearchBar(
                      controller: _searchController,
                      hintText: 'Search for furniture...',
                      onChanged: (value) {
                        // Implement search
                      },
                    ),
                  ),
                ),

                // Welcome Message
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing_l,
                      vertical: AppTheme.spacing_m,
                    ),
                    child: Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        final greeting =
                            authProvider.isAuthenticated
                                ? 'Welcome back, ${authProvider.userData?.fullName.split(' ').first ?? 'User'}!'
                                : 'Discover your dream furniture';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(greeting, style: AppTheme.headingMedium),
                            SizedBox(height: AppTheme.spacing_xs),
                            Text(
                              'Find the perfect pieces for your home',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // Featured Products
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Featured Products',
                    actionText: 'See All',
                    onActionTap: () {
                      // Navigate to all products
                    },
                  ),
                ),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 280,
                    child:
                        featuredProducts.isEmpty
                            ? Center(
                              child: Text(
                                'No featured products found',
                                style: AppTheme.bodyMedium,
                              ),
                            )
                            : ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.spacing_m,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: featuredProducts.length,
                              itemBuilder: (context, index) {
                                final product = featuredProducts[index];
                                return Container(
                                  width: 200,
                                  margin: EdgeInsets.only(
                                    right: AppTheme.spacing_m,
                                  ),
                                  child: ProductCard(
                                    id: product.id,
                                    name: product.name,
                                    imageUrl: product.imageUrls.first,
                                    price: product.price,
                                    rating: product.rating,
                                    isFavorite:
                                        false, // Need to implement check
                                    onFavoriteToggle: () async {
                                      final authProvider =
                                          Provider.of<AuthProvider>(
                                            context,
                                            listen: false,
                                          );

                                      if (!authProvider.isAuthenticated) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Please login to add items to wishlist',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      // Toggle wishlist
                                      await productProvider.addToWishlist(
                                        product.id,
                                      );
                                    },
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => ProductDetailPage(
                                                productId: product.id,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                  ),
                ),

                // Categories
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Categories',
                    actionText: 'See All',
                    onActionTap: () {
                      // Navigate to all categories
                    },
                  ),
                ),

                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing_m),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppTheme.spacing_m,
                      crossAxisSpacing: AppTheme.spacing_m,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate((
                      BuildContext context,
                      int index,
                    ) {
                      if (index >= categories.length) return null;

                      final category = categories[index];
                      return CategoryCard(
                        name: category.name,
                        imageUrl: category.imageUrl,
                        color: category.color,
                        itemCount: category.itemCount,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => CategoryPage(category: category),
                            ),
                          );
                        },
                      );
                    }, childCount: categories.length),
                  ),
                ),

                // Bottom Padding
                SliverToBoxAdapter(
                  child: SizedBox(height: AppTheme.spacing_xl),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
