import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? address;
  final String? profileImageUrl;
  final List<String> wishlist;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.address,
    this.profileImageUrl,
    List<String>? wishlist,
    required this.createdAt,
  }) : wishlist = wishlist ?? [];

  // Copy with method for creating a new instance with updated values
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? address,
    String? profileImageUrl,
    List<String>? wishlist,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      wishlist: wishlist ?? this.wishlist,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'profileImageUrl': profileImageUrl,
      'wishlist': wishlist,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create user from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phone: data['phone'],
      address: data['address'],
      profileImageUrl: data['profileImageUrl'],
      wishlist: List<String>.from(data['wishlist'] ?? []),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // For debugging
  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, fullName: $fullName, phone: $phone, address: $address)';
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phone: map['phone'],
      address: map['address'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      wishlist:
          map['wishlist'] != null ? List<String>.from(map['wishlist']) : [],
    );
  }

  factory UserModel.empty() {
    return UserModel(
      id: '',
      email: '',
      fullName: '',
      createdAt: DateTime.now(),
    );
  }
}
