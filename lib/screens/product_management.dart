import 'dart:async';

import 'package:ecommerce_app_dashboard/models/product_model.dart';
import 'package:ecommerce_app_dashboard/screens/product_form_dialog.dart';
import 'package:ecommerce_app_dashboard/services/product_service.dart';
import 'package:ecommerce_app_dashboard/providers/product_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ProductManagementScreen extends ConsumerStatefulWidget {
  const ProductManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends ConsumerState<ProductManagementScreen> {
  final ProductService _productService = ProductService();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final List<Product> _selectedProducts = [];
  Timer? _debounce;
  late final ScrollController _headerScrollController;
  late final ScrollController _bodyScrollController;

  void _selectProduct(Product product) {
    setState(() {
      if (!_selectedProducts.any((p) => p.product_id == product.product_id)) {
        _selectedProducts.add(product);
      }
    });
  }

  void _clearSelections() {
    setState(() {
      _selectedProducts.clear();
    });
  }

  void _deselectProduct(Product product) {
    setState(() {
      _selectedProducts.removeWhere((p) => p.product_id == product.product_id);
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

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const ProductFormDialog();
      },
    ).then((_) {
      _clearSelections();
    });
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ProductFormDialog(product: product);
      },
    ).then((_) {
      _clearSelections();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider(_searchQuery));

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '상품 관리',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '검색',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('상품 추가'),
                onPressed: () => _showAddProductDialog(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _selectedProducts.length == 1
                    ? () => _showEditProductDialog(
                          context,
                          _selectedProducts.first,
                        )
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor:
                      _selectedProducts.length == 1 ? Colors.black : Colors.grey,
                ),
                child: const Text('수정'),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: _selectedProducts.isNotEmpty
                    ? () => _deleteSelectedProducts()
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor:
                      _selectedProducts.isNotEmpty ? Colors.red : Colors.grey,
                ),
                child: const Text('삭제'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
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
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildTableHeader('이미지', 1),
                          _buildTableHeader('상품명', 2),
                          _buildTableHeader('상품 설명', 2),
                          _buildTableHeader('재고', 1),
                          _buildTableHeader('기준 시간', 1),
                          _buildTableHeader('판매자', 1),
                          _buildTableHeader('가격', 1),
                          _buildTableHeader('선택', 1),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: productsAsync.when(
                      loading: () => const Center(child: SizedBox.shrink()),
                      error: (err, stack) => Center(
                        child: Text('Error: $err'),
                      ),
                      data: (products) {
                        if (products.isEmpty) {
                          return const Center(child: Text('No products found'));
                        }
                        return SingleChildScrollView(
                          controller: _bodyScrollController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: 1600,
                            child: ListView.builder(
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return _buildProductRow(product);
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

  Widget _buildTableHeader(String title, int flex) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildProductRow(Product product) {
    final bool isSelected = _selectedProducts.any(
      (p) => p.product_id == product.product_id,
    );

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey.shade100 : null,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: product.imgUrl != null
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
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(product.productName),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(product.instructions),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(product.stock.toString()),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('${product.baselineTime} ${product.meridiem}'),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(product.sellerName),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ...product.pricePoints.map(
                    (pp) => Text(
                      '${pp.quantity} qty = \$${NumberFormat('#,###').format(pp.price)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    if (isSelected) {
                      _deselectProduct(product);
                    } else {
                      _selectProduct(product);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _deleteSelectedProducts() {
    if (_selectedProducts.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('삭제 확인'),
          content: Text(
            _selectedProducts.length == 1
                ? '삭제하시겠습니까?'
                : '${_selectedProducts.length}개의 상품을 삭제하시겠습니까?',
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const AlertDialog(
                      content: Row(
                        children: [
                          SizedBox.shrink(),
                          SizedBox(width: 16),
                          Text("상품 삭제중..."),
                        ],
                      ),
                    );
                  },
                );

                try {
                  for (Product product in _selectedProducts) {
                    await _productService.deleteProduct(product.product_id);
                  }

                  _clearSelections();

                  Navigator.of(context).pop();
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('상품을 성공적으로 삭제했습니다')),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }
}
