import 'package:intl/intl.dart';

class Exchange {
  String orderId;
  String userId;
  String exchangeId;
  String reason;

  Exchange({
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

  static Exchange fromDocument(Map<String, dynamic> doc) {
    return Exchange(
      orderId: doc['orderId'] ?? '',
      userId: doc['userId'] ?? '',
      exchangeId: doc['exchangeId'] ?? '',
      reason: doc['reason'] ?? '',
    );
  }
}
