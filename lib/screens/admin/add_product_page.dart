import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../utils/app_theme.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _brandController = TextEditingController();

  // Specifications controllers
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _depthController = TextEditingController();
  final _weightController = TextEditingController();
  final _materialController = TextEditingController();

  // Form values
  String? _selectedCategory;
  List<String> _imageUrls = [];
  List<File> _images = [];
  bool _isAvailable = true;
  bool _isFeatured = false;
  final List<String> _selectedColors = [];
  final List<String> _selectedMaterials = [];
  bool _isLoading = false;

  // Available options
  List<CategoryModel> _categories = [];
  final List<String> _availableColors = [
    'Black',
    'White',
    'Gray',
    'Brown',
    'Beige',
    'Navy',
    'Teal',
    'Green',
    'Blue',
    'Red',
    'Orange',
    'Yellow',
    'Purple',
    'Pink',
    'Natural',
  ];

  final List<String> _availableMaterials = [
    'Wood',
    'Oak',
    'Pine',
    'Walnut',
    'Maple',
    'Cherry',
    'Mahogany',
    'Metal',
    'Steel',
    'Aluminum',
    'Iron',
    'Glass',
    'Plastic',
    'Fabric',
    'Leather',
    'Velvet',
    'Linen',
    'Cotton',
    'Wool',
    'Silk',
    'Rattan',
    'Bamboo',
    'Marble',
    'Stone',
    'Composite',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _stockController.dispose();
    _brandController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _depthController.dispose();
    _weightController.dispose();
    _materialController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      setState(() => _isLoading = true);

      final snapshot =
          await FirebaseFirestore.instance.collection('categories').get();
      _categories =
          snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Error loading categories: ${e.toString()}');
    }
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> pickedFiles = await picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (var file in pickedFiles) {
            _images.add(File(file.path));
          }
        });
      }
    } catch (e) {
      _showErrorDialog('Error picking images: ${e.toString()}');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        setState(() {
          _images.add(File(photo.path));
        });
      }
    } catch (e) {
      _showErrorDialog('Error taking photo: ${e.toString()}');
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> uploadedUrls = [];

    try {
      for (int i = 0; i < _images.length; i++) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('product_images')
            .child('${DateTime.now().millisecondsSinceEpoch}_$i.jpg');

        await storageRef.putFile(_images[i]);
        final downloadUrl = await storageRef.getDownloadURL();
        uploadedUrls.add(downloadUrl);
      }
    } catch (e) {
      throw Exception('Failed to upload images: ${e.toString()}');
    }

    return uploadedUrls;
  }

  Future<void> _submitProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_images.isEmpty) {
        _showErrorDialog('Please add at least one product image');
        return;
      }

      if (_selectedCategory == null) {
        _showErrorDialog('Please select a category');
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Upload images
        final imageUrls = await _uploadImages();

        // Create specifications map
        final specifications = {
          'dimensions': {
            'width':
                _widthController.text.isEmpty
                    ? null
                    : double.parse(_widthController.text),
            'height':
                _heightController.text.isEmpty
                    ? null
                    : double.parse(_heightController.text),
            'depth':
                _depthController.text.isEmpty
                    ? null
                    : double.parse(_depthController.text),
          },
          'weight':
              _weightController.text.isEmpty
                  ? null
                  : double.parse(_weightController.text),
          'material': _materialController.text,
        };

        // Create product reference
        final productsRef = FirebaseFirestore.instance.collection('products');
        final newProductRef = productsRef.doc();

        // Create product model
        final product = ProductModel(
          id: newProductRef.id,
          name: _nameController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          category: _selectedCategory!,
          imageUrls: imageUrls,
          isAvailable: _isAvailable,
          rating: 0.0,
          reviewCount: 0,
          specifications: specifications,
          dimensions: {
            'width':
                _widthController.text.isEmpty
                    ? null
                    : double.parse(_widthController.text),
            'height':
                _heightController.text.isEmpty
                    ? null
                    : double.parse(_heightController.text),
            'depth':
                _depthController.text.isEmpty
                    ? null
                    : double.parse(_depthController.text),
          },
          colors: _selectedColors.isNotEmpty ? _selectedColors : null,
          materials: _selectedMaterials.isNotEmpty ? _selectedMaterials : null,
          brand: _brandController.text.isEmpty ? null : _brandController.text,
          discountPrice:
              _discountPriceController.text.isEmpty
                  ? null
                  : double.parse(_discountPriceController.text),
          stockQuantity:
              _stockController.text.isEmpty
                  ? null
                  : int.parse(_stockController.text),
          isFeatured: _isFeatured,
          createdAt: DateTime.now(),
        );

        // Save to Firestore
        await newProductRef.set(product.toMap());

        setState(() => _isLoading = false);

        // Show success and reset form
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully')),
        );
        _resetForm();
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorDialog('Failed to add product: ${e.toString()}');
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _discountPriceController.clear();
      _stockController.clear();
      _brandController.clear();
      _widthController.clear();
      _heightController.clear();
      _depthController.clear();
      _weightController.clear();
      _materialController.clear();
      _selectedCategory = null;
      _isAvailable = true;
      _isFeatured = false;
      _selectedColors.clear();
      _selectedMaterials.clear();
      _images.clear();
      _imageUrls.clear();
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
        title: const Text('Add New Product'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information Section
                      _buildSectionTitle('Basic Information'),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Product Name',
                        hint: 'Enter product name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter product name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Product Description',
                        hint: 'Enter detailed product description',
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter product description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField(
                        label: 'Category',
                        hint: 'Select product category',
                        value: _selectedCategory,
                        items:
                            _categories.map((category) {
                              return DropdownMenuItem(
                                value: category.name,
                                child: Text(category.name),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _brandController,
                        label: 'Brand (Optional)',
                        hint: 'Enter brand name',
                      ),

                      // Pricing Section
                      _buildSectionTitle('Pricing & Inventory'),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _priceController,
                              label: 'Price (\$)',
                              hint: 'Enter price',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter price';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _discountPriceController,
                              label: 'Sale Price (\$) (Optional)',
                              hint: 'Enter sale price',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  final price = double.parse(
                                    _priceController.text,
                                  );
                                  final discountPrice = double.parse(value);
                                  if (discountPrice >= price) {
                                    return 'Sale price must be less than regular price';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _stockController,
                        label: 'Stock Quantity (Optional)',
                        hint: 'Enter stock quantity',
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
                      Row(
                        children: [
                          Expanded(
                            child: SwitchListTile(
                              title: const Text('Available for Sale'),
                              value: _isAvailable,
                              onChanged: (value) {
                                setState(() {
                                  _isAvailable = value;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: SwitchListTile(
                              title: const Text('Featured Product'),
                              value: _isFeatured,
                              onChanged: (value) {
                                setState(() {
                                  _isFeatured = value;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),

                      // Product Specifications
                      _buildSectionTitle('Product Specifications'),
                      const Text(
                        'Dimensions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _widthController,
                              label: 'Width (cm)',
                              hint: 'Width',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (double.tryParse(value) == null) {
                                    return 'Enter valid number';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTextField(
                              controller: _heightController,
                              label: 'Height (cm)',
                              hint: 'Height',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (double.tryParse(value) == null) {
                                    return 'Enter valid number';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTextField(
                              controller: _depthController,
                              label: 'Depth (cm)',
                              hint: 'Depth',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (double.tryParse(value) == null) {
                                    return 'Enter valid number';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _weightController,
                        label: 'Weight (kg) (Optional)',
                        hint: 'Enter product weight',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _materialController,
                        label: 'Primary Material (Optional)',
                        hint: 'E.g., Oak, Steel, Fabric',
                      ),

                      // Colors and Materials
                      _buildSectionTitle('Colors & Materials'),
                      const Text(
                        'Available Colors',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children:
                            _availableColors.map((color) {
                              final isSelected = _selectedColors.contains(
                                color,
                              );
                              return FilterChip(
                                label: Text(color),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedColors.add(color);
                                    } else {
                                      _selectedColors.remove(color);
                                    }
                                  });
                                },
                                backgroundColor: Colors.grey[200],
                                selectedColor: AppTheme.primaryColor
                                    .withOpacity(0.2),
                                checkmarkColor: AppTheme.primaryColor,
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Available Materials',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children:
                            _availableMaterials.map((material) {
                              final isSelected = _selectedMaterials.contains(
                                material,
                              );
                              return FilterChip(
                                label: Text(material),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedMaterials.add(material);
                                    } else {
                                      _selectedMaterials.remove(material);
                                    }
                                  });
                                },
                                backgroundColor: Colors.grey[200],
                                selectedColor: AppTheme.primaryColor
                                    .withOpacity(0.2),
                                checkmarkColor: AppTheme.primaryColor,
                              );
                            }).toList(),
                      ),

                      // Product Images
                      _buildSectionTitle('Product Images'),
                      const Text(
                        'Add high-quality images of your product from different angles',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Add Images'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _takePhoto,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Take Photo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_images.isNotEmpty)
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _images.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 120,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _images[index],
                                        height: 120,
                                        width: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _images.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                      // Submit Button
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'ADD PRODUCT',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const Divider(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Text(hint),
              value: value,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
