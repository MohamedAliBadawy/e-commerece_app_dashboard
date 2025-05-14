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
      print("Generated password: $password");

      // Create Firebase Auth user
      final user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: deliveryManager.email,
        password: password,
      );
      await user.user!.updateDisplayName(deliveryManager.name);
      deliveryManager.userId = user.user!.uid;

      // Create the request data exactly like cURL
      final requestData = {
        'email': deliveryManager.email,
        'password': password,
        'name': deliveryManager.name,
      };

      // Debug output
      print("Sending data: ${jsonEncode(requestData)}");
      print("To URL: https://sendcredentialemail-nlc5xkd7oa-uc.a.run.app");

      try {
        // Try with the dio package instead of http
        final dio = Dio();
        final response = await dio.post(
          'https://sendcredentialemail-nlc5xkd7oa-uc.a.run.app',
          options: Options(headers: {'Content-Type': 'application/json'}),
          data: requestData,
        );

        print('Response status: ${response.statusCode}');
        print('Response data: ${response.data}');
      } catch (e) {
        print('Error details: $e');
        if (e is DioException) {
          print('Request that failed: ${e.requestOptions.uri}');
          print('Request data: ${e.requestOptions.data}');
          print('Response status: ${e.response?.statusCode}');
          print('Response data: ${e.response?.data}');
        }
      }

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
