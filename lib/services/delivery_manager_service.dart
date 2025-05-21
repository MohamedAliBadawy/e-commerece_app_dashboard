import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:ecommerce_app_dashboard/models/delivery_manager_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class DeliveryManagerService {
  final CollectionReference deliveryManagersCollection = FirebaseFirestore
      .instance
      .collection('deliveryManagers');

  Future<List<DeliveryManager>> getDeliveryManagersOnce() async {
    final snapshot = await deliveryManagersCollection.get();
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return DeliveryManager.fromDocument(data);
    }).toList();
  }

  Future<void> addDeliveryManager(DeliveryManager deliveryManager) async {
    try {
      deliveryManager.userId = deliveryManager.phone;
      // Save to Firestore regardless of email success
      return await deliveryManagersCollection
          .doc(deliveryManager.userId)
          .set(deliveryManager.toDocument());
    } catch (e) {
      print('Error in addDeliveryManager: $e');
      throw Exception('Failed to add delivery manager: $e');
    }
  }

  Future<void> updateDeliveryManager(DeliveryManager deliveryManager) {
    return deliveryManagersCollection
        .doc(deliveryManager.userId)
        .update(deliveryManager.toDocument());
  }

  Future<void> deleteDeliveryManager(String userId) {
    return deliveryManagersCollection.doc(userId).delete();
  }
}
