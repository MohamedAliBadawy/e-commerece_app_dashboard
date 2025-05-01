import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app_dashboard/models/delivery_manager_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeliveryManagerService {
  final CollectionReference deliveryManagersCollection = FirebaseFirestore
      .instance
      .collection('deliveryManagers');

  String generateRandomPassword(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#%^&*';
    final rand = Random.secure();
    return List.generate(
      length,
      (index) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  Future<void> addDeliveryManager(DeliveryManager deliveryManager) async {
    try {
      final password = generateRandomPassword(12);
      print(password);
      final user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: deliveryManager.email,
        password: password,
      );
      await user.user!.updateDisplayName(deliveryManager.name);
      deliveryManager.userId = user.user!.uid;
      return deliveryManagersCollection
          .doc(deliveryManager.userId)
          .set(deliveryManager.toDocument());
    } catch (e) {
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
