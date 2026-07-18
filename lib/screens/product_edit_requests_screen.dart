import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../models/product_edit_request_model.dart';
import '../services/category_service.dart';

class ProductEditRequestsScreen extends StatefulWidget {
  final bool isNewProductOnly;

  const ProductEditRequestsScreen({
    super.key,
    required this.isNewProductOnly,
  });

  @override
  State<ProductEditRequestsScreen> createState() =>
      _ProductEditRequestsScreenState();
}

class _ProductEditRequestsScreenState extends State<ProductEditRequestsScreen> {
  String _statusFilter = 'all';

  Future<Product?> _fetchCurrentProduct(String productId) async {
    final doc = await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .get();
    if (doc.exists && doc.data() != null) {
      return Product.fromMap(doc.data()!);
    }
    return null;
  }

  void _showRequestDetailsDialog(
    BuildContext context,
    ProductEditRequestModel request,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<Product?>(
          future: request.isNewProduct == true
              ? Future.value(null)
              : _fetchCurrentProduct(request.productId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                content: Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: const SizedBox.shrink(),
                ),
              );
            }

            final currentProduct = snapshot.data;
            final isNew =
                request.isNewProduct == true || currentProduct == null;

            String formatRegions(String? method, Map<String, dynamic>? address) {
              if (method != '지역배송') return '전국 배송';
              if (address == null) return '지역 미지정';
              final List<String> included = address['includedSigungu'] is List
                  ? List<String>.from(address['includedSigungu'])
                  : [];
              final List<String> excluded = address['excludedEupmyeondong'] is List
                  ? List<String>.from(address['excludedEupmyeondong'])
                  : [];
              String result = '허용: ${included.isEmpty ? '-' : included.join(', ')}';
              if (excluded.isNotEmpty) {
                result += '\n제외: ${excluded.join(', ')}';
              }
              return result;
            }

            Widget buildComparisonRow(
              String fieldName,
              String currentValue,
              String proposedValue,
            ) {
              final bool isChanged = currentValue != proposedValue;
              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  color: isChanged ? Colors.grey.shade50 : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        fieldName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (!isNew)
                      Expanded(
                        flex: 3,
                        child: Text(
                          currentValue,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            decoration:
                                isChanged ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        proposedValue,
                        style: TextStyle(
                          color:
                              isChanged ? Colors.black : Colors.grey.shade800,
                          fontWeight:
                              isChanged ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            Widget buildImageComparisonRow(
              String fieldName,
              List<String> currentUrls,
              List<String> proposedUrls,
            ) {
              final bool isChanged = !listEquals(currentUrls, proposedUrls);
              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  color: isChanged ? Colors.grey.shade50 : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        fieldName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (!isNew)
                      Expanded(
                        flex: 3,
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: currentUrls.isEmpty
                              ? [const Text('없음')]
                              : currentUrls
                                  .map((url) => Image.network(
                                        url,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ))
                                  .toList(),
                        ),
                      ),
                    Expanded(
                      flex: 3,
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: proposedUrls.isEmpty
                            ? [const Text('없음')]
                            : proposedUrls
                                .map((url) => Image.network(
                                      url,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ))
                                .toList(),
                      ),
                    ),
                  ],
                ),
              );
            }

            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isNew ? '신규 상품 등록 요청' : '상품 수정 요청 비교',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: SizedBox(
                width: 800,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        color: Colors.grey.shade100,
                        child: Row(
                          children: [
                            const Expanded(
                              flex: 2,
                              child: Text(
                                '항목',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (!isNew)
                              const Expanded(
                                flex: 3,
                                child: Text(
                                  '현재 값',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            const Expanded(
                              flex: 3,
                              child: Text(
                                '요청 값',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      buildComparisonRow(
                        '상품명',
                        currentProduct?.productName ?? '',
                        request.productName,
                      ),
                      buildComparisonRow(
                        '카테고리',
                        currentProduct?.category ?? '',
                        request.category,
                      ),
                      buildComparisonRow(
                        '공급가',
                        currentProduct?.supplyPrice.toString() ?? '',
                        request.supplyPrice.toString(),
                      ),
                      buildComparisonRow(
                        '배송비',
                        currentProduct?.deliveryPrice?.toString() ?? '',
                        request.deliveryPrice.toString(),
                      ),
                      buildComparisonRow(
                        '기본 배송비',
                        currentProduct?.shippingFee?.toString() ?? '',
                        request.shippingFee.toString(),
                      ),
                      buildComparisonRow(
                        '재고',
                        currentProduct?.stock.toString() ?? '',
                        request.stock.toString(),
                      ),
                      buildComparisonRow(
                        '보관 방법 (Storage)',
                        currentProduct?.description ?? '',
                        request.storageInfo,
                      ),
                      buildComparisonRow(
                        '안내 사항 (Instructions)',
                        currentProduct?.instructions ?? '',
                        request.instructions,
                      ),
                      buildComparisonRow(
                        '배송 형태/수수료 정보',
                        currentProduct == null
                            ? ''
                            : (currentProduct.freeShipping == true
                                ? '무료 배송'
                                : '유료 배송'),
                        request.noFreeShipping
                            ? '조건부 무료 배송 (기준: \$${request.freeShippingThreshold})'
                            : '무료 배송',
                      ),
                      buildComparisonRow(
                        '배송 방식',
                        currentProduct?.shippingMethod ?? '택배배송',
                        request.shippingMethod ?? '택배배송',
                      ),
                      buildComparisonRow(
                        '배송 지역',
                        formatRegions(currentProduct?.shippingMethod, currentProduct?.address),
                        formatRegions(request.shippingMethod, request.address),
                      ),
                      buildImageComparisonRow(
                        '대표 이미지',
                        currentProduct?.imgUrl != null
                            ? [currentProduct!.imgUrl!]
                            : [],
                        request.imgUrl.isNotEmpty ? [request.imgUrl] : [],
                      ),
                      buildImageComparisonRow(
                        '추가 이미지',
                        currentProduct?.imgUrls.whereType<String>().toList() ??
                            [],
                        request.imgUrls,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (request.status == 'pending') ...[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _rejectEditRequest(request);
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('거절'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _acceptEditRequest(request);
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    child: const Text('승인'),
                  ),
                ] else
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('닫기'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _acceptEditRequest(ProductEditRequestModel request) async {
    try {
      Product? existingProduct;
      String productId = request.productId;

      if (request.isNewProduct == true || productId.isEmpty) {
        if (productId.isEmpty) {
          productId = FirebaseFirestore.instance.collection('products').doc().id;
        }
      } else {
        existingProduct = await _fetchCurrentProduct(productId);
      }

      List<String>? categoryList;
      try {
        final categories = await CategoryService().getCategoriesOnce();
        final match = categories.firstWhere(
          (cat) => cat.name.trim() == request.category.trim(),
        );
        categoryList = [match.id];
      } catch (_) {
        // Fallback to name if matching category ID is not found
      }

      final product = Product.fromEditRequest(
        request,
        existingProduct: existingProduct,
        productId: productId,
        categoryList: categoryList,
      );

      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .set(product.toMap());

      await FirebaseFirestore.instance
          .collection('product_edit_requests')
          .doc(request.id)
          .update({
        'status': 'approved',
        'product_id': productId,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('요청이 승인되어 상품 정보가 업데이트되었습니다.'),
          backgroundColor: Colors.black,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('승인 중 오류 발생: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectEditRequest(ProductEditRequestModel request) async {
    try {
      await FirebaseFirestore.instance
          .collection('product_edit_requests')
          .doc(request.id)
          .update({'status': 'rejected'});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('요청이 거절되었습니다.'),
          backgroundColor: Colors.black,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('거절 중 오류 발생: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEditRequestRow(ProductEditRequestModel request) {
    Color statusColor;
    Color statusTextColor;
    String statusText;
    switch (request.status) {
      case 'pending':
        statusColor = Colors.grey.shade100;
        statusTextColor = Colors.grey.shade800;
        statusText = '대기중';
        break;
      case 'approved':
        statusColor = Colors.black;
        statusTextColor = Colors.white;
        statusText = '승인됨';
        break;
      case 'rejected':
        statusColor = Colors.red.shade50;
        statusTextColor = Colors.red.shade800;
        statusText = '거절됨';
        break;
      default:
        statusColor = Colors.grey.shade100;
        statusTextColor = Colors.black;
        statusText = request.status;
    }

    String formattedDate = '';
    if (request.requestedAt is Timestamp) {
      final dateTime = (request.requestedAt as Timestamp).toDate();
      formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                request.productName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                (request.sellerName != null && request.sellerName!.trim().isNotEmpty)
                    ? request.sellerName!
                    : (request.requestedBy ?? request.sellerUid ?? 'Unknown'),
              ),
            ),
          ),

          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: UnconstrainedBox(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(formattedDate),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => _showRequestDetailsDialog(context, request),
                    child: const Text('상세 보기'),
                  ),
                  if (request.status == 'pending') ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _acceptEditRequest(request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('승인'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _rejectEditRequest(request),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('거절'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isNewProductOnly ? '상품 등록 요청 관리' : '상품 수정 요청 관리';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                '상태 필터:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _statusFilter,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _statusFilter = value;
                    });
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('전체')),
                  DropdownMenuItem(value: 'pending', child: Text('대기중')),
                  DropdownMenuItem(value: 'approved', child: Text('승인됨')),
                  DropdownMenuItem(value: 'rejected', child: Text('거절됨')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      children: const [
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              '상품명',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              '신청자',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              '상태',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              '요청일',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              '작업',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('product_edit_requests')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data == null) {
                          return const Center(
                            child: Text('No edit requests available'),
                          );
                        }

                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return const Center(child: Text('요청이 없습니다.'));
                        }

                        List<ProductEditRequestModel> requests =
                            docs.map((doc) {
                          return ProductEditRequestModel.fromMap(
                            doc.id,
                            doc.data() as Map<String, dynamic>,
                          );
                        }).toList();

                        // Filter based on whether it is a registration (isNewProduct == true)
                        // or a modification (isNewProduct == false or null)
                        requests = requests.where((r) {
                          final isNew = r.isNewProduct == true;
                          return isNew == widget.isNewProductOnly;
                        }).toList();

                        if (_statusFilter != 'all') {
                          requests = requests
                              .where((r) => r.status == _statusFilter)
                              .toList();
                        }

                        requests.sort((a, b) {
                          final aTime = a.requestedAt is Timestamp
                              ? (a.requestedAt as Timestamp)
                              : Timestamp.fromMicrosecondsSinceEpoch(0);
                          final bTime = b.requestedAt is Timestamp
                              ? (b.requestedAt as Timestamp)
                              : Timestamp.fromMicrosecondsSinceEpoch(0);
                          return bTime.compareTo(aTime);
                        });

                        if (requests.isEmpty) {
                          return const Center(
                            child: Text('조건에 맞는 요청이 없습니다.'),
                          );
                        }

                        return ListView.builder(
                          itemCount: requests.length,
                          itemBuilder: (context, index) {
                            final request = requests[index];
                            return _buildEditRequestRow(request);
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
}
