import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  authenticating,
  unauthenticated,
  error,
}

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  AuthStatus _status = AuthStatus.uninitialized;
  User? _user;
  UserModel? _userData;
  String? _errorMessage;
  bool _isLoading = false;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription? _connectivitySubscription;
  bool _isOnline = true;
  DateTime? _lastOfflineTime;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  UserModel? get userData => _userData;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoggedIn => _userData != null;
  bool get isOnline => _isOnline;

  // Constructor
  AuthProvider() {
    // Initialize auth state as soon as provider is created
    _initializeAuthState();
    _setupConnectivityListener();
  }

  // Set up connectivity listener
  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Use the first result, or assume NONE if the list is empty
      final ConnectivityResult result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      
      final wasOffline = !_isOnline;
      final isNowOnline = result != ConnectivityResult.none;
      
      _isOnline = isNowOnline;
      
      if (wasOffline && isNowOnline) {
        // We're back online after being offline
        print('Connection restored. Refreshing auth state...');
        _refreshAfterReconnection();
      } else if (!isNowOnline) {
        // We just went offline
        _lastOfflineTime = DateTime.now();
        print('Connection lost at ${_lastOfflineTime}');
      }
    });
  }
  
  // Refresh data after reconnection
  Future<void> _refreshAfterReconnection() async {
    // Only refresh if we've been offline for a while
    final offlineDuration = _lastOfflineTime != null 
        ? DateTime.now().difference(_lastOfflineTime!) 
        : Duration.zero;
        
    if (offlineDuration.inSeconds < 5) {
      // If we were offline for less than 5 seconds, don't bother refreshing
      return;
    }
    
    // If user was authenticated, refresh their data
    if (_status == AuthStatus.authenticated && _user != null) {
      try {
        await _fetchUserData();
        notifyListeners();
      } catch (e) {
        print('Failed to refresh user data after reconnection: $e');
      }
    }
  }

  @override
  void dispose() {
    // Cancel auth state subscription to prevent memory leaks
    _authSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  // Initialize auth state
  Future<void> _initializeAuthState() async {
    try {
      // Set initial loading state
      _setLoading(true);
      
      // Try to initialize persistence first
      try {
        await _firebaseService.initializeAuthPersistence();
      } catch (e) {
        // Non-fatal, can continue
        print("Warning: Failed to set persistence: $e");
      }
      
      // Check for existing user immediately
      _user = _auth.currentUser;
      
      if (_user != null) {
        _status = AuthStatus.authenticated;
        
        // Fetch user data but don't block UI on it
        _fetchUserData().catchError((e) {
          print("Warning: Failed to fetch initial user data: $e");
          // Will be retried when needed
        });
      } else {
        _status = AuthStatus.unauthenticated;
      }
      
      // Notify UI of initial state
      _setLoading(false);
      notifyListeners();
      
      // Listen for auth state changes
      _authSubscription = _firebaseService.authStateChanges.listen(
        (User? user) async {
          // Only process if the auth state actually changed
          final bool userChanged = (user?.uid != _user?.uid) || 
                                   (user == null && _user != null) || 
                                   (user != null && _user == null);
          
          if (userChanged) {
            if (user == null) {
              // User logged out
              _user = null;
              _userData = null;
              _status = AuthStatus.unauthenticated;
            } else {
              // User logged in or changed
              _user = user;
              _status = AuthStatus.authenticated;
              
              // Fetch user data
              try {
                await _fetchUserData();
              } catch (e) {
                print("Warning: Auth state change - failed to fetch user data: $e");
                // Don't change auth status on data fetch failure
              }
            }
            
            // Notify UI of auth state change
            notifyListeners();
          }
        },
        onError: (error) {
          print("Error in auth state stream: $error");
          // Don't change auth state on stream error
        },
      );
    } catch (e) {
      _handleError(e, 'Error initializing authentication state');
      _status = AuthStatus.unauthenticated;
      _setLoading(false);
      notifyListeners();
    }
  }

  // Fetch user data
  Future<void> _fetchUserData() async {
    if (_user == null) return;
    
    try {
      _setLoading(true);
      _userData = await _firebaseService.getUserData();
      _setLoading(false);
    } catch (e) {
      _handleError(e, 'Error fetching user data');
    }
  }

  // Register with email and password
  Future<bool> registerWithEmailAndPassword(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      _setLoading(true);
      _clearError();
      _status = AuthStatus.authenticating;
      notifyListeners();

      await _firebaseService.registerWithEmailAndPassword(
        email,
        password,
        fullName,
      );
      
      // Auth state listener will automatically update the state
      _setLoading(false);
      return true;
    } catch (e) {
      _handleError(e, 'Registration failed');
      return false;
    }
  }

  // Login with email and password
  Future<bool> loginWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();
      _status = AuthStatus.authenticating;
      notifyListeners();

      UserModel userModel = await _firebaseService.loginWithEmailAndPassword(
        email,
        password,
      );

      // Update user data immediately for faster UI response
      _user = FirebaseAuth.instance.currentUser;
      _userData = userModel;
      _status = AuthStatus.authenticated;
      _setLoading(false);
      notifyListeners();
      
      return true;
    } catch (e) {
      _handleError(e, 'Login failed');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      _setLoading(true);
      _clearError();
      await _firebaseService.logout();
      // Auth state listener will handle the rest
      _setLoading(false);
    } catch (e) {
      _handleError(e, 'Logout failed');
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();
      await _firebaseService.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _handleError(e, 'Password reset failed');
      return false;
    }
  }
  
  // Format and handle errors
  void _handleError(dynamic error, String context) {
    String message = error.toString();
    
    // Format Firebase auth errors
    if (message.contains('firebase_auth')) {
      if (message.contains('user-not-found')) {
        message = 'No account found with this email';
      } else if (message.contains('wrong-password')) {
        message = 'Incorrect password';
      } else if (message.contains('invalid-email')) {
        message = 'Invalid email address';
      } else if (message.contains('email-already-in-use')) {
        message = 'This email is already registered';
      } else if (message.contains('weak-password')) {
        message = 'Password is too weak';
      } else if (message.contains('network-request-failed')) {
        message = 'Network error - check your connection';
      }
    }
    
    _setError('$context: $message');
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = AuthStatus.error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Update profile
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    String? profileImageUrl,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      if (_userData == null) {
        throw Exception('Cannot update profile: User data not available');
      }

      if (fullName != null && fullName.isNotEmpty) {
        await _firebaseService.updateDisplayName(fullName);
      }

      // Create updated user model
      UserModel updatedUser = _userData!.copyWith(
        fullName: fullName ?? _userData!.fullName,
        phone: phone ?? _userData!.phone,
        address: address ?? _userData!.address,
        profileImageUrl: profileImageUrl ?? _userData!.profileImageUrl,
      );

      // Update with retry
      int retryCount = 0;
      while (retryCount < 3) {
        try {
          await _firebaseService.updateUserData(updatedUser);
          break;
        } catch (e) {
          retryCount++;
          if (retryCount == 3) throw e;
          await Future.delayed(Duration(seconds: 1));
        }
      }
      
      // Refresh user data
      await _fetchUserData();
      _setLoading(false);
      return true;
    } catch (e) {
      _handleError(e, 'Profile update failed');
      return false;
    }
  }

  // Upload profile image
  Future<bool> uploadProfileImage(File imageFile) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Check if file exists and is readable
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }
      
      // Check file size (limit to 2MB)
      final fileSize = await imageFile.length();
      if (fileSize > 2 * 1024 * 1024) {
        throw Exception('Image file is too large (max 2MB)');
      }

      String base64Image = await _firebaseService.uploadProfileImage(imageFile);

      // Refresh user data
      await _fetchUserData();

      _setLoading(false);
      return true;
    } catch (e) {
      _handleError(e, 'Profile image upload failed');
      return false;
    }
  }

  // Add to wishlist
  Future<bool> addToWishlist(String productId) async {
    if (_userData == null) {
      _setError('Cannot add to wishlist: Not logged in');
      return false;
    }

    try {
      _clearError();
      
      // Check if already in wishlist
      if (_userData!.wishlist.contains(productId)) {
        return true; // Already in wishlist, consider this a success
      }
      
      List<String> updatedWishlist = List<String>.from(_userData!.wishlist);
      updatedWishlist.add(productId);

      UserModel updatedUser = _userData!.copyWith(wishlist: updatedWishlist);
      
      // Update with retry
      int retryCount = 0;
      while (retryCount < 3) {
        try {
          await _firebaseService.updateUserData(updatedUser);
          break;
        } catch (e) {
          retryCount++;
          if (retryCount == 3) throw e;
          await Future.delayed(Duration(seconds: 1));
        }
      }
      
      await _fetchUserData();
      return true;
    } catch (e) {
      _handleError(e, 'Failed to add to wishlist');
      return false;
    }
  }

  // Remove from wishlist
  Future<bool> removeFromWishlist(String productId) async {
    if (_userData == null) {
      _setError('Cannot remove from wishlist: Not logged in');
      return false;
    }

    try {
      _clearError();
      
      // Check if product is in wishlist
      if (!_userData!.wishlist.contains(productId)) {
        return true; // Not in wishlist, consider this a success
      }
      
      List<String> updatedWishlist = List<String>.from(_userData!.wishlist);
      updatedWishlist.remove(productId);

      UserModel updatedUser = _userData!.copyWith(wishlist: updatedWishlist);
      
      // Update with retry
      int retryCount = 0;
      while (retryCount < 3) {
        try {
          await _firebaseService.updateUserData(updatedUser);
          break;
        } catch (e) {
          retryCount++;
          if (retryCount == 3) throw e;
          await Future.delayed(Duration(seconds: 1));
        }
      }
      
      await _fetchUserData();
      return true;
    } catch (e) {
      _handleError(e, 'Failed to remove from wishlist');
      return false;
    }
  }
}
