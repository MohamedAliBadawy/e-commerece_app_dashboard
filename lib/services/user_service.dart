import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app_dashboard/models/user_model.dart';
import 'package:http/http.dart' as http;

class UserService {
  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');

  Future<void> updateUser(User user) {
    return usersCollection.doc(user.userId).update(user.toDocument());
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

  Future<void> deleteUser(String userId) {
    return usersCollection.doc(userId).delete();
  }
}
