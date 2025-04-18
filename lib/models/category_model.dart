import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String imageUrl;
  final String itemCount;
  final Color color;
  final String description;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.itemCount,
    required this.color,
    required this.description,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      itemCount: data['itemCount'] ?? '0 items',
      color: Color(int.parse(data['color'] ?? '0xFF2D3142')),
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'itemCount': itemCount,
      'color': color.value.toString(),
      'description': description,
    };
  }
}
