import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/delivery_manager_model.dart';
import '../services/category_service.dart';
import '../services/delivery_manager_service.dart';

// Stream of products based on query
final productsStreamProvider = StreamProvider.family<List<Product>, String>((ref, query) {
  final col = FirebaseFirestore.instance.collection('products');
  if (query.isEmpty) {
    return col.snapshots().map((snap) =>
        snap.docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>)).toList());
  } else {
    // Queries on 'name' as in original code
    return col
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }
});

// Future provider for categories
final categoriesFutureProvider = FutureProvider<List<Category>>((ref) async {
  return await CategoryService().getCategoriesOnce();
});

// Future provider for delivery managers
final deliveryManagersFutureProvider = FutureProvider<List<DeliveryManager>>((ref) async {
  return await DeliveryManagerService().getDeliveryManagersOnce();
});
