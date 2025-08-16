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

  Future<String> getNextSubId() async {
    final snapshot = await deliveryManagersCollection.get();
    final subIds =
        snapshot.docs
            .map((doc) => doc['subId'] as String?)
            .where((id) => id != null && id.startsWith('sub'))
            .toList();

    int maxNum = 0;
    for (final id in subIds) {
      final numStr = id!.replaceAll(RegExp(r'[^0-9]'), '');
      final num = int.tryParse(numStr) ?? 0;
      if (num > maxNum) maxNum = num;
    }
    final nextNum = maxNum + 1;
    return 'sub${nextNum.toString().padLeft(2, '0')}';
  }

  Future<String> generateUniqueCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    String code;
    bool exists = true;

    do {
      code =
          List.generate(
            10,
            (index) => chars[rand.nextInt(chars.length)],
          ).join();
      final snapshot =
          await deliveryManagersCollection
              .where('uniqueCode', isEqualTo: code)
              .get();
      exists = snapshot.docs.isNotEmpty;
    } while (exists);

    return code;
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

  Future<void> deleteAuthUserHttp(String uid) async {
    // Replace with your actual Cloud Function URL
    final url = 'https://deleteauthuser-nlc5xkd7oa-uc.a.run.app';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user: ${response.body}');
    }
  }

  Future<void> deleteDeliveryManager(String userId) {
    return deliveryManagersCollection.doc(userId).delete();
  }
}
