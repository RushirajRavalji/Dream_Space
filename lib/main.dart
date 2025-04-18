import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_app.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'firebase_options.dart';
import 'utils/app_theme.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    // Initialize auth persistence
    final firebaseService = FirebaseService();
    await firebaseService.initializeAuthPersistence();
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    // Continue with app even if Firebase fails - will show appropriate error screens
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: 'Furniture App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: _handleAuthState(authProvider),
          );
        },
      ),
    );
  }
  
  Widget _handleAuthState(AuthProvider authProvider) {
    // Show appropriate widget based on auth state
    switch (authProvider.status) {
      case AuthStatus.authenticated:
        return const MainApp();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.uninitialized:
        // While waiting for auth state to be determined, show a loading screen
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        );
      default:
        // For error or other states, redirect to login
        return const LoginScreen();
    }
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Furniture App',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/1.png',
              height: 200,
              width: 200,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.image_not_supported,
                  size: 200,
                  color: Colors.grey,
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome to Furniture App',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This is a placeholder for the furniture app.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
