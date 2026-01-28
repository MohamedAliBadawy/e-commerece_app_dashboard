import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  late final ScrollController _headerScrollController;
  late final ScrollController _bodyScrollController;

  @override
  void initState() {
    super.initState();
    _headerScrollController = ScrollController();
    _bodyScrollController = ScrollController();

    _headerScrollController.addListener(() {
      if (_bodyScrollController.hasClients &&
          _bodyScrollController.offset != _headerScrollController.offset) {
        _bodyScrollController.jumpTo(_headerScrollController.offset);
      }
    });
    _bodyScrollController.addListener(() {
      if (_headerScrollController.hasClients &&
          _headerScrollController.offset != _bodyScrollController.offset) {
        _headerScrollController.jumpTo(_bodyScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> getPaymentsStream() {
    return FirebaseFirestore.instance
        .collection('payple_transfer_results')
        .orderBy('receivedAt', descending: true)
        .snapshots();
  }

  String formatDate(dynamic apiTranDtm, Timestamp? receivedAt) {
    // Try to use receivedAt if available, else parse api_tran_dtm
    if (receivedAt != null) {
      final dt = receivedAt.toDate();
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
    }
    if (apiTranDtm is String && apiTranDtm.length >= 14) {
      final dt = DateTime.tryParse(apiTranDtm.substring(0, 14));
      if (dt != null) {
        return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '정산 이체 내역',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Table header
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _headerScrollController,
                    child: Container(
                      width: 1600,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildHeaderCell('날짜', 2),
                          _buildHeaderCell('이름', 2),
                          _buildHeaderCell('은행', 2),
                          _buildHeaderCell('계좌번호', 2),
                          _buildHeaderCell('금액', 1),
                          _buildHeaderCell('결과', 1),
                          _buildHeaderCell('메시지', 2),
                          _buildHeaderCell('배송 관리자 전화번호', 2), // Changed header
                        ],
                      ),
                    ),
                  ),
                  // Table body
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: getPaymentsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data == null) {
                          return Center(child: Text('데이터가 없습니다'));
                        }
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return Center(child: Text('이체 내역이 없습니다'));
                        }
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: _bodyScrollController,
                          child: SizedBox(
                            width: 1600,
                            child: ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final data =
                                    docs[index].data() as Map<String, dynamic>;
                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildCell(
                                        formatDate(
                                          data['api_tran_dtm'],
                                          data['receivedAt'],
                                        ),
                                        2,
                                      ),
                                      _buildCell(
                                        data['account_holder_name'] ?? '',
                                        2,
                                      ),
                                      _buildCell(data['bank_name'] ?? '', 2),
                                      _buildCell(
                                        data['account_num_masked'] ??
                                            data['account_num'] ??
                                            '',
                                        2,
                                      ),
                                      _buildCell(
                                        NumberFormat('#,###').format(
                                          int.tryParse(
                                                data['tran_amt']?.toString() ??
                                                    '0',
                                              ) ??
                                              0,
                                        ),
                                        1,
                                      ),
                                      _buildCell(data['result'] ?? '', 1),
                                      _buildCell(data['message'] ?? '', 2),
                                      _buildDeliveryManagerCell(
                                        data['sub_id'] ?? '',
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDeliveryManagerCell(String subId) {
    return Expanded(
      flex: 2,
      child: FutureBuilder<QuerySnapshot>(
        future:
            FirebaseFirestore.instance
                .collection('deliveryManagers')
                .where('subId', isEqualTo: subId)
                .limit(1)
                .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.docs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('없음', style: TextStyle(color: Colors.grey)),
            );
          }
          final doc = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final phone = doc['phone'] ?? '';
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(phone, style: TextStyle(fontSize: 15)),
          );
        },
      ),
    );
  }

  Widget _buildCell(String value, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Text(value, style: TextStyle(fontSize: 15)),
      ),
    );
  }
}
