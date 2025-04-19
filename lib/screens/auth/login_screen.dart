import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_furniture_app_fixed/providers/auth_provider.dart';
import 'package:new_furniture_app_fixed/providers/product_provider.dart';
import 'package:new_furniture_app_fixed/providers/connectivity_provider.dart';
import 'package:new_furniture_app_fixed/utils/app_theme.dart';
import 'package:new_furniture_app_fixed/screens/auth/register_screen.dart';
import 'package:new_furniture_app_fixed/screens/auth/forgot_password_screen.dart';
import 'package:new_furniture_app_fixed/screens/home/main_app.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isNetworkError = false;

  @override
  void initState() {
    super.initState();

    // Check connectivity on startup
    checkConnectivity();

    // Check if user is already logged in
    _checkExistingSession();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Check network connectivity
  Future<void> checkConnectivity() async {
    try {
      final connectivityProvider = Provider.of<ConnectivityProvider>(
        context,
        listen: false,
      );
      final hasConnection = await connectivityProvider.checkConnectivity();

      setState(() {
        _isNetworkError = !hasConnection;
      });
    } catch (e) {
      // If we can't check connectivity, assume we're online
      setState(() {
        _isNetworkError = false;
      });
    }
  }

  // Check if user already has a valid session
  Future<void> _checkExistingSession() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // If user is already authenticated, navigate to main app
    if (authProvider.isAuthenticated) {
      // A small delay to allow UI to initialize
      await Future.delayed(Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainApp()),
      );
    }
  }

  void _signIn() async {
    // Validate form first
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Check connectivity first
    await checkConnectivity();
    if (_isNetworkError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No internet connection. Please check your network settings.',
          ),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              checkConnectivity().then((_) {
                if (!_isNetworkError) {
                  _signIn();
                }
              });
            },
          ),
        ),
      );
      return;
    }

    // Clear any previous error messages
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Set loading state
    setState(() {});

    try {
      // Special handling for admin account
      if (email == 'driger.ray.dranzer@gmail.com' && password == 'Admin@1234') {
        await _handleAdminLogin(authProvider, email, password);
        return;
      }

      // Regular user login
      final success = await authProvider.loginWithEmailAndPassword(
        email,
        password,
      );

      if (!mounted) return;

      if (success) {
        // Initialize product data if needed
        final productProvider = Provider.of<ProductProvider>(
          context,
          listen: false,
        );
        await productProvider.initialize();

        // Navigate to main app
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainApp()),
          (route) => false,
        );
      } else {
        // This should rarely happen as loginWithEmailAndPassword typically throws on failure
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login failed. Please check your credentials.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Check if it's a network error
      if (e.toString().contains('network')) {
        setState(() {
          _isNetworkError = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Network error. Please check your internet connection.',
            ),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                checkConnectivity().then((_) {
                  if (!_isNetworkError) {
                    _signIn();
                  }
                });
              },
            ),
          ),
        );
        return;
      }

      // Format Firebase error messages to be more user-friendly
      String errorMessage = _formatAuthError(e.toString());

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  // Handle admin login with special privileges
  Future<void> _handleAdminLogin(
    AuthProvider authProvider,
    String email,
    String password,
  ) async {
    try {
      // First try normal login
      bool loginSuccess = await authProvider.loginWithEmailAndPassword(
        email,
        password,
      );

      if (!mounted) return;

      if (loginSuccess) {
        // Admin login successful, navigate to main app
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainApp()),
          (route) => false,
        );
        return;
      }
    } catch (e) {
      // Login failed - could be because account doesn't exist
      // Proceed to try creating the account
    }

    try {
      // Try to register this admin account
      bool registerSuccess = await authProvider.registerWithEmailAndPassword(
        email,
        password,
        'Admin User',
      );

      if (!mounted) return;

      if (registerSuccess) {
        // Admin registration successful, navigate to main app
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainApp()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create admin account. Please try again.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Format Firebase error messages to be more user-friendly
      String errorMessage = _formatAuthError(e.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Admin account setup failed: $errorMessage')),
      );
    }
  }

  // Format Firebase auth errors to be more user-friendly
  String _formatAuthError(String errorMessage) {
    if (errorMessage.contains('user-not-found')) {
      return 'No account found with this email. Please register first.';
    } else if (errorMessage.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    } else if (errorMessage.contains('invalid-email')) {
      return 'The email address is not valid.';
    } else if (errorMessage.contains('user-disabled')) {
      return 'This account has been disabled. Please contact support.';
    } else if (errorMessage.contains('too-many-requests')) {
      return 'Too many failed login attempts. Please try again later.';
    } else if (errorMessage.contains('operation-not-allowed')) {
      return 'This login method is not enabled. Please contact support.';
    } else if (errorMessage.contains('email-already-in-use')) {
      return 'This email is already registered. Please login instead.';
    } else if (errorMessage.contains('weak-password')) {
      return 'Password is too weak. Please use a stronger password.';
    } else if (errorMessage.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection.';
    } else {
      return 'Login error: $errorMessage';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Network status indicator
            if (_isNetworkError)
              Container(
                width: double.infinity,
                color: Colors.red.shade100,
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No internet connection',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: checkConnectivity,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(50, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppTheme.spacing_l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: AppTheme.spacing_xl * 2),
                    Text(
                      'Welcome Back',
                      style: AppTheme.headingLarge,
                      textAlign: TextAlign.left,
                    ),
                    SizedBox(height: AppTheme.spacing_s),
                    Text(
                      'Sign in to continue',
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    SizedBox(height: AppTheme.spacing_xl * 2),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: AppTheme.spacing_m),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_passwordVisible,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _passwordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _passwordVisible = !_passwordVisible;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: AppTheme.spacing_s),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size(10, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text('Forgot Password?'),
                            ),
                          ),
                          SizedBox(height: AppTheme.spacing_l),
                          ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 50),
                            ),
                            child:
                                authProvider.isLoading
                                    ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text('Login'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppTheme.spacing_xl * 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: AppTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => RegisterScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size(10, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('Register'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
