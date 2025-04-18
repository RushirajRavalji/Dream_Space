import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/ui_components.dart';
import 'category_page.dart';

class AllCategoriesPage extends StatelessWidget {
  const AllCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('All Categories', style: AppTheme.headingMedium),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return const LoadingIndicator();
          }

          final categories = productProvider.categories;

          if (categories.isEmpty) {
            return Center(
              child: Text('No categories found', style: AppTheme.bodyLarge),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppTheme.spacing_m),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppTheme.spacing_m,
              crossAxisSpacing: AppTheme.spacing_m,
              childAspectRatio: 0.85,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
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
                      builder: (context) => CategoryPage(category: category),
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
