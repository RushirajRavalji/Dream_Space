import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/ui_components.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _resetSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.resetPassword(
        _emailController.text.trim(),
      );

      if (success) {
        setState(() {
          _resetSent = true;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'An error occurred'),
            backgroundColor: Colors.red,
          ),
        );
        authProvider.clearError();
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
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing_l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text('Reset Password', style: AppTheme.headingLarge),
                SizedBox(height: AppTheme.spacing_s),
                Text(
                  'Enter your email to receive a password reset link',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),

                SizedBox(height: AppTheme.spacing_xl),

                if (_resetSent)
                  // Success message
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacing_l),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius_m,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 48,
                        ),
                        SizedBox(height: AppTheme.spacing_m),
                        Text(
                          'Reset Link Sent!',
                          style: AppTheme.headingSmall.copyWith(
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacing_s),
                        Text(
                          'Check your email for instructions to reset your password.',
                          style: AppTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppTheme.spacing_l),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(double.infinity, 48),
                          ),
                          child: Text('Back to Login'),
                        ),
                      ],
                    ),
                  )
                else
                  // Reset form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email field
                        Text('Email', style: AppTheme.labelLarge),
                        SizedBox(height: AppTheme.spacing_s),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: AppTheme.spacing_xl),

                        // Reset button
                        authProvider.isLoading
                            ? Center(child: CircularProgressIndicator())
                            : PremiumButton(
                              text: 'Send Reset Link',
                              onPressed: _resetPassword,
                            ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
