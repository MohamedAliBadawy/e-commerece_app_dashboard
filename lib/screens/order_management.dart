import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app_dashboard/models/delivery_manager_model.dart';
import 'package:ecommerce_app_dashboard/models/exchange_model.dart';
import 'package:ecommerce_app_dashboard/models/order_model.dart';
import 'package:ecommerce_app_dashboard/models/product_model.dart';
import 'package:ecommerce_app_dashboard/models/refund_model.dart';
import 'package:ecommerce_app_dashboard/models/user_model.dart';
import 'package:ecommerce_app_dashboard/services/order_service.dart';
import 'package:ecommerce_app_dashboard/services/refund_service.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Loading...'),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  int _currentTabIndex = 0;

  String _searchQuery = '';
  final OrderService _orderService = OrderService();
  final TextEditingController _searchController = TextEditingController();
  final List<MyOrder> _selectedOrders = [];
  Timer? _debounce;
  Map<String, String?> selectedManagerNames = {}; // orderId -> managerName
  final RefundService _refundService = RefundService();
  late final ScrollController _headerScrollController;
  late final ScrollController _bodyScrollController;

  Future<void> _downloadOrdersAsExcel() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('orders').get();

    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Header row
    sheet.appendRow([
      TextCellValue('주문 ID'),
      TextCellValue('수취인'),
      TextCellValue('전화번호'),
      TextCellValue('주소'),
      TextCellValue('상세주소'),
      TextCellValue('배송 요청사항'),
      TextCellValue('제품'),
      TextCellValue('수량'),
      TextCellValue('날짜'),
      TextCellValue('가격'),
      TextCellValue('공급가'),
      TextCellValue('배송비'),
      TextCellValue('도서산간 추가 배송비'),
      TextCellValue('택배사'),
      TextCellValue('운송장 번호'),
    ]);

    for (var doc in querySnapshot.docs) {
      final order = MyOrder.fromDocument(doc.data());

      // Fetch user and product info
      final userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(order.userId)
              .get();
      final user =
          userSnapshot.exists
              ? User.fromDocument(userSnapshot.data() as Map<String, dynamic>)
              : null;

      final productSnapshot =
          await FirebaseFirestore.instance
              .collection('products')
              .doc(order.productId)
              .get();
      final product =
          productSnapshot.exists
              ? Product.fromMap(productSnapshot.data() as Map<String, dynamic>)
              : null;

      sheet.appendRow([
        TextCellValue(order.orderId),
        TextCellValue(user?.name ?? ''),
        TextCellValue(order.phoneNo),
        TextCellValue(order.deliveryAddress),
        TextCellValue(order.deliveryAddressDetail),
        TextCellValue(order.deliveryInstructions),
        TextCellValue(product?.productName ?? ''),
        TextCellValue(order.quantity.toString()),
        TextCellValue(
          DateTime.parse(order.orderDate).toLocal().toString().split('.')[0],
        ),
        TextCellValue(order.totalPrice.toString()),

        TextCellValue(product?.supplyPrice.toString() ?? ''),
        TextCellValue(product?.deliveryPrice?.toString() ?? ''),
        TextCellValue(product?.shippingFee?.toString() ?? ''),
        TextCellValue(order.courier),
        TextCellValue(order.trackingNumber),
      ]);
    }

    final fileBytes = excel.encode();
    if (fileBytes != null) {
      await FileSaver.instance.saveFile(
        name: 'orders.xlsx',
        bytes: Uint8List.fromList(fileBytes),
      );
    }
  }

  Stream<QuerySnapshot> getOrdersStream(String query) {
    if (query.isEmpty) {
      return FirebaseFirestore.instance.collection('orders').snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('orders')
          .where('orderId', isGreaterThanOrEqualTo: query)
          .where('orderId', isLessThan: query + 'z')
          .snapshots();
    }
  }

  Stream<QuerySnapshot> getRefundRequestsStream(String query) {
    if (query.isEmpty) {
      return FirebaseFirestore.instance.collection('refunds').snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('refunds')
          .where('orderId', isGreaterThanOrEqualTo: query)
          .where('orderId', isLessThan: query + 'z')
          .snapshots();
    }
  }

  Stream<QuerySnapshot> getExchangeRequestsStream(String query) {
    if (query.isEmpty) {
      return FirebaseFirestore.instance.collection('exchanges').snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('exchanges')
          .where('orderId', isGreaterThanOrEqualTo: query)
          .where('orderId', isLessThan: query + 'z')
          .snapshots();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

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
    _debounce?.cancel();
    _searchController.dispose();
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefund(
    BuildContext context,
    bool isRefund,
    String orderId,
    String uid,
  ) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    try {
      final result = await _refundService.requestRefund(
        orderId: orderId,
        isRefund: isRefund,
        uid: uid,
      );

      // Delete the refund document after successful refund
      try {
        // Query to find the refund document with this orderId
        final refundQuery =
            await FirebaseFirestore.instance
                .collection('refunds')
                .where('orderId', isEqualTo: orderId)
                .get();

        // Delete all matching documents (should be only one)
        for (var doc in refundQuery.docs) {
          await doc.reference.delete();
        }
      } catch (deleteError) {
        print('Error deleting refund document: $deleteError');
        // Don't throw - the refund was successful even if deletion fails
      }

      Navigator.pop(context); // Close loading

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['status'] == 'refunded'
                ? 'Order refunded successfully'
                : 'Order canceled successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SizedBox(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '검색',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              minimumSize: Size(110, 40),
            ),
            onPressed: _downloadOrdersAsExcel,
            child: Text('Download Orders as Excel'),
          ),
          SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,

            child: SizedBox(
              width: 1600,

              child: DefaultTabController(
                length: 3,
                child: TabBar(
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'All Orders'),
                    Tab(text: 'Incoming refund requests'),
                    Tab(text: 'Incoming exchange requests'),
                  ],
                  onTap: (index) {
                    setState(() {
                      _currentTabIndex = index;
                    });
                  },
                ),
              ),
            ),
          ),
          _currentTabIndex == 0
              ? _buildOrdersTable()
              : _currentTabIndex == 1
              ? _buildRefundRequestsTable()
              : _buildExchangeRequestsTable(),
          /*         Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Table header
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildTableHeader('상품', 2),
                        _buildTableHeader('주문 번호', 1),
                        _buildTableHeader('배송 관리자', 2),
                        _buildTableHeader('기준 시간', 1),
                        _buildTableHeader('재고', 1),
                        _buildTableHeader('운송장 번호', 1),
                        _buildTableHeader('선택', 1),
                      ],
                    ),
                  ),
                  // Table body
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: getOrdersStream(_searchQuery),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        // 3. Check for null data
                        if (!snapshot.hasData || snapshot.data == null) {
                          return Center(child: Text('주문이 없습니다'));
                        }
                        final orders = snapshot.data!.docs;

                        if (orders.isEmpty) {
                          return Center(child: Text('주문이 없습니다'));
                        }
                        return ListView.builder(
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order = MyOrder.fromDocument(
                              orders[index].data() as Map<String, dynamic>,
                            );
                            return _buildOrderRow(order);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ), */
        ],
      ),
    );
  }

  Widget _buildOrdersTable() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _headerScrollController,
              child: Container(
                width: 1600,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.black),
                    left: BorderSide(color: Colors.black),
                    right: BorderSide(color: Colors.black),
                    top: BorderSide(color: Colors.black),
                  ),
                ),
                child: Row(
                  children: [
                    _buildHeaderCell('상품', flex: 2, hasRightBorder: true),
                    _buildHeaderCell('주문 번호', flex: 1, hasRightBorder: true),
                    _buildHeaderCell('사용자', flex: 1, hasRightBorder: true),
                    _buildHeaderCell('사용자 ID', flex: 1, hasRightBorder: true),
                    _buildHeaderCell('주소', flex: 1, hasRightBorder: true),
                    _buildHeaderCell('상세주소', flex: 1, hasRightBorder: true),
                    _buildHeaderCell('수량', flex: 1, hasRightBorder: true),
                    _buildHeaderCell('가격', flex: 1, hasRightBorder: true),
                    _buildHeaderCell('날짜', flex: 1, hasRightBorder: true),
                    _buildHeaderCell(
                      '',
                      flex: 1,
                      hasRightBorder: false,
                    ), // last cell, no border
                  ],
                ),
              ),
            ),

            /*             // Table header
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                        _buildTableHeader('상품', 1),
                  _buildTableHeader('주문 번호', 1),
                  _buildTableHeader('배송 관리자', 2),
                  _buildTableHeader('기준 시간', 1),
                  _buildTableHeader('재고', 1),
                  _buildTableHeader('운송장 번호', 1),
                  _buildTableHeader('선택', 1),
                ],
              ),
            ), */
            // Table body
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getOrdersStream(_searchQuery),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  // 3. Check for null data
                  if (!snapshot.hasData || snapshot.data == null) {
                    return Center(child: Text('주문이 없습니다'));
                  }
                  final orders = snapshot.data!.docs;

                  if (orders.isEmpty) {
                    return Center(child: Text('주문이 없습니다'));
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _bodyScrollController,
                    child: SizedBox(
                      width: 1600,
                      child: ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = MyOrder.fromDocument(
                            orders[index].data() as Map<String, dynamic>,
                          );
                          return _buildOrderRow(order);
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
    );
  }

  Widget _buildRefundRequestsTable() {
    return Expanded(
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
                    _buildTableHeader('상품', 2),
                    _buildTableHeader('주문 번호', 1),
                    _buildTableHeader('사용자', 1),
                    _buildTableHeader('사용자 ID', 1),
                    _buildTableHeader('주소', 1),
                    _buildTableHeader('가격', 1),
                    _buildTableHeader('사유', 1),
                    _buildTableHeader('', 1),
                  ],
                ),
              ),
            ),
            // Table body
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getRefundRequestsStream(_searchQuery),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  // 3. Check for null data
                  if (!snapshot.hasData || snapshot.data == null) {
                    return Center(child: Text('주문이 없습니다'));
                  }
                  final orders = snapshot.data!.docs;

                  if (orders.isEmpty) {
                    return Center(child: Text('주문이 없습니다'));
                  }
                  print(orders.first.data());
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _bodyScrollController,
                    child: SizedBox(
                      width: 1600,

                      child: ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final data =
                              orders[index].data() as Map<String, dynamic>;
                          return _buildRefundRow(Refund.fromDocument(data));
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
    );
  }

  Widget _buildExchangeRequestsTable() {
    return Expanded(
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
                    _buildTableHeader('상품', 2),
                    _buildTableHeader('주문 번호', 1),
                    _buildTableHeader('사용자', 1),
                    _buildTableHeader('사용자 ID', 1),
                    _buildTableHeader('주소', 1),
                    _buildTableHeader('가격', 1),
                    _buildTableHeader('사유', 1),
                    _buildTableHeader('', 1),
                  ],
                ),
              ),
            ),
            // Table body
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getExchangeRequestsStream(_searchQuery),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  // 3. Check for null data
                  if (!snapshot.hasData || snapshot.data == null) {
                    return Center(child: Text('주문이 없습니다'));
                  }
                  final orders = snapshot.data!.docs;

                  if (orders.isEmpty) {
                    return Center(child: Text('주문이 없습니다'));
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _bodyScrollController,
                    child: SizedBox(
                      width: 1600,
                      child: ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = MyOrder.fromDocument(
                            orders[index].data() as Map<String, dynamic>,
                          );
                          return _buildOrderRow(order);
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
    );
  }

  // Add to the same file or a utils file
  Widget _buildHeaderCell(
    String title, {
    int flex = 1,
    bool hasRightBorder = true,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border:
              hasRightBorder
                  ? Border(right: BorderSide(color: Colors.black))
                  : null,
        ),
        child: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTableHeader(String title, int flex) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildNewTableHeader(String title, int flex) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildOrderRow(MyOrder order) {
    final bool isSelected = _selectedOrders.any(
      (p) => p.orderId == order.orderId,
    );
    bool isProductDeleted = false;
    Product product = Product.empty();
    return FutureBuilder(
      future: Future.wait([
        FirebaseFirestore.instance.collection('deliveryManagers').get(),
        FirebaseFirestore.instance
            .collection('products')
            .doc(order.productId)
            .get(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text('배송 관리자가 없습니다'));
        }
        final querySnapshot = snapshot.data![0] as QuerySnapshot;
        final deliveryManagers = querySnapshot.docs;

        final List<DeliveryManager> deliveryManagerNames =
            deliveryManagers
                .map(
                  (doc) => DeliveryManager.fromDocument(
                    (doc as DocumentSnapshot).data() as Map<String, dynamic>,
                  ),
                )
                .toList();
        if (order.deliveryManagerId.isNotEmpty &&
            selectedManagerNames[order.orderId] == null) {
          selectedManagerNames[order.orderId] = order.deliveryManagerId!;
        }
        if ((snapshot.data![1] as DocumentSnapshot).data() == null) {
          isProductDeleted = true;
        } else {
          product = Product.fromMap(
            (snapshot.data![1] as DocumentSnapshot).data()
                as Map<String, dynamic>,
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.1) : null,
            border: Border(
              bottom: BorderSide(color: Colors.black),
              top: BorderSide(color: Colors.black),
              left: BorderSide(color: Colors.black),
              right: BorderSide(color: Colors.black),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.black)),
                  ),
                  child: Row(
                    children: [
                      isProductDeleted
                          ? Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey.shade300,
                          )
                          : product.imgUrl != null
                          ? Image.network(
                            product.imgUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                          : Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey.shade300,
                          ),
                      SizedBox(width: 16),
                      Flexible(
                        child: Text(
                          isProductDeleted ? '삭제된 상품' : product.productName,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  height: 50,

                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.black)),
                  ),
                  child: Text(order.orderId),
                ),
              ),
              Expanded(
                flex: 1,
                child:
                    selectedManagerNames[order.orderId] != null
                        ? Container(
                          height: 50,

                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.black),
                            ),
                          ),
                          child: Text(
                            deliveryManagerNames
                                .firstWhere(
                                  (manager) =>
                                      manager.userId ==
                                      selectedManagerNames[order.orderId],
                                )
                                .name,
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                        : Container(
                          height: 50,

                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.black),
                            ),
                          ),
                          child: Text(
                            '널',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
              ),
              Expanded(
                flex: 1,
                child:
                    selectedManagerNames[order.orderId] != null
                        ? Container(
                          height: 50,

                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.black),
                            ),
                          ),
                          child: Text(
                            deliveryManagerNames
                                .firstWhere(
                                  (manager) =>
                                      manager.userId ==
                                      selectedManagerNames[order.orderId],
                                )
                                .userId,
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                        : Container(
                          height: 50,

                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.black),
                            ),
                          ),
                          child: Text(
                            '널',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  height: 50,

                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.black)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(order.deliveryAddress),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  height: 50,

                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.black)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(order.deliveryAddressDetail),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  height: 50,

                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.black)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(order.quantity.toString()),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  height: 50,

                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.black)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(order.totalPrice.toString()),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  height: 50,

                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.black)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    DateTime.parse(
                      order.orderDate,
                    ).toLocal().toString().split('.')[0],
                  ),
                ),
              ),
              Expanded(
                child: IconButton(
                  onPressed: () async {
                    /*                         _showLoadingDialog(context);
                      order.deliveryManagerId =
                          selectedManagerNames[order.orderId]!;
                      order.deliveryManager =
                          deliveryManagerNames
                              .firstWhere(
                                (name) =>
                                    name.userId ==
                                    selectedManagerNames[order.orderId]!,
                              )
                              .name;
                      await _orderService.updateOrder(order);
                  
                      Navigator.of(context, rootNavigator: true).pop();
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('완료'))); */
                  },
                  icon: Icon(Icons.edit),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRefundRow(Refund refund) {
    final bool isSelected = _selectedOrders.any(
      (p) => p.orderId == refund.orderId,
    );
    print(refund.userId);
    print(refund.orderId);

    return FutureBuilder(
      future: Future.wait([
        FirebaseFirestore.instance.collection('users').doc(refund.userId).get(),
        FirebaseFirestore.instance
            .collection('orders')
            .doc(refund.orderId)
            .get(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text('배송 관리자가 없습니다'));
        }

        // Add null checks for each data retrieval
        final userSnapshot = snapshot.data![0];
        final orderSnapshot = snapshot.data![1];

        if (userSnapshot == null || orderSnapshot == null) {
          print('User or Order snapshot is null');
          return Center(child: Text('데이터를 찾을 수 없습니다'));
        }

        final user = User.fromDocument(
          userSnapshot.data() as Map<String, dynamic>,
        );

        final order = MyOrder.fromDocument(
          orderSnapshot.data() as Map<String, dynamic>,
        );

        return Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.1) : null,

            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Flexible(
                        child: FutureBuilder(
                          future:
                              FirebaseFirestore.instance
                                  .collection('products')
                                  .doc(order.productId)
                                  .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (!snapshot.hasData || snapshot.data == null) {
                              return Center(child: Text('상품 정보가 없습니다'));
                            }
                            final product = Product.fromMap(
                              (snapshot.data as DocumentSnapshot).data()
                                  as Map<String, dynamic>,
                            );
                            print(product.imgUrl);
                            return Row(
                              children: [
                                product.imgUrl != null
                                    ? Image.network(
                                      product.imgUrl!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    )
                                    : Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey.shade300,
                                    ),
                                SizedBox(width: 16),
                                Flexible(child: Text(product.productName)),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(order.orderId),
                ),
              ),

              /*               Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(product.baselineTime.toString()),
                ),
              ), */
              /*               Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(product.stock.toString()),
                ),
              ), */
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(user.name),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(user.userId),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(order.deliveryAddress),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(order.totalPrice.toString()),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(refund.reason),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check_circle, color: Colors.green),
                      tooltip: 'Accept',
                      onPressed:
                          () => _handleRefund(
                            context,
                            true,
                            refund.orderId,
                            refund.userId,
                          ),
                    ),
                    IconButton(
                      icon: Icon(Icons.cancel, color: Colors.red),
                      tooltip: 'Cancel',
                      onPressed:
                          () => _handleRefund(
                            context,
                            false,
                            refund.orderId,
                            refund.userId,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExchangeRow(Exchange exchange) {
    final bool isSelected = _selectedOrders.any(
      (p) => p.orderId == exchange.orderId,
    );
    print(exchange.userId);
    print(exchange.orderId);

    return FutureBuilder(
      future: Future.wait([
        FirebaseFirestore.instance
            .collection('users')
            .doc(exchange.userId)
            .get(),
        FirebaseFirestore.instance
            .collection('orders')
            .doc(exchange.orderId)
            .get(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text('배송 관리자가 없습니다'));
        }

        // Add null checks for each data retrieval
        final userSnapshot = snapshot.data![0];
        final orderSnapshot = snapshot.data![1];

        if (userSnapshot == null || orderSnapshot == null) {
          print('User or Order snapshot is null');
          return Center(child: Text('데이터를 찾을 수 없습니다'));
        }

        final user = User.fromDocument(
          userSnapshot.data() as Map<String, dynamic>,
        );

        final order = MyOrder.fromDocument(
          orderSnapshot.data() as Map<String, dynamic>,
        );

        return Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.1) : null,

            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Flexible(
                        child: FutureBuilder(
                          future:
                              FirebaseFirestore.instance
                                  .collection('products')
                                  .doc(order.productId)
                                  .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (!snapshot.hasData || snapshot.data == null) {
                              return Center(child: Text('상품 정보가 없습니다'));
                            }
                            final product = Product.fromMap(
                              (snapshot.data as DocumentSnapshot).data()
                                  as Map<String, dynamic>,
                            );
                            print(product.imgUrl);
                            return Row(
                              children: [
                                product.imgUrl != null
                                    ? Image.network(
                                      product.imgUrl!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    )
                                    : Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey.shade300,
                                    ),
                                SizedBox(width: 16),
                                Flexible(child: Text(product.productName)),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(order.orderId),
                ),
              ),

              /*               Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(product.baselineTime.toString()),
                ),
              ), */
              /*               Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(product.stock.toString()),
                ),
              ), */
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(user.name),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(user.userId),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(order.deliveryAddress),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(order.totalPrice.toString()),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(exchange.reason),
                ),
              ),
              Expanded(
                child: IconButton(
                  onPressed: () async {
                    /*   _showLoadingDialog(context);
                    order.deliveryManagerId =
                        selectedManagerNames[order.orderId]!;
                    order.deliveryManager =
                        deliveryManagerNames
                            .firstWhere(
                              (name) =>
                                  name.userId ==
                                  selectedManagerNames[order.orderId]!,
                            )
                            .name;
                    await _orderService.updateOrder(order);

                    Navigator.of(context, rootNavigator: true).pop();
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('완료'))); */
                  },
                  icon: Icon(Icons.edit),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
