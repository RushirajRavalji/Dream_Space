import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/main_app.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/connectivity_provider.dart';
import 'firebase_options.dart';
import 'utils/app_theme.dart';
import 'services/firebase_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize auth persistence first to ensure user session is maintained
    final firebaseService = FirebaseService();
    await firebaseService.initializeAuthPersistence();

    // Pre-load shared preferences for faster access
    await SharedPreferences.getInstance();
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
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Ensure we don't rebuild the entire app when loading
          if (authProvider.status == AuthStatus.uninitialized) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              home: Scaffold(
                backgroundColor: AppTheme.backgroundColor,
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            );
          }

          return MaterialApp(
            title: 'Elegance Furniture',
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
        print("Main: User authenticated, showing home screen");
        return const MainApp(); // Use MainApp instead of HomeScreen for authenticated users
      case AuthStatus.unauthenticated:
        print("Main: User not authenticated, showing login screen");
        return const LoginScreen();
      case AuthStatus.uninitialized:
        // Premium splash screen
        print("Main: Auth state initializing, showing splash screen");
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadius_l,
                    ),
                    boxShadow: AppTheme.shadowElevation2,
                  ),
                  padding: EdgeInsets.all(AppTheme.spacing_m),
                  child: Image.asset('assets/1.png', fit: BoxFit.contain),
                ),
                SizedBox(height: AppTheme.spacing_l),
                Text(
                  'Elegance Furniture',
                  style: AppTheme.headingLarge.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(height: AppTheme.spacing_s),
                Text(
                  'Premium Quality for Your Home',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                SizedBox(height: AppTheme.spacing_xl),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        );
      default:
        // For error or other states, redirect to login
        print("Main: Auth status is in error state, showing login screen");
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
