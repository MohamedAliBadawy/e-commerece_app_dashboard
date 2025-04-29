import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_file/cross_file.dart';
import 'package:ecommerce_app_dashboard/models/delivery_manager_model.dart';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class DeliveryManagerService {
  final CollectionReference deliveryManagersCollection = FirebaseFirestore
      .instance
      .collection('deliveryManagers');

  Future<void> addDeliveryManager(DeliveryManager deliveryManager) {
    return deliveryManagersCollection
        .doc(deliveryManager.userId)
        .set(deliveryManager.toDocument());
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
