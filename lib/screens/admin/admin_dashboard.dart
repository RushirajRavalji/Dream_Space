import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/asset_uploader.dart';
import '../../providers/product_provider.dart';
import 'add_product_page.dart';
import 'manage_products_page.dart';
import 'manage_categories_page.dart';
import 'admin_orders_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final AssetUploader _assetUploader = AssetUploader();
  bool _assetsUploading = false;

  final List<Widget> _pages = [
    const AdminHome(),
    const AddProductPage(),
    const ManageProductsPage(),
    const ManageCategoriesPage(),
    const AdminOrdersPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Product Listings',
            onPressed: () => _refreshProductListings(context),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload, color: Colors.white),
            tooltip: 'Upload All Assets',
            onPressed:
                _assetsUploading ? null : () => _uploadAllAssets(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: AppTheme.primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Manage your furniture store',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.dashboard,
              title: 'Dashboard',
              index: 0,
            ),
            _buildDrawerItem(
              icon: Icons.add_circle_outline,
              title: 'Add New Product',
              index: 1,
            ),
            _buildDrawerItem(
              icon: Icons.inventory,
              title: 'Manage Products',
              index: 2,
            ),
            _buildDrawerItem(
              icon: Icons.category,
              title: 'Manage Categories',
              index: 3,
            ),
            _buildDrawerItem(
              icon: Icons.shopping_bag,
              title: 'Orders',
              index: 4,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Return to Store'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: _selectedIndex == index ? AppTheme.primaryColor : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _selectedIndex == index ? AppTheme.primaryColor : Colors.black,
          fontWeight:
              _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context);
      },
    );
  }

  Future<void> _uploadAllAssets(BuildContext context) async {
    setState(() => _assetsUploading = true);

    try {
      await _assetUploader.uploadAllAssets(context);
    } finally {
      setState(() => _assetsUploading = false);
    }
  }

  Future<void> _refreshProductListings(BuildContext context) async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing product listings...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // Refresh categories
      await productProvider.fetchCategories();

      // Refresh products for each category
      for (var category in productProvider.categories) {
        await productProvider.fetchProductsByCategory(category.name);
      }

      // Refresh featured products
      await productProvider.fetchFeaturedProducts();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product listings refreshed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing listings: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to Admin Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'Quick Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildStatCards(context),
          const SizedBox(height: 24),
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildStatCards(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          context,
          title: 'Products',
          value: '128',
          icon: Icons.inventory,
          color: Colors.blue,
        ),
        _buildStatCard(
          context,
          title: 'Categories',
          value: '12',
          icon: Icons.category,
          color: Colors.orange,
        ),
        _buildStatCard(
          context,
          title: 'Orders',
          value: '56',
          icon: Icons.shopping_bag,
          color: Colors.green,
        ),
        _buildStatCard(
          context,
          title: 'Customers',
          value: '248',
          icon: Icons.people,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildActionCard(
              context,
              title: 'Add Product',
              icon: Icons.add_circle_outline,
              color: AppTheme.primaryColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddProductPage(),
                  ),
                );
              },
            ),
            _buildActionCard(
              context,
              title: 'Manage Products',
              icon: Icons.edit,
              color: Colors.amber[700]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageProductsPage(),
                  ),
                );
              },
            ),
            _buildActionCard(
              context,
              title: 'View Orders',
              icon: Icons.shopping_cart,
              color: Colors.indigo,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminOrdersPage(),
                  ),
                );
              },
            ),
            _buildActionCard(
              context,
              title: 'Refresh Cache',
              icon: Icons.refresh,
              color: Colors.teal[600]!,
              onTap: () => _refreshCache(context),
            ),
          ],
        ),

        const SizedBox(height: 24),
        const Text(
          'Troubleshooting Tools',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildActionCard(
              context,
              title: 'Check Images',
              icon: Icons.find_in_page,
              color: Colors.blue[600]!,
              onTap: () => _diagnoseProblem(context),
            ),
            _buildActionCard(
              context,
              title: 'Fix Product Images',
              icon: Icons.healing,
              color: Colors.red[600]!,
              onTap: () => _fixImages(context),
            ),
            _buildActionCard(
              context,
              title: 'Fix Category Images',
              icon: Icons.category,
              color: Colors.green[600]!,
              onTap: () => _fixCategoryImages(context),
            ),
            _buildActionCard(
              context,
              title: 'Use Local Assets',
              icon: Icons.storage,
              color: Colors.purple[600]!,
              onTap: () => _updateCategoriesToUseAssets(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _diagnoseProblem(BuildContext context) async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Diagnosing Images'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Checking product images in database...'),
              ],
            ),
          ),
    );

    try {
      // Run the diagnostic
      await productProvider.checkProductImages();

      // Close the dialog
      Navigator.of(context).pop();

      // Show result dialog
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Diagnosis Complete'),
              content: const Text(
                'Image diagnostic complete. Check the console for detailed results.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      // Close the dialog
      Navigator.of(context).pop();

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during diagnosis: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fixImages(BuildContext context) async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    // Show confirmation dialog
    final shouldFix = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Fix Product Images'),
            content: const Text(
              'This will check all products for missing or invalid images and fix them with placeholders. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Fix Images'),
              ),
            ],
          ),
    );

    if (shouldFix != true) {
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Fixing Images'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Fixing product images in database...'),
              ],
            ),
          ),
    );

    try {
      // Run the fix
      await productProvider.fixProductImages();

      // Close the dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product images fixed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close the dialog
      Navigator.of(context).pop();

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fixing images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshCache(BuildContext context) async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing product listings...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // Refresh product data
      await productProvider.initializeData();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product listings refreshed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing listings: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fixCategoryImages(BuildContext context) async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    // Show confirmation dialog
    final shouldFix = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Fix Category Images'),
            content: const Text(
              'This will check all categories for missing or invalid images and fix them with appropriate images. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Fix Categories'),
              ),
            ],
          ),
    );

    if (shouldFix != true) {
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Fixing Categories'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Fixing category images in database...'),
              ],
            ),
          ),
    );

    try {
      // Run the fix
      await productProvider.fixCategoryImages();

      // Close the dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category images fixed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close the dialog
      Navigator.of(context).pop();

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fixing category images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateCategoriesToUseAssets(BuildContext context) async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    // Show confirmation dialog
    final shouldFix = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Update Category Images'),
            content: const Text(
              'This will update all categories to use local asset images instead of Firebase images. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Update Categories'),
              ),
            ],
          ),
    );

    if (shouldFix != true) {
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Updating Categories'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Updating categories to use local assets...'),
              ],
            ),
          ),
    );

    try {
      // Run the update
      await productProvider.updateCategoriesToUseAssets();

      // Close the dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Categories updated to use local assets successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close the dialog
      Navigator.of(context).pop();

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating categories: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
