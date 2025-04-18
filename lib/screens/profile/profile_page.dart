import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:new_furniture_app_fixed/providers/auth_provider.dart';
import 'package:new_furniture_app_fixed/models/user_model.dart';
import 'package:new_furniture_app_fixed/screens/auth/login_screen.dart';
import 'package:new_furniture_app_fixed/utils/app_theme.dart';
import 'package:new_furniture_app_fixed/utils/ui_components.dart';
import '../admin/admin_dashboard.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.userData != null) {
      _nameController.text = authProvider.userData!.fullName;
      _emailController.text = authProvider.userData!.email;
      _phoneController.text = authProvider.userData!.phone ?? '';
      _addressController.text = authProvider.userData!.address ?? '';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
    });
  }

  void _initializeControllers() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userData != null) {
      final user = authProvider.userData!;
      _nameController.text = user.fullName;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      _addressController.text = user.address ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.userData == null) return;

    try {
      await authProvider.updateProfile(
        fullName: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profile updated successfully')));

      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
      );
    }
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final File imageFile = File(image.path);
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      try {
        await authProvider.updateProfile(profileImageUrl: base64Image);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!authProvider.isAuthenticated) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
              title: Text('Profile', style: AppTheme.headingSmall),
              backgroundColor: AppTheme.surfaceColor,
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 100,
                    color: AppTheme.textLightColor,
                  ),
                  SizedBox(height: AppTheme.spacing_l),
                  Text(
                    'Please login to view your profile',
                    style: AppTheme.headingSmall,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppTheme.spacing_m),
                  Text(
                    'Create an account or log in to manage your profile, track orders, and more.',
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppTheme.spacing_xl),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 48),
                    ),
                    child: const Text('Login'),
                  ),
                ],
              ),
            ),
          );
        }

        final UserModel user = authProvider.userData!;

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: Text('Profile', style: AppTheme.headingSmall),
            backgroundColor: AppTheme.surfaceColor,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  _isEditing ? Icons.close : Icons.edit,
                  color: AppTheme.textPrimaryColor,
                ),
                onPressed: () {
                  setState(() {
                    if (_isEditing) {
                      // Cancel editing - restore original values
                      _initializeControllers();
                    }
                    _isEditing = !_isEditing;
                  });
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacing_l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile picture
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.accentColor,
                          child:
                              user.profileImageUrl != null
                                  ? ClipOval(
                                    child: Image.memory(
                                      base64Decode(user.profileImageUrl!),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                        ),
                        if (_isEditing)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor,
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  // Implement image picker
                                  _pickImage();
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing_l),

                  // Name field
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    enabled: _isEditing,
                  ),
                  SizedBox(height: AppTheme.spacing_m),

                  // Email field (disabled, cannot change email after registration)
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    enabled: false,
                  ),
                  SizedBox(height: AppTheme.spacing_m),

                  // Phone field
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: AppTheme.spacing_m),

                  // Address field
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    enabled: _isEditing,
                    maxLines: 3,
                  ),
                  SizedBox(height: AppTheme.spacing_xl),

                  // Support
                  Text('Support', style: AppTheme.labelLarge),
                  SizedBox(height: AppTheme.spacing_m),

                  _buildSettingItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    onTap: () {},
                  ),

                  _buildSettingItem(
                    context,
                    icon: Icons.info_outline,
                    title: 'About Us',
                    onTap: () {},
                  ),

                  // Admin Dashboard (only for admin users)
                  // Recognized admin emails: admin@example.com and driger.ray.dranzer@gmail.com
                  if (user.email == 'admin@example.com' || user.email == 'driger.ray.dranzer@gmail.com') ...[
                    SizedBox(height: AppTheme.spacing_xl),
                    Text('Admin Tools', style: AppTheme.labelLarge),
                    SizedBox(height: AppTheme.spacing_m),
                    _buildSettingItem(
                      context,
                      icon: Icons.admin_panel_settings,
                      title: 'Admin Dashboard',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminDashboard(),
                          ),
                        );
                      },
                    ),
                  ],

                  SizedBox(height: AppTheme.spacing_xl),

                  // Save button (only visible in edit mode)
                  if (_isEditing)
                    ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Save Changes'),
                    ),

                  // Logout button
                  SizedBox(height: AppTheme.spacing_m),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
