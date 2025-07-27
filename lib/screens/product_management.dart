// screens/product_management.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app_dashboard/models/category_model.dart';
import 'package:ecommerce_app_dashboard/models/delivery_manager_model.dart';
import 'package:ecommerce_app_dashboard/screens/address/address_search_dialog.dart';
import 'package:ecommerce_app_dashboard/services/category_service.dart';
import 'package:ecommerce_app_dashboard/services/delivery_manager_service.dart';
import 'package:ecommerce_app_dashboard/services/kakao_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static const separator = ',';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all separators
    String oldValueText = oldValue.text.replaceAll(separator, '');
    String newValueText = newValue.text.replaceAll(separator, '');

    if (oldValue.text.endsWith(separator) &&
        oldValue.text.length == newValue.text.length + 1) {
      newValueText = newValueText.substring(0, newValueText.length - 1);
    }

    // Only process if the new value is a valid number
    if (double.tryParse(newValueText) == null) {
      return oldValue;
    }

    // Format the number
    final formatter = NumberFormat('#,###.##');
    String newText = formatter.format(double.parse(newValueText));

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class ProductManagementScreen extends StatefulWidget {
  @override
  _ProductManagementScreenState createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final ProductService _productService = ProductService();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final List<Product> _selectedProducts = [];
  Timer? _debounce;
  late final ScrollController _headerScrollController;
  late final ScrollController _bodyScrollController;

  Stream<QuerySnapshot> getProductsStream(String query) {
    if (query.isEmpty) {
      return FirebaseFirestore.instance.collection('products').snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('products')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .snapshots();
    }
  }

  void _selectProduct(Product product) {
    setState(() {
      // Check if not already selected
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

  // 2. Function to deselect a product
  void _deselectProduct(Product product) {
    setState(() {
      // Remove all instances of this product (should be just one)
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '상품 관리',
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
              SizedBox(width: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('상품 추가'),
                onPressed: () => _showAddProductDialog(context),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                    _selectedProducts.length == 1
                        ? () => _showEditProductDialog(
                          context,
                          _selectedProducts.first,
                        )
                        : null, // Disable if not exactly one product selected
                child: Text('수정'),
                style: TextButton.styleFrom(
                  foregroundColor:
                      _selectedProducts.length == 1 ? Colors.blue : Colors.grey,
                ),
              ),
              SizedBox(width: 16),
              TextButton(
                onPressed:
                    _selectedProducts.isNotEmpty
                        ? () => _deleteSelectedProducts()
                        : null, // Disable if no products selected
                child: Text('삭제'),
                style: TextButton.styleFrom(
                  foregroundColor:
                      _selectedProducts.isNotEmpty ? Colors.red : Colors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
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
                  // Table body
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: getProductsStream(_searchQuery),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        // 3. Check for null data
                        if (!snapshot.hasData || snapshot.data == null) {
                          return Center(child: Text('No products available'));
                        }
                        final products = snapshot.data!.docs;

                        if (products.isEmpty) {
                          return Center(child: Text('No products found'));
                        }
                        return SingleChildScrollView(
                          controller: _bodyScrollController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: 1600,

                            child: ListView.builder(
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = Product.fromMap(
                                  products[index].data()
                                      as Map<String, dynamic>,
                                );
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
        child: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildProductRow(Product product) {
    final bool isSelected = _selectedProducts.any(
      (p) => p.product_id == product.product_id,
    );

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : null,

        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child:
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

  void _showAddProductDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();

    String productId = DateTime.now().millisecondsSinceEpoch.toString();
    String productName = '';
    String sellerName = '';
    String category = '';
    // For categories
    List<Category> categories = [];
    bool isLoadingCategories = true;
    bool isLoadingDeliveryManagers = true;
    List<DeliveryManager> deliveryManagers = [];
    double price = 0;
    bool freeShipping = true;
    String instructions = '';
    String description = '';
    int stock = 0;
    int deliveryPrice = 0;
    int supplyPrice = 0;
    double marginRate = 0;
    int shippingFee = 0;
    int estimatedSettlement = 0;
    int baselineTime = 0;
    String meridiem = 'AM';
    String? imgUrl;
    List<String?> imgUrls = [];
    List<PricePoint> pricePoints = [PricePoint(quantity: 1, price: 0)];
    String deliveryManagerId = '';
    Map<String, dynamic> _address = {};
    final TextEditingController _addressController = TextEditingController();

    DateTime? _selectedDate;

    bool _imagesLoading = false;

    XFile? _mainImage;
    List<XFile> _additionalImages = [];
    final ImagePicker _picker = ImagePicker();

    // Preview widgets
    Widget? _mainImagePreview;
    List<Widget> _additionalImagePreviews = [];

    // Actually show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Load categories when dialog opens
            if (isLoadingCategories) {
              CategoryService()
                  .getCategoriesOnce()
                  .then((loadedCategories) {
                    setDialogState(() {
                      categories = loadedCategories;
                      isLoadingCategories = false;
                      // Set default category if available
                      if (categories.isNotEmpty && category.isEmpty) {
                        category = categories.first.id;
                      }
                    });
                  })
                  .catchError((error) {
                    print('Error loading categories: $error');
                    setDialogState(() {
                      isLoadingCategories = false;
                    });
                  });
            }

            // Load delivery managers when dialog opens
            if (isLoadingDeliveryManagers) {
              DeliveryManagerService()
                  .getDeliveryManagersOnce()
                  .then((loadedDeliveryManagers) {
                    setDialogState(() {
                      deliveryManagers = loadedDeliveryManagers;
                      isLoadingDeliveryManagers = false;
                      // Set default delivery manager if available
                      if (deliveryManagers.isNotEmpty &&
                          deliveryManagerId.isEmpty) {
                        deliveryManagerId = deliveryManagers.first.userId;
                      }
                    });
                  })
                  .catchError((error) {
                    print('Error loading delivery managers: $error');
                    setDialogState(() {
                      isLoadingDeliveryManagers = false;
                    });
                  });
            }

            void searchAddress() async {
              final kakaoService = KakaoApiService(
                apiKey: '772742afea4cfac8c58ed62cfa7d1777',
              );

              // Show a search dialog or navigate to a search screen
              final result = await showDialog(
                context: context,
                builder:
                    (context) =>
                        AddressSearchDialog(kakaoService: kakaoService),
              );

              if (result != null) {
                setDialogState(() {
                  _addressController.text = result['address_name'];
                  _address = result;
                });
              }
            }

            Future<void> _selectDate(BuildContext context) async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2025),
                lastDate: DateTime(2050),
              );
              if (picked != null && picked != _selectedDate) {
                setDialogState(() {
                  _selectedDate = picked;
                });
              }
            }

            // Function to pick main image
            Future<void> _pickMainImage() async {
              setDialogState(() => _imagesLoading = true);

              final XFile? image = await _picker.pickImage(
                source: ImageSource.gallery,
              );
              if (image != null) {
                _mainImage = image;

                // Create a preview
                _mainImagePreview = FutureBuilder<Uint8List>(
                  future: image.readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.data != null) {
                      return Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        height: 100,
                      );
                    } else {
                      return Container(
                        height: 100,
                        color: Colors.grey[200],
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                  },
                );

                // Update the dialog UI
                setDialogState(() {
                  _imagesLoading = false;
                });
              }
            }

            // Function to pick additional images
            Future<void> _pickAdditionalImages() async {
              setDialogState(() => _imagesLoading = true);

              final List<XFile>? images = await _picker.pickMultiImage();
              if (images != null && images.isNotEmpty) {
                setDialogState(() {
                  _additionalImages.clear();
                  _additionalImagePreviews.clear();
                  _additionalImages.addAll(images);

                  // Show loading state immediately
                  _additionalImagePreviews.add(
                    Center(child: CircularProgressIndicator()),
                  );
                });

                // Process images and build previews
                final List<Widget> newPreviews = [];
                for (var image in images) {
                  final bytes = await image.readAsBytes();
                  newPreviews.add(
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.memory(
                        bytes,
                        fit: BoxFit.cover,
                        width: 80,
                        height: 80,
                      ),
                    ),
                  );
                }

                // Update with final previews
                setDialogState(() {
                  _additionalImagePreviews = newPreviews;
                  _imagesLoading = false;
                });
              }
            }

            return AlertDialog(
              title: Text('상품 추가'),
              content: Container(
                width: 600,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(labelText: '판매자명'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '판매자명을 입력하세요';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  sellerName = value!;
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(labelText: '상품명'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '상품명을 입력하세요';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  productName = value!;
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child:
                                  isLoadingCategories
                                      ? Center(
                                        child: CircularProgressIndicator(),
                                      )
                                      : DropdownButton<String>(
                                        value:
                                            categories.isNotEmpty
                                                ? category
                                                : null,
                                        items:
                                            categories.map((Category value) {
                                              return DropdownMenuItem<String>(
                                                value: value.id,
                                                child: Text(value.name),
                                              );
                                            }).toList(),
                                        onChanged: (String? newValue) {
                                          setDialogState(() {
                                            category = newValue!;
                                          });
                                        },
                                      ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '수량-가격',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: pricePoints.length,
                                    itemBuilder: (context, index) {
                                      pricePoints[index].price =
                                          ((pricePoints[index].quantity *
                                                  supplyPrice) +
                                              deliveryPrice) /
                                          (1 - (marginRate / 100));
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8.0,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                enabled: index != 0,
                                                initialValue:
                                                    pricePoints[index].quantity
                                                        .toString(),
                                                decoration: InputDecoration(
                                                  labelText: '수량',
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                onChanged: (value) {
                                                  setDialogState(() {
                                                    pricePoints[index]
                                                            .quantity =
                                                        int.tryParse(value) ??
                                                        1;
                                                  });
                                                },
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            Expanded(
                                              child: TextFormField(
                                                enabled: false,
                                                inputFormatters: [
                                                  ThousandsSeparatorInputFormatter(),
                                                ],
                                                controller:
                                                    TextEditingController(
                                                      text: NumberFormat(
                                                        '#,###.##',
                                                      ).format(
                                                        pricePoints[index]
                                                            .price,
                                                      ),
                                                    ),
                                                decoration: InputDecoration(
                                                  labelText: '가격',
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete),
                                              onPressed:
                                                  index == 0
                                                      ? null
                                                      : () {
                                                        setDialogState(() {
                                                          pricePoints.removeAt(
                                                            index,
                                                          );
                                                        });
                                                      },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.add),
                                    label: Text('수량-가격 옵션 추가'),
                                    onPressed: () {
                                      setDialogState(() {
                                        pricePoints.add(
                                          PricePoint(
                                            quantity:
                                                pricePoints.isEmpty
                                                    ? 1
                                                    : pricePoints
                                                            .last
                                                            .quantity +
                                                        1,
                                            price: 0,
                                          ),
                                        );
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        isLoadingDeliveryManagers
                            ? Center(child: CircularProgressIndicator())
                            : Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: deliveryManagerId,
                                    decoration: InputDecoration(
                                      labelText: '판매자',
                                    ),
                                    items:
                                        deliveryManagers.map((dm) {
                                          return DropdownMenuItem(
                                            value: dm.userId,
                                            child: Text(dm.name),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      setDialogState(() {
                                        deliveryManagerId = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(labelText: '재고'),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter
                                      .digitsOnly, // Only allow digits
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '재고를 입력하세요';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  stock = int.parse(value!);
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        labelText: '주문 마감 시간',
                                        hintText: '1-12 사이 입력',
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter
                                            .digitsOnly, // Only allow digits
                                        LengthLimitingTextInputFormatter(
                                          2,
                                        ), // Max 2 characters
                                      ],
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return '시간을 입력하세요';
                                        }

                                        final number = int.tryParse(value);
                                        if (number == null) {
                                          return '유효한 숫자를 입력하세요';
                                        }

                                        if (number < 1 || number > 12) {
                                          return '1-12 사이의 숫자를 입력하세요';
                                        }

                                        return null;
                                      },
                                      onSaved: (value) {
                                        baselineTime = int.parse(value!);
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  DropdownButton<String>(
                                    value: meridiem,
                                    items:
                                        ['AM', 'PM'].map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                    onChanged: (String? newValue) {
                                      setDialogState(() {
                                        meridiem = newValue!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Supply Price',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter
                                      .digitsOnly, // Only allow digits
                                  ThousandsSeparatorInputFormatter(), // Use it here
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Supply Price를 입력하세요';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setDialogState(() {
                                    supplyPrice = int.parse(
                                      value.replaceAll(',', ''),
                                    );
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 16),

                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Delivery Price',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter
                                      .digitsOnly, // Only allow digits
                                  ThousandsSeparatorInputFormatter(), // Use it here
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Delivery Price를 입력하세요';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setDialogState(() {
                                    deliveryPrice = int.parse(
                                      value.replaceAll(',', ''),
                                    );
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText:
                                      'Additional Shipping Fee for remote',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter
                                      .digitsOnly, // Only allow digits
                                  ThousandsSeparatorInputFormatter(),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Additional Shipping Fee for remote를 입력하세요';
                                  }

                                  final number = int.tryParse(
                                    value.replaceAll(',', ''),
                                  );
                                  if (number == null) {
                                    return '유효한 숫자를 입력하세요';
                                  }

                                  return null;
                                },
                                onSaved: (value) {
                                  shippingFee = int.parse(
                                    value!.replaceAll(',', ''),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Margin Rate (%)',
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Margin Rate를 입력하세요';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setDialogState(() {
                                    marginRate = double.parse(value);
                                  });
                                },
                              ),
                            ),
                            /*  SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Estimated Settlement',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter
                                      .digitsOnly, // Only allow digits
                                  ThousandsSeparatorInputFormatter(),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Estimated Settlement를 입력하세요';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  estimatedSettlement = int.parse(
                                    value!.replaceAll(',', ''),
                                  );
                                },
                              ),
                            ), */
                          ],
                        ),
                        /* SizedBox(height: 16),
                        Flexible(
                          child: ListTile(
                            title: Text(
                              _selectedDate == null
                                  ? 'No date selected'
                                  : 'Selected: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                            ),
                            trailing: Icon(Icons.calendar_today),
                            onTap: () => _selectDate(context),
                          ),
                        ), */
                        TextFormField(
                          decoration: InputDecoration(labelText: '상품 설명'),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '설명을 입력하세요';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            description = value!;
                          },
                        ),
                        SizedBox(height: 24),
                        TextFormField(
                          decoration: InputDecoration(labelText: '보관법 및 소비기한'),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '설명을 입력하세요';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            instructions = value!;
                          },
                        ),
                        SizedBox(height: 24),
                        TextFormField(
                          controller: _addressController,
                          readOnly: true,
                          onTap: searchAddress,
                          decoration: InputDecoration(
                            labelText: 'Administrative Region',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Administrative Region can not be empty';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('메인 이미지'),
                                  SizedBox(height: 8),
                                  InkWell(
                                    onTap: _pickMainImage,
                                    child: Container(
                                      height: 100,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child:
                                          _mainImagePreview != null
                                              ? _mainImagePreview
                                              : Center(
                                                child: Icon(
                                                  Icons.add_photo_alternate,
                                                  size: 40,
                                                ),
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('추가 이미지'),
                                  SizedBox(height: 8),
                                  InkWell(
                                    onTap: _pickAdditionalImages,
                                    child: Container(
                                      height: 100,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child:
                                          _additionalImagePreviews.isNotEmpty
                                              ? ListView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                children:
                                                    _additionalImagePreviews,
                                              )
                                              : Center(
                                                child: Icon(
                                                  Icons.add_photo_alternate,
                                                  size: 40,
                                                ),
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: Text('취소'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('저장'),
                  onPressed:
                      _imagesLoading
                          ? null
                          : () async {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();

                              // Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    content: Row(
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(width: 16),
                                        Text("상품 등록중..."),
                                      ],
                                    ),
                                  );
                                },
                              );

                              try {
                                // Upload main image if selected
                                if (_mainImage != null) {
                                  imgUrl = await _productService
                                      .uploadImageToFirebaseStorage(
                                        _mainImage!,
                                      );
                                }

                                // Upload additional images if selected
                                if (_additionalImages.isNotEmpty) {
                                  imgUrls = await _productService
                                      .uploadProductImages(_additionalImages);
                                }

                                // Create product object
                                Product newProduct = Product(
                                  product_id: productId,
                                  productName: productName,
                                  sellerName: sellerName,
                                  category: category,
                                  price: price,
                                  supplyPrice: supplyPrice,
                                  pricePoints: pricePoints,
                                  freeShipping: freeShipping,
                                  instructions: instructions,
                                  description: description,
                                  stock: stock,
                                  baselineTime: baselineTime,
                                  meridiem: meridiem,
                                  imgUrl: imgUrl,
                                  imgUrls: imgUrls,
                                  marginRate: marginRate,
                                  deliveryManagerId: deliveryManagerId,
                                  address: _address,
                                  /*                                   estimatedSettlementDate: DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(_selectedDate!),
                                  estimatedSettlement: estimatedSettlement, */
                                  deliveryPrice: deliveryPrice,
                                  shippingFee: shippingFee,
                                );

                                // Save to Firestore
                                await _productService.addProduct(newProduct);

                                // Close loading dialog
                                Navigator.of(context).pop();

                                // Close form dialog
                                Navigator.of(context).pop();

                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('상품이 성공적으로 등록되었습니다')),
                                );
                              } catch (e) {
                                // Close loading dialog
                                Navigator.of(context).pop();

                                // Show error message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                  ),
                                );
                              }
                            }
                          },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Edit Product Dialog
  void _showEditProductDialog(BuildContext context, Product product) {
    final _formKey = GlobalKey<FormState>();

    // Initialize with existing product data
    String productId = product.product_id;
    String productName = product.productName;
    String sellerName = product.sellerName;
    String category = product.category;
    // For categories
    List<Category> categories = [];
    bool isLoadingCategories = true;
    bool isLoadingDeliveryManagers = true;
    List<DeliveryManager> deliveryManagers = [];
    double price = product.price;
    List<PricePoint> pricePoints = product.pricePoints;
    String? deliveryManagerId = product.deliveryManagerId;
    bool freeShipping = product.freeShipping;
    String instructions = product.instructions;
    String description = product.description;
    int stock = product.stock;
    int baselineTime = product.baselineTime;
    String meridiem = product.meridiem;
    String? imgUrl = product.imgUrl;
    List<String?> imgUrls = List.from(product.imgUrls);
    int deliveryPrice = product.deliveryPrice ?? 0;
    int supplyPrice = product.supplyPrice ?? 0;
    double marginRate = product.marginRate ?? 0;
    int shippingFee = product.shippingFee ?? 0;
    Map<String, dynamic> _address = product.address ?? {};
    final TextEditingController _addressController = TextEditingController(
      text: product.address?['address_name'] ?? '',
    );
    /*     int estimatedSettlement = product.estimatedSettlement ?? 0;
    DateTime? _selectedDate =
        product.estimatedSettlementDate != ''
            ? DateTime.parse(product.estimatedSettlementDate!)
            : null; */

    bool _imagesLoading = false;

    XFile? _mainImage;
    List<XFile> _additionalImages = [];
    final ImagePicker _picker = ImagePicker();

    // Preview widgets
    Widget? _mainImagePreview;
    List<Widget> _additionalImagePreviews = [];

    // Initialize with existing image
    if (imgUrl != null) {
      _mainImagePreview = Image.network(imgUrl, fit: BoxFit.cover, height: 100);
    }

    // Initialize with existing additional images
    for (var url in imgUrls) {
      if (url != null) {
        _additionalImagePreviews.add(
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Image.network(url, fit: BoxFit.cover, width: 80, height: 80),
          ),
        );
      }
    }

    // Actually show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Load categories when dialog opens
            if (isLoadingCategories) {
              CategoryService()
                  .getCategoriesOnce()
                  .then((loadedCategories) {
                    setDialogState(() {
                      categories = loadedCategories;
                      isLoadingCategories = false;
                      // Set default category if available
                      if (categories.isNotEmpty && category.isEmpty) {
                        category = categories.first.id;
                      }
                    });
                  })
                  .catchError((error) {
                    print('Error loading categories: $error');
                    setDialogState(() {
                      isLoadingCategories = false;
                    });
                  });
            }

            // Load delivery managers when dialog opens
            if (isLoadingDeliveryManagers) {
              DeliveryManagerService()
                  .getDeliveryManagersOnce()
                  .then((loadedDeliveryManagers) {
                    setDialogState(() {
                      deliveryManagers = loadedDeliveryManagers;
                      isLoadingDeliveryManagers = false;
                      // Set default delivery manager if available
                      if (deliveryManagers.isNotEmpty &&
                          deliveryManagerId == null) {
                        deliveryManagerId = deliveryManagers.first.userId;
                      }
                    });
                  })
                  .catchError((error) {
                    print('Error loading delivery managers: $error');
                    setDialogState(() {
                      isLoadingDeliveryManagers = false;
                    });
                  });
            }
            void searchAddress() async {
              final kakaoService = KakaoApiService(
                apiKey: '772742afea4cfac8c58ed62cfa7d1777',
              );

              // Show a search dialog or navigate to a search screen
              final result = await showDialog(
                context: context,
                builder:
                    (context) =>
                        AddressSearchDialog(kakaoService: kakaoService),
              );

              if (result != null) {
                setDialogState(() {
                  _addressController.text = result['address_name'];
                  _address = result;
                });
              }
            }

            // Function to pick main image
            Future<void> _pickMainImage() async {
              setDialogState(() => _imagesLoading = true);

              final XFile? image = await _picker.pickImage(
                source: ImageSource.gallery,
              );
              if (image != null) {
                _mainImage = image;

                // Create a preview
                _mainImagePreview = FutureBuilder<Uint8List>(
                  future: image.readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.data != null) {
                      return Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        height: 100,
                      );
                    } else {
                      return Container(
                        height: 100,
                        color: Colors.grey[200],
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                  },
                );

                // Update the dialog UI
                setDialogState(() {
                  _imagesLoading = false;
                });
              }
            }

            /*             Future<void> _selectDate(BuildContext context) async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2025),
                lastDate: DateTime(2050),
              );
              if (picked != null && picked != _selectedDate) {
                setDialogState(() {
                  _selectedDate = picked;
                });
              }
            } */

            // Function to pick additional images
            Future<void> _pickAdditionalImages() async {
              setDialogState(() => _imagesLoading = true);

              final List<XFile>? images = await _picker.pickMultiImage();
              if (images != null && images.isNotEmpty) {
                setDialogState(() {
                  _additionalImages.clear();
                  _additionalImagePreviews.clear();
                  _additionalImages.addAll(images);

                  // Show loading state immediately
                  _additionalImagePreviews.add(
                    Center(child: CircularProgressIndicator()),
                  );
                });

                // Process images and build previews
                final List<Widget> newPreviews = [];
                for (var image in images) {
                  final bytes = await image.readAsBytes();
                  newPreviews.add(
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.memory(
                        bytes,
                        fit: BoxFit.cover,
                        width: 80,
                        height: 80,
                      ),
                    ),
                  );
                }

                // Update with final previews
                setDialogState(() {
                  _additionalImagePreviews = newPreviews;
                  _imagesLoading = false;
                });
              }
            }

            return AlertDialog(
              title: Text('Edit Product'),
              content: Container(
                width: 600,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: sellerName,
                                decoration: InputDecoration(labelText: '판매자명'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '판매자명을 입력하세요';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  sellerName = value!;
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: productName,
                                decoration: InputDecoration(labelText: '상품명'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '상품명을 입력하세요';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  productName = value!;
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child:
                                  isLoadingCategories
                                      ? Center(
                                        child: CircularProgressIndicator(),
                                      )
                                      : DropdownButton<String>(
                                        value: category,

                                        items:
                                            categories.map((Category value) {
                                              return DropdownMenuItem<String>(
                                                value: value.id,
                                                child: Text(value.name),
                                              );
                                            }).toList(),

                                        onChanged: (String? newValue) {
                                          setDialogState(() {
                                            category = newValue!;
                                          });
                                        },
                                      ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '수량-가격',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: pricePoints.length,
                                    itemBuilder: (context, index) {
                                      pricePoints[index].price =
                                          ((pricePoints[index].quantity *
                                                  supplyPrice) +
                                              deliveryPrice) /
                                          (1 - (marginRate / 100));

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8.0,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                enabled: index != 0,
                                                initialValue:
                                                    pricePoints[index].quantity
                                                        .toString(),
                                                decoration: InputDecoration(
                                                  labelText: '수량',
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                onChanged: (value) {
                                                  setDialogState(() {
                                                    pricePoints[index]
                                                            .quantity =
                                                        int.tryParse(value) ??
                                                        1;
                                                  });
                                                },
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            Expanded(
                                              child: TextFormField(
                                                enabled: false,
                                                inputFormatters: [
                                                  ThousandsSeparatorInputFormatter(),
                                                ],
                                                controller:
                                                    TextEditingController(
                                                      text: NumberFormat(
                                                        '#,###.##',
                                                      ).format(
                                                        pricePoints[index]
                                                            .price,
                                                      ),
                                                    ),
                                                decoration: InputDecoration(
                                                  labelText: '가격',
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete),
                                              onPressed:
                                                  index == 0
                                                      ? null
                                                      : () {
                                                        setDialogState(() {
                                                          pricePoints.removeAt(
                                                            index,
                                                          );
                                                        });
                                                      },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.add),
                                    label: Text('수량-가격 옵션 추가'),
                                    onPressed: () {
                                      setDialogState(() {
                                        pricePoints.add(
                                          PricePoint(
                                            quantity:
                                                pricePoints.isEmpty
                                                    ? 1
                                                    : pricePoints
                                                            .last
                                                            .quantity +
                                                        1,
                                            price: 0,
                                          ),
                                        );
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        isLoadingDeliveryManagers
                            ? Center(child: CircularProgressIndicator())
                            : Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: deliveryManagerId,
                                    decoration: InputDecoration(
                                      labelText: '판매자',
                                    ),
                                    items:
                                        deliveryManagers.map((dm) {
                                          return DropdownMenuItem(
                                            value: dm.userId,
                                            child: Text(dm.name),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      setDialogState(() {
                                        deliveryManagerId = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: stock.toString(),
                                decoration: InputDecoration(labelText: '재고'),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '재고를 입력하세요';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  stock = int.parse(value!);
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: baselineTime.toString(),
                                      decoration: InputDecoration(
                                        labelText: '주문 마감 시간',
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return '기준 시간을 입력하세요';
                                        }
                                        return null;
                                      },
                                      onSaved: (value) {
                                        baselineTime = int.parse(value!);
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  DropdownButton<String>(
                                    value: meridiem,
                                    items:
                                        ['AM', 'PM'].map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                    onChanged: (String? newValue) {
                                      setDialogState(() {
                                        meridiem = newValue!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: deliveryPrice.toString(),
                                decoration: InputDecoration(
                                  labelText: 'Supply Price',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter
                                      .digitsOnly, // Only allow digits
                                  ThousandsSeparatorInputFormatter(),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Supply Price를 입력하세요';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setDialogState(() {
                                    supplyPrice = int.parse(
                                      value.replaceAll(',', ''),
                                    );
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: deliveryPrice.toString(),
                                decoration: InputDecoration(
                                  labelText: 'Delivery Price',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter
                                      .digitsOnly, // Only allow digits
                                  ThousandsSeparatorInputFormatter(),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Delivery Price를 입력하세요';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setDialogState(() {
                                    deliveryPrice = int.parse(
                                      value!.replaceAll(',', ''),
                                    );
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: shippingFee.toString(),
                                decoration: InputDecoration(
                                  labelText:
                                      'Additional Shipping Fee for remote',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter
                                      .digitsOnly, // Only allow digits
                                  ThousandsSeparatorInputFormatter(),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Additional Shipping Fee for remote를 입력하세요';
                                  }

                                  final number = int.tryParse(
                                    value.replaceAll(',', ''),
                                  );
                                  if (number == null) {
                                    return '유효한 숫자를 입력하세요';
                                  }

                                  return null;
                                },
                                onSaved: (value) {
                                  shippingFee = int.parse(
                                    value!.replaceAll(',', ''),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: marginRate.toString(),
                                decoration: InputDecoration(
                                  labelText: 'Margin Rate (%)',
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Margin Rate를 입력하세요';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setDialogState(() {
                                    marginRate = double.parse(value);
                                  });
                                },
                              ),
                            ),
                            /* SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: estimatedSettlement.toString(),
                                decoration: InputDecoration(
                                  labelText: 'Estimated Settlement',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter
                                      .digitsOnly, // Only allow digits
                                  ThousandsSeparatorInputFormatter(),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Estimated Settlement를 입력하세요';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  estimatedSettlement = int.parse(
                                    value!.replaceAll(',', ''),
                                  );
                                },
                              ),
                            ), */
                          ],
                        ),
                        /*                         SizedBox(height: 16),
                        Flexible(
                          child: ListTile(
                            title: Text(
                              _selectedDate == null
                                  ? 'No date selected'
                                  : 'Selected: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                            ),
                            trailing: Icon(Icons.calendar_today),
                            onTap: () => _selectDate(context),
                          ),
                        ), */
                        SizedBox(height: 16),
                        TextFormField(
                          initialValue: description,
                          decoration: InputDecoration(labelText: '상품 설명'),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '설명을 입력하세요';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            description = value!;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          initialValue: instructions,
                          decoration: InputDecoration(labelText: '보관법 및 소비기한'),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '설명을 입력하세요';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            instructions = value!;
                          },
                        ),
                        SizedBox(height: 24),
                        TextFormField(
                          controller: _addressController,
                          readOnly: true,
                          onTap: searchAddress,
                          decoration: InputDecoration(
                            labelText: 'Administrative Region',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Administrative Region can not be empty';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('메인 이미지'),
                                  SizedBox(height: 8),
                                  InkWell(
                                    onTap: _pickMainImage,
                                    child: Container(
                                      height: 100,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child:
                                          _mainImagePreview != null
                                              ? _mainImagePreview
                                              : Center(
                                                child: Icon(
                                                  Icons.add_photo_alternate,
                                                  size: 40,
                                                ),
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('추가 이미지'),
                                  SizedBox(height: 8),
                                  InkWell(
                                    onTap: _pickAdditionalImages,
                                    child: Container(
                                      height: 100,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child:
                                          _additionalImagePreviews.isNotEmpty
                                              ? ReorderableListView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                onReorder: (
                                                  oldIndex,
                                                  newIndex,
                                                ) {
                                                  setDialogState(() {
                                                    if (newIndex > oldIndex) {
                                                      newIndex -= 1;
                                                    }
                                                    final item =
                                                        _additionalImagePreviews
                                                            .removeAt(oldIndex);
                                                    _additionalImagePreviews
                                                        .insert(newIndex, item);
                                                  });
                                                },
                                                children:
                                                    _additionalImagePreviews.asMap().entries.map((
                                                      entry,
                                                    ) {
                                                      int index = entry.key;
                                                      Widget imageWidget =
                                                          entry.value;

                                                      return Stack(
                                                        key: ValueKey(
                                                          index,
                                                        ), // Required for ReorderableListView
                                                        children: [
                                                          imageWidget,
                                                          // Delete button
                                                          Positioned(
                                                            top: 0,
                                                            right: 0,
                                                            child: IconButton(
                                                              icon: Icon(
                                                                Icons.close,
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                              onPressed: () {
                                                                setDialogState(() {
                                                                  _additionalImagePreviews
                                                                      .removeAt(
                                                                        index,
                                                                      );
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    }).toList(),
                                              )
                                              : Center(
                                                child: Icon(
                                                  Icons.add_photo_alternate,
                                                  size: 40,
                                                ),
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: Text('취소'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('저장'),
                  onPressed:
                      _imagesLoading
                          ? null
                          : () async {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();

                              // Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    content: Row(
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(width: 16),
                                        Text("상품 등록중..."),
                                      ],
                                    ),
                                  );
                                },
                              );

                              try {
                                // Upload main image if a new one was selected
                                if (_mainImage != null) {
                                  imgUrl = await _productService
                                      .uploadImageToFirebaseStorage(
                                        _mainImage!,
                                      );
                                }

                                // Upload additional images if new ones were selected
                                if (_additionalImages.isNotEmpty) {
                                  List<String?> newImgUrls =
                                      await _productService.uploadProductImages(
                                        _additionalImages,
                                      );

                                  // Combine existing and new image URLs
                                  // This approach keeps existing images and adds new ones
                                  imgUrls.addAll(newImgUrls);
                                }

                                // Create updated product object
                                Product updatedProduct = Product(
                                  product_id: productId,
                                  productName: productName,
                                  sellerName: sellerName,
                                  supplyPrice: supplyPrice,
                                  category: category,
                                  price: price,
                                  pricePoints: pricePoints,
                                  freeShipping: freeShipping,
                                  instructions: instructions,
                                  description: description,
                                  stock: stock,
                                  baselineTime: baselineTime,
                                  meridiem: meridiem,
                                  imgUrl: imgUrl,
                                  imgUrls: imgUrls,
                                  marginRate: marginRate,
                                  deliveryManagerId: deliveryManagerId,
                                  address: _address,
                                  /*                                   estimatedSettlementDate:
                                      _selectedDate != null
                                          ? DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(_selectedDate!)
                                          : null,
                                  estimatedSettlement: estimatedSettlement, */
                                  deliveryPrice: deliveryPrice,
                                  shippingFee: shippingFee,
                                );

                                // Update in Firestore
                                await _productService.updateProduct(
                                  updatedProduct,
                                );

                                // Close loading dialog
                                Navigator.of(context).pop();

                                // Close form dialog
                                Navigator.of(context).pop();

                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('상품 수정이 성공적으로 완료되었습니다'),
                                  ),
                                );

                                // Clear selection
                                _clearSelections();
                              } catch (e) {
                                // Close loading dialog
                                Navigator.of(context).pop();

                                // Show error message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                  ),
                                );
                              }
                            }
                          },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Delete Product confirmation
  void _deleteSelectedProducts() {
    if (_selectedProducts.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('삭제 확인'),
          content: Text(
            _selectedProducts.length == 1
                ? '삭제하시겠습니까?'
                : '${_selectedProducts.length}개의 상품을 삭제하시겠습니까?',
          ),
          actions: [
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('삭제'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text("상품 삭제중..."),
                        ],
                      ),
                    );
                  },
                );

                try {
                  // Delete each selected product
                  for (Product product in _selectedProducts) {
                    await _productService.deleteProduct(product.product_id);
                  }

                  // Clear selections
                  _clearSelections();

                  // Close loading dialog
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();

                  // Show success message
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('상품을 성공적으로 삭제했습니다')));
                } catch (e) {
                  // Close loading dialog
                  Navigator.of(context).pop();

                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
