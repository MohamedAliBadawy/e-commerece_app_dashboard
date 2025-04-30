import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app_dashboard/models/delivery_manager_model.dart';
import 'package:ecommerce_app_dashboard/models/order_model.dart';
import 'package:ecommerce_app_dashboard/models/product_model.dart';
import 'package:ecommerce_app_dashboard/services/delivery_manager_service.dart';
import 'package:ecommerce_app_dashboard/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final OrderService _orderService = OrderService();

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<MyOrder> _orders = [];
  List<MyOrder> _filteredOrders = [];
  final List<MyOrder> _selectedOrders = [];
  Timer? _debounce;
  Map<String, String?> selectedManagerNames = {}; // orderId -> managerName

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

  void _selectOrder(MyOrder order) {
    setState(() {
      if (!_selectedOrders.any((p) => p.orderId == order.orderId)) {
        _selectedOrders.add(order);
      }
    });
  }

  void _clearSelections() {
    setState(() {
      _selectedOrders.clear();
    });
  }

  void _deselectOrder(MyOrder order) {
    setState(() {
      _selectedOrders.removeWhere((p) => p.orderId == order.orderId);
    });
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
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
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
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24.h),
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
                        hintText: 'Search',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ),
              ),
            ],
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
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildTableHeader('Product', 2),
                        _buildTableHeader('Order No.', 1),
                        _buildTableHeader('Delivery Manager', 2),
                        _buildTableHeader('Baseline Time', 1),
                        _buildTableHeader('Stock', 1),
                        _buildTableHeader('Tracking No.', 1),
                        _buildTableHeader('', 1),
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
                          return Center(child: Text('No orders available'));
                        }
                        final orders = snapshot.data!.docs;

                        if (orders.isEmpty) {
                          return Center(child: Text('No orders found'));
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
          ),
        ],
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

  Widget _buildOrderRow(MyOrder order) {
    final bool isSelected = _selectedOrders.any(
      (p) => p.orderId == order.orderId,
    );

    String? selectedManagerName;

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
          return Center(child: Text('No delivery managers found'));
        }
        final querySnapshot = snapshot.data![0] as QuerySnapshot;
        final deliveryManagers = querySnapshot.docs;

        final List<String> deliveryManagerNames =
            deliveryManagers.map((doc) => doc['name'] as String).toList();
        final product = Product.fromMap(
          (snapshot.data![1] as DocumentSnapshot).data()
              as Map<String, dynamic>,
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
                      SizedBox(width: 16.w),
                      Flexible(child: Text(product.productName)),
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
              Expanded(
                flex: 2,
                child: DropdownButton<String>(
                  value: selectedManagerNames[order.orderId],
                  hint: Text('Select'),
                  items:
                      deliveryManagerNames.map((name) {
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(name),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedManagerNames[order.orderId] = newValue;
                    });
                  },
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(product.baselineTime.toString()),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(product.stock.toString()),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(order.trackingNumber),
                ),
              ),
              Expanded(
                child: IconButton(onPressed: () {}, icon: Icon(Icons.edit)),
              ),
            ],
          ),
        );
      },
    );
  }
}
