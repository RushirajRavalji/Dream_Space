import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../models/category_model.dart';

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({super.key});

  @override
  _ManageCategoriesPageState createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _itemCountController = TextEditingController();
  Color _selectedColor = const Color(0xFF4D6BB3); // Default color

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _itemCountController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final category = {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'itemCount':
              _itemCountController.text.isEmpty
                  ? '0 items'
                  : '${_itemCountController.text} items',
          'color': '0x${_selectedColor.value.toRadixString(16).toUpperCase()}',
          'imageUrl': 'assets/category_placeholder.png', // Default image
        };

        await FirebaseFirestore.instance.collection('categories').add(category);

        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added successfully')),
        );

        _resetForm();
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorDialog('Error adding category: ${e.toString()}');
      }
    }
  }

  Future<void> _deleteCategory(String categoryId) async {
    try {
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(categoryId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category deleted successfully')),
      );
    } catch (e) {
      _showErrorDialog('Error deleting category: ${e.toString()}');
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _nameController.clear();
      _descriptionController.clear();
      _itemCountController.clear();
      _selectedColor = const Color(0xFF4D6BB3);
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Manage Categories'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Add Category Form
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Add New Category',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Category Name',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter category name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'Description (Optional)',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _itemCountController,
                                decoration: const InputDecoration(
                                  labelText: 'Item Count (Optional)',
                                  border: OutlineInputBorder(),
                                  hintText: 'e.g. 24',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    if (int.tryParse(value) == null) {
                                      return 'Please enter a valid number';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              const Text('Category Color:'),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildColorOption(
                                      const Color(0xFF4D6BB3),
                                    ), // Blue
                                    _buildColorOption(
                                      const Color(0xFFD8A17E),
                                    ), // Orange
                                    _buildColorOption(
                                      const Color(0xFFE8D4C3),
                                    ), // Beige
                                    _buildColorOption(
                                      const Color(0xFF2D3142),
                                    ), // Dark Blue
                                    _buildColorOption(
                                      const Color(0xFF9CA0AB),
                                    ), // Gray
                                    _buildColorOption(
                                      const Color(0xFF4CAF50),
                                    ), // Green
                                    _buildColorOption(
                                      const Color(0xFFF44336),
                                    ), // Red
                                    _buildColorOption(
                                      const Color(0xFF9C27B0),
                                    ), // Purple
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _addCategory,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('ADD CATEGORY'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Existing Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category List
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('categories')
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text('No categories found'),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          return ListView.builder(
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final doc = snapshot.data!.docs[index];
                              final data = doc.data() as Map<String, dynamic>;

                              // Parse color from string
                              Color categoryColor = AppTheme.primaryColor;
                              if (data['color'] != null) {
                                try {
                                  categoryColor = Color(
                                    int.parse(
                                      data['color'].toString().replaceFirst(
                                        '0x',
                                        '',
                                      ),
                                      radix: 16,
                                    ),
                                  );
                                } catch (e) {
                                  // Use default color on error
                                }
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: categoryColor,
                                    child: const Icon(
                                      Icons.category,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(data['name'] ?? 'Unnamed'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (data['description'] != null &&
                                          data['description'].isNotEmpty)
                                        Text(data['description']),
                                      Text(data['itemCount'] ?? '0 items'),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (ctx) => AlertDialog(
                                              title: const Text(
                                                'Delete Category',
                                              ),
                                              content: const Text(
                                                'Are you sure you want to delete this category? This may affect products in this category.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () =>
                                                          Navigator.of(
                                                            ctx,
                                                          ).pop(),
                                                  child: const Text('CANCEL'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(ctx).pop();
                                                    _deleteCategory(doc.id);
                                                  },
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                  ),
                                                  child: const Text('DELETE'),
                                                ),
                                              ],
                                            ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildColorOption(Color color) {
    final isSelected = _selectedColor.value == color.value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : const SizedBox(width: 20, height: 20),
        ),
      ),
    );
  }
}
