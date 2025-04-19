import 'package:cloud_firestore/cloud_firestore.dart';

/// A utility class for Firebase Firestore collection references.
///
/// This centralizes all Firestore collection names in one place
/// to avoid inconsistencies and make updates easier.
class FirebaseCollections {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names
  static const String users = 'users';
  static const String products = 'products';
  static const String categories = 'categories';
  static const String productImages = 'product_images';
  static const String productImagesChunks = 'product_images_chunks';
  static const String wishlist = 'wishlist';
  static const String cart = 'cart';
  static const String orders = 'orders';

  // Collection references
  static CollectionReference get usersCollection =>
      _firestore.collection(users);

  static CollectionReference get productsCollection =>
      _firestore.collection(products);

  static CollectionReference get categoriesCollection =>
      _firestore.collection(categories);

  static CollectionReference get productImagesCollection =>
      _firestore.collection(productImages);

  static CollectionReference get productImagesChunksCollection =>
      _firestore.collection(productImagesChunks);

  static CollectionReference get wishlistCollection =>
      _firestore.collection(wishlist);

  static CollectionReference get cartCollection => _firestore.collection(cart);

  static CollectionReference get ordersCollection =>
      _firestore.collection(orders);
}
