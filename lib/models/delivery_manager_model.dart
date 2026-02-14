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
  String uid;
  final String invoicerCorpNum;
  final String invoicerMgtKey;
  final String invoicerTaxRegID;
  final String invoicerCorpName;
  final String invoicerCEOName;
  final String invoicerAddr;
  final String invoicerBizClass;
  final String invoicerBizType;
  final String invoicerContactName;
  final String invoicerTEL;
  final String invoicerHP;
  final String invoicerEmail;
  final bool invoicerSMSSendYN;

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
    required this.uid,
    this.invoicerCorpNum = '',
    this.invoicerMgtKey = '',
    this.invoicerTaxRegID = '',
    this.invoicerCorpName = '',
    this.invoicerCEOName = '',
    this.invoicerAddr = '',
    this.invoicerBizClass = '',
    this.invoicerBizType = '',
    this.invoicerContactName = '',
    this.invoicerTEL = '',
    this.invoicerHP = '',
    this.invoicerEmail = '',
    this.invoicerSMSSendYN = false,
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
      'uid': uid,
      'invoicerCorpNum': invoicerCorpNum,
      'invoicerMgtKey': invoicerMgtKey,
      'invoicerTaxRegID': invoicerTaxRegID,
      'invoicerCorpName': invoicerCorpName,
      'invoicerCEOName': invoicerCEOName,
      'invoicerAddr': invoicerAddr,
      'invoicerBizClass': invoicerBizClass,
      'invoicerBizType': invoicerBizType,
      'invoicerContactName': invoicerContactName,
      'invoicerTEL': invoicerTEL,
      'invoicerHP': invoicerHP,
      'invoicerEmail': invoicerEmail,
      'invoicerSMSSendYN': invoicerSMSSendYN,
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
      uid: doc['uid'] ?? '',
      invoicerCorpNum: doc['invoicerCorpNum'] ?? '',
      invoicerMgtKey: doc['invoicerMgtKey'] ?? '',
      invoicerTaxRegID: doc['invoicerTaxRegID'] ?? '',
      invoicerCorpName: doc['invoicerCorpName'] ?? '',
      invoicerCEOName: doc['invoicerCEOName'] ?? '',
      invoicerAddr: doc['invoicerAddr'] ?? '',
      invoicerBizClass: doc['invoicerBizClass'] ?? '',
      invoicerBizType: doc['invoicerBizType'] ?? '',
      invoicerContactName: doc['invoicerContactName'] ?? '',
      invoicerTEL: doc['invoicerTEL'] ?? '',
      invoicerHP: doc['invoicerHP'] ?? '',
      invoicerEmail: doc['invoicerEmail'] ?? '',
      invoicerSMSSendYN: doc['invoicerSMSSendYN'] ?? false,
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
