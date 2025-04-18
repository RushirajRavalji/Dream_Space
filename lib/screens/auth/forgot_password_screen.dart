import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_furniture_app_fixed/providers/auth_provider.dart';
import 'package:new_furniture_app_fixed/utils/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetEmail() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      try {
        await authProvider.resetPassword(_emailController.text.trim());
        if (mounted) {
          setState(() {
            _emailSent = true;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacing_l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Reset Password',
                style: AppTheme.headingLarge,
                textAlign: TextAlign.left,
              ),
              SizedBox(height: AppTheme.spacing_s),
              Text(
                _emailSent
                    ? 'Check your email for reset instructions'
                    : 'Enter your email address to receive a link to reset your password',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.left,
              ),
              SizedBox(height: AppTheme.spacing_xl),
              if (!_emailSent) ...[
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
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppTheme.spacing_l),
                      ElevatedButton(
                        onPressed:
                            authProvider.isLoading ? null : _sendResetEmail,
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
                                : Text('Send Reset Link'),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                SizedBox(height: AppTheme.spacing_m),
                Text(
                  'Email sent successfully!',
                  style: AppTheme.headingMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppTheme.spacing_l),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text('Back to Login'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
