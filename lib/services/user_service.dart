import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app_dashboard/models/user_model.dart';

class UserService {
  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');

  Future<void> updateUser(User user) {
    return usersCollection.doc(user.userId).update(user.toDocument());
  }

  Future<void> deleteUser(String userId) {
    return usersCollection.doc(userId).delete();
  }
}
