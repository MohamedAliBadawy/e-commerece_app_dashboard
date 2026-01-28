import 'package:intl/intl.dart';

class Refund {
  String orderId;
  String userId;
  String exchangeId;
  String reason;

  Refund({
    required this.orderId,
    required this.userId,
    required this.exchangeId,
    required this.reason,
  });

  Map<String, Object?> toDocument() {
    return {
      'orderId': orderId,
      'userId': userId,
      'exchangeId': exchangeId,
      'reason': reason,
    };
  }

  static Refund fromDocument(Map<String, dynamic> doc) {
    return Refund(
      orderId: doc['orderId'] ?? '',
      userId: doc['userId'] ?? '',
      exchangeId: doc['exchangeId'] ?? '',
      reason: doc['reason'] ?? '',
    );
  }
}
