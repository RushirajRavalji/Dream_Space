import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/image_utils.dart';
import '../../services/firebase_service.dart';
import '../../components/firebase_base64_image.dart';

class EditProductPage extends StatefulWidget {
  final ProductModel product;

  const EditProductPage({super.key, required this.product});

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _discountPriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _brandController;

  // Specifications controllers
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late final TextEditingController _depthController;
  late final TextEditingController _weightController;
  late final TextEditingController _materialController;

  // Form values
  String? _selectedCategory;
  List<String> _imageUrls = []; // These are now base64 image IDs in Firestore
  List<File> _newImages = [];
  bool _isAvailable = true;
  bool _isFeatured = false;
  List<String> _selectedColors = [];
  List<String> _selectedMaterials = [];
  bool _isLoading = false;
  bool _hasChangedImages = false;

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
    _initializeControllers();
    _populateFormFields();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _discountPriceController = TextEditingController();
    _stockController = TextEditingController();
    _brandController = TextEditingController();
    _widthController = TextEditingController();
    _heightController = TextEditingController();
    _depthController = TextEditingController();
    _weightController = TextEditingController();
    _materialController = TextEditingController();
  }

  void _populateFormFields() {
    final ProductModel product = widget.product;

    // Populate text controllers
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();
    _discountPriceController.text = product.discountPrice?.toString() ?? '';
    _stockController.text = product.stockQuantity?.toString() ?? '';
    _brandController.text = product.brand ?? '';

    // Dimensions
    if (product.dimensions != null) {
      _widthController.text = product.dimensions!['width']?.toString() ?? '';
      _heightController.text = product.dimensions!['height']?.toString() ?? '';
      _depthController.text = product.dimensions!['depth']?.toString() ?? '';
    }

    // Other specifications
    if (product.specifications != null &&
        product.specifications!['weight'] != null) {
      _weightController.text = product.specifications!['weight'].toString();
    }

    if (product.specifications != null &&
        product.specifications!['material'] != null) {
      _materialController.text = product.specifications!['material'].toString();
    }

    // Dropdown and toggle values
    _selectedCategory = product.category;
    _isAvailable = product.isAvailable;
    _isFeatured = product.isFeatured ?? false;

    // Multi-select values
    if (product.colors != null) {
      _selectedColors = List<String>.from(product.colors!);
    }

    if (product.materials != null) {
      _selectedMaterials = List<String>.from(product.materials!);
    }

    // Images
    if (product.imageUrls.isNotEmpty) {
      _imageUrls = List<String>.from(product.imageUrls);
    }
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
            _newImages.add(File(file.path));
          }
          _hasChangedImages = true;
        });

        // Show feedback to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${pickedFiles.length} images'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Error picking images: ${e.toString()}');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // Compress image to reduce file size
      );

      if (photo != null) {
        setState(() {
          _newImages.add(File(photo.path));
          _hasChangedImages = true;
        });

        // Show feedback to user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added photo from camera'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Error taking photo: ${e.toString()}');
    }
  }

  Future<List<String>> _uploadNewImages() async {
    List<String> imageIds = [];
    FirebaseService firebaseService = FirebaseService();

    try {
      for (int i = 0; i < _newImages.length; i++) {
        try {
          setState(() {
            _isLoading = true;
          });

          // Indicate which image is being processed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Processing image ${i + 1} of ${_newImages.length}...',
              ),
              duration: Duration(seconds: 1),
            ),
          );

          // Convert image to base64
          String base64Image = await ImageUtils.fileToBase64(_newImages[i]);

          // Upload base64 image to Firestore
          String imageId = await firebaseService.uploadBase64Image(
            base64Image,
            'product_images',
          );
          imageIds.add(imageId);
        } catch (imageError) {
          // Log the error but continue with other images
          print('Error processing image $i: $imageError');

          // Show a snackbar about the error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error with image ${i + 1}. Skipping...'),
              backgroundColor: Colors.orange,
            ),
          );

          // If we couldn't process any images, eventually throw an error
          if (i == _newImages.length - 1 && imageIds.isEmpty) {
            throw Exception(
              'Failed to process any images. Try with smaller images.',
            );
          }
        }
      }

      return imageIds;
    } catch (e) {
      throw Exception('Failed to upload images: ${e.toString()}');
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
      _hasChangedImages = true;
    });

    // Provide feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Existing image removed'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
      // We've changed images if we had new images at all
      _hasChangedImages = true;
    });

    // Provide feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New image removed'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_imageUrls.isEmpty && _newImages.isEmpty) {
        _showErrorDialog('Please add at least one product image');
        return;
      }

      if (_selectedCategory == null) {
        _showErrorDialog('Please select a category');
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Only upload new images if they exist and changes were made
        List<String> allImageUrls = List.from(_imageUrls);
        if (_newImages.isNotEmpty) {
          // Show general processing message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Processing images...'),
              duration: Duration(seconds: 2),
            ),
          );

          final newUploadedIds = await _uploadNewImages();
          allImageUrls.addAll(newUploadedIds);
        }

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
        final productRef = FirebaseFirestore.instance
            .collection('products')
            .doc(widget.product.id);

        // Create a direct map for updating to ensure all fields are set properly
        final Map<String, dynamic> productData = {
          'id': widget.product.id,
          'name': _nameController.text,
          'description': _descriptionController.text,
          'price': double.parse(_priceController.text),
          'category': _selectedCategory!,
          'imageUrls': allImageUrls,
          'isAvailable': _isAvailable,
          'rating': widget.product.rating,
          'reviewCount': widget.product.reviewCount,
          'specifications': specifications,
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
          'colors': _selectedColors.isNotEmpty ? _selectedColors : null,
          'materials':
              _selectedMaterials.isNotEmpty ? _selectedMaterials : null,
          'brand': _brandController.text.isEmpty ? null : _brandController.text,
          'discountPrice':
              _discountPriceController.text.isEmpty
                  ? null
                  : double.parse(_discountPriceController.text),
          'stockQuantity':
              _stockController.text.isEmpty
                  ? null
                  : int.parse(_stockController.text),
          'isFeatured': _isFeatured,
          'createdAt':
              widget.product.createdAt is Timestamp
                  ? widget.product.createdAt
                  : Timestamp.fromDate(widget.product.createdAt),
          'updatedAt': Timestamp.now(),
        };

        // Save directly to Firestore
        await productRef.update(productData);

        // Debug log
        print('Updated product with isFeatured: $_isFeatured');

        // Refresh products in the provider
        final productProvider = Provider.of<ProductProvider>(
          context,
          listen: false,
        );
        await productProvider.refreshProductsAfterAdd(
          _selectedCategory!,
          _isFeatured,
        );

        setState(() => _isLoading = false);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Product updated successfully and is now visible in the store!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Go back to previous screen
        Navigator.of(context).pop();
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorDialog('Failed to update product: ${e.toString()}');
      }
    }
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
        title: const Text('Edit Product'),
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
                        'Manage product images',
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

                      // No Images Message
                      if (_imageUrls.isEmpty && _newImages.isEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.yellow[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Please add at least one product image',
                                  style: TextStyle(color: Colors.amber),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Existing Images
                      if (_imageUrls.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Current Images',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _imageUrls.length,
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
                                      child: FirebaseBase64Image(
                                        imageId: _imageUrls[index],
                                        height: 120,
                                        width: 120,
                                        fit: BoxFit.cover,
                                        placeholder: Container(
                                          height: 120,
                                          width: 120,
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                        errorWidget: Container(
                                          height: 120,
                                          width: 120,
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.broken_image,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: GestureDetector(
                                      onTap: () => _removeExistingImage(index),
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
                      ],

                      // New Images
                      if (_newImages.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'New Images',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _newImages.length,
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
                                        _newImages[index],
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
                                      onTap: () => _removeNewImage(index),
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
                      ],

                      // Submit Button
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _updateProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'UPDATE PRODUCT',
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
