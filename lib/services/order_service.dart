import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app_dashboard/models/order_model.dart';

class OrderService {
  final CollectionReference ordersCollection = FirebaseFirestore.instance
      .collection('orders');

  Future<void> addOrder(MyOrder order) {
    return ordersCollection.doc(order.orderId).set(order.toDocument());
  }

  Future<void> updateOrder(MyOrder order) {
    return ordersCollection.doc(order.orderId).update(order.toDocument());
  }

  Future<void> deleteOrder(String orderId) {
    return ordersCollection.doc(orderId).delete();
  }
}
