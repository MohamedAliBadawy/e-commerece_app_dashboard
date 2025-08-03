import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DeliveryManager {
  String userId;
  String email;
  String name;
  String phone;
  String preferences;
  Timestamp? createdAt;
  String subId;
  String bankCodeStd;
  String code;
  String accountNum;
  String accountHolderInfoType;
  String accountHolderInfo;
  DeliveryManager({
    required this.userId,
    required this.email,
    required this.name,
    required this.phone,
    required this.preferences,
    this.createdAt,
    required this.subId,
    required this.code,
    required this.accountNum,
    required this.accountHolderInfoType,
    required this.accountHolderInfo,
    required this.bankCodeStd,
  });

  Map<String, Object?> toDocument() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      'phone': phone,
      'preferences': preferences,
      'subId': subId,
      'bankCodeStd': bankCodeStd,
      'code': code,
      'accountNum': accountNum,
      'accountHolderInfoType': accountHolderInfoType,
      'accountHolderInfo': accountHolderInfo,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  static DeliveryManager fromDocument(Map<String, dynamic> doc) {
    return DeliveryManager(
      userId: doc['userId'],
      email: doc['email'],
      name: doc['name'],
      phone: doc['phone'],
      preferences: doc['preferences'],
      subId: doc['subId'] ?? '',
      bankCodeStd: doc['bankCodeStd'] ?? '',
      code: doc['code'] ?? '',
      accountNum: doc['accountNum'] ?? '',
      accountHolderInfoType: doc['accountHolderInfoType'] ?? '0',
      accountHolderInfo: doc['accountHolderInfo'] ?? '',
      createdAt: doc['createdAt'],
    );
  }

  String get formattedCreatedAt {
    if (createdAt == null) return 'Not available';

    final dateTime = createdAt!.toDate();
    final formatter = DateFormat(
      'MM/dd/yyyy, hh:mm a',
    ); // Customize format as needed
    return formatter.format(dateTime);
  }
}
