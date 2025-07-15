import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RefundService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<Map<String, dynamic>> requestRefund({
    required String orderId,
    required bool isRefund,
    required String uid,
  }) async {
    try {
      // Call the Firebase function
      final HttpsCallable callable = _functions.httpsCallable('requestRefund');

      final result = await callable.call({
        'orderId': orderId,
        'type': isRefund ? 'refund' : 'cancel',
        'uid': uid,
      });

      // The function returns: { status: 'refunded' or 'canceled', refundResult: {...} }
      return result.data as Map<String, dynamic>;
    } on FirebaseFunctionsException catch (e) {
      // Handle specific errors from the function
      print('Error code: ${e.code}');
      print('Error details: ${e.details}');
      print('Error message: ${e.message}');

      switch (e.code) {
        case 'invalid-argument':
          throw Exception('Missing order ID');
        case 'not-found':
          throw Exception('Order not found');
        case 'permission-denied':
          throw Exception('You do not own this order');
        case 'failed-precondition':
          throw Exception('Order missing required payment information');
        case 'internal':
          throw Exception('Refund processing failed');
        default:
          throw Exception('An error occurred: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
