import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app_dashboard/models/category_model.dart';
import 'package:ecommerce_app_dashboard/models/delivery_manager_model.dart';
import 'package:ecommerce_app_dashboard/screens/address/address_search_dialog.dart';
import 'package:ecommerce_app_dashboard/services/kakao_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../providers/product_providers.dart';

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

    String oldValueText = oldValue.text.replaceAll(separator, '');
    String newValueText = newValue.text.replaceAll(separator, '');

    if (oldValue.text.endsWith(separator) &&
        oldValue.text.length == newValue.text.length + 1) {
      newValueText = newValueText.substring(0, newValueText.length - 1);
    }

    if (double.tryParse(newValueText) == null) {
      return oldValue;
    }

    final formatter = NumberFormat('#,###.##');
    String newText = formatter.format(double.parse(newValueText));

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class ProductFormDialog extends ConsumerStatefulWidget {
  final Product? product;

  const ProductFormDialog({Key? key, this.product}) : super(key: key);

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();

  late String productId;
  late String productName;
  late String sellerName;
  late String category;
  late String memo;
  late List<String> categoryList;
  late double price;
  late bool freeShipping;
  late String instructions;
  late String description;
  late int stock;
  late int deliveryPrice;
  late int supplyPrice;
  late double marginRate;
  late int shippingFee;
  late int baselineTime;
  late String meridiem;
  late String arrivalDate;
  String? imgUrl;
  List<String?> imgUrls = [];
  late List<PricePoint> pricePoints;
  String? deliveryManagerId;
  Map<String, dynamic>? _address;
  final TextEditingController _addressController = TextEditingController();

  bool _imagesLoading = false;
  XFile? _mainImage;
  List<XFile> _additionalImages = [];
  final ImagePicker _picker = ImagePicker();

  Widget? _mainImagePreview;
  List<Widget> _additionalImagePreviews = [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      productId = p.product_id;
      productName = p.productName;
      sellerName = p.sellerName;
      category = p.category;
      memo = p.memo;
      categoryList = List<String>.from(p.categoryList);
      price = p.price;
      freeShipping = p.freeShipping;
      instructions = p.instructions;
      description = p.description;
      stock = p.stock;
      deliveryPrice = p.deliveryPrice ?? 0;
      supplyPrice = p.supplyPrice;
      marginRate = p.marginRate ?? 0.0;
      shippingFee = p.shippingFee ?? 0;
      baselineTime = p.baselineTime;
      meridiem = p.meridiem;
      arrivalDate = p.arrivalDate ?? '';
      imgUrl = p.imgUrl;
      imgUrls = List<String?>.from(p.imgUrls);
      pricePoints = List<PricePoint>.from(p.pricePoints);
      deliveryManagerId = p.deliveryManagerId;
      _address = p.address;
      if (_address != null && _address!['address_name'] != null) {
        _addressController.text = _address!['address_name'];
      }

      if (imgUrl != null) {
        _mainImagePreview = Image.network(imgUrl!, fit: BoxFit.cover, height: 100);
      }
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
    } else {
      productId = DateTime.now().millisecondsSinceEpoch.toString();
      productName = '';
      sellerName = '';
      category = '';
      memo = '';
      categoryList = [];
      price = 0;
      freeShipping = true;
      instructions = '';
      description = '';
      stock = 0;
      deliveryPrice = 0;
      supplyPrice = 0;
      marginRate = 0;
      shippingFee = 0;
      baselineTime = 0;
      meridiem = 'AM';
      arrivalDate = '';
      pricePoints = [PricePoint(quantity: 1, price: 0)];
      deliveryManagerId = '';
    }
  }

  void searchAddress() async {
    final kakaoService = KakaoApiService(
      apiKey: '772742afea4cfac8c58ed62cfa7d1777',
    );

    final result = await showDialog(
      context: context,
      builder: (context) => AddressSearchDialog(kakaoService: kakaoService),
    );

    if (result != null) {
      setState(() {
        _addressController.text = result['address_name'];
        _address = result;
      });
    }
  }

  Future<void> _pickMainImage() async {
    setState(() => _imagesLoading = true);

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _mainImage = image;
      final bytes = await image.readAsBytes();
      setState(() {
        _mainImagePreview = Image.memory(bytes, fit: BoxFit.cover, height: 100);
        _imagesLoading = false;
      });
    } else {
      setState(() => _imagesLoading = false);
    }
  }

  Future<void> _pickAdditionalImages() async {
    setState(() => _imagesLoading = true);

    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      _additionalImages.clear();
      _additionalImagePreviews.clear();
      _additionalImages.addAll(images);

      final List<Widget> newPreviews = [];
      for (var image in images) {
        final bytes = await image.readAsBytes();
        newPreviews.add(
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Image.memory(bytes, fit: BoxFit.cover, width: 80, height: 80),
          ),
        );
      }

      setState(() {
        _additionalImagePreviews = newPreviews;
        _imagesLoading = false;
      });
    } else {
      setState(() => _imagesLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsyncValue = ref.watch(categoriesFutureProvider);
    final deliveryManagersAsyncValue = ref.watch(deliveryManagersFutureProvider);

    return categoriesAsyncValue.when(
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => AlertDialog(
        title: const Text('Error'),
        content: Text('Failed to load categories: $err'),
      ),
      data: (categories) => deliveryManagersAsyncValue.when(
        loading: () => const SizedBox.shrink(),
        error: (err, stack) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to load delivery managers: $err'),
        ),
        data: (deliveryManagers) {
          // Resolve category and deliveryManagerId safely in build phase!
          final hasValidDM = deliveryManagers.any((dm) => dm.userId == deliveryManagerId);
          if (deliveryManagers.isNotEmpty && (deliveryManagerId == null || deliveryManagerId!.isEmpty || !hasValidDM)) {
            deliveryManagerId = deliveryManagers.first.userId;
          }
          final hasValidCategory = categories.any((cat) => cat.id == category);
          if (categories.isNotEmpty && (category.isEmpty || !hasValidCategory)) {
            category = categories.first.id;
          }

          return AlertDialog(
            title: Text(widget.product != null ? '상품 수정' : '상품 추가'),
            content: SizedBox(
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
                              decoration: const InputDecoration(labelText: '판매자명'),
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: productName,
                              decoration: const InputDecoration(labelText: '상품명'),
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              children: categories.map((cat) {
                                final isSelected = categoryList.contains(cat.id);
                                return FilterChip(
                                  label: Text(cat.name),
                                  selected: isSelected,
                                  onSelected: (bool selected) {
                                    setState(() {
                                      if (selected) {
                                        categoryList.add(cat.id);
                                      } else {
                                        categoryList.remove(cat.id);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '수량-가격',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: pricePoints.length,
                                  itemBuilder: (context, index) {
                                    pricePoints[index].price =
                                        ((pricePoints[index].quantity * supplyPrice) + deliveryPrice) /
                                        (1 - (marginRate / 100));
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              enabled: index != 0,
                                              initialValue: pricePoints[index].quantity.toString(),
                                              decoration: InputDecoration(
                                                labelText: '${index + 1}구간 수량',
                                              ),
                                              keyboardType: TextInputType.number,
                                              onChanged: (val) {
                                                if (val.isNotEmpty) {
                                                  setState(() {
                                                    pricePoints[index].quantity = int.parse(val);
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextFormField(
                                              key: ValueKey('price_${pricePoints[index].price}'),
                                              enabled: false,
                                              initialValue: NumberFormat('#,###').format(pricePoints[index].price),
                                              decoration: InputDecoration(
                                                labelText: '${index + 1}구간 판매가',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (pricePoints.length > 1)
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            pricePoints.removeLast();
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        child: const Text('구간 삭제'),
                                      ),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          pricePoints.add(
                                            PricePoint(
                                              quantity: pricePoints.isEmpty ? 1 : pricePoints.last.quantity + 1,
                                              price: 0,
                                            ),
                                          );
                                        });
                                      },
                                      child: const Text('구간 추가'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: deliveryManagerId,
                              decoration: const InputDecoration(labelText: '판매자'),
                              items: deliveryManagers.map((dm) {
                                return DropdownMenuItem(
                                  value: dm.userId,
                                  child: Text(dm.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  deliveryManagerId = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: stock.toString(),
                              decoration: const InputDecoration(labelText: '재고'),
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: baselineTime.toString(),
                                    decoration: const InputDecoration(labelText: '주문 마감 시간'),
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
                                const SizedBox(width: 8),
                                DropdownButton<String>(
                                  value: meridiem,
                                  items: ['AM', 'PM'].map((String val) {
                                    return DropdownMenuItem<String>(
                                      value: val,
                                      child: Text(val),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
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
                              initialValue: supplyPrice.toString(),
                              decoration: const InputDecoration(labelText: 'Supply Price'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                ThousandsSeparatorInputFormatter(),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Supply Price를 입력하세요';
                                }
                                return null;
                              },
                              onChanged: (val) {
                                setState(() {
                                  supplyPrice = int.parse(val.replaceAll(',', ''));
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: deliveryPrice.toString(),
                              decoration: const InputDecoration(labelText: 'Delivery Price'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                ThousandsSeparatorInputFormatter(),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Delivery Price를 입력하세요';
                                }
                                return null;
                              },
                              onChanged: (val) {
                                setState(() {
                                  deliveryPrice = int.parse(val.replaceAll(',', ''));
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: shippingFee.toString(),
                              decoration: const InputDecoration(labelText: 'Additional Shipping Fee for remote'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                ThousandsSeparatorInputFormatter(),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Additional Shipping Fee for remote를 입력하세요';
                                }
                                final number = int.tryParse(value.replaceAll(',', ''));
                                if (number == null) return '유효한 숫자를 입력하세요';
                                return null;
                              },
                              onSaved: (value) {
                                shippingFee = int.parse(value!.replaceAll(',', ''));
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: marginRate.toString(),
                              decoration: const InputDecoration(labelText: 'Margin Rate (%)'),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Margin Rate를 입력하세요';
                                }
                                return null;
                              },
                              onChanged: (val) {
                                setState(() {
                                  marginRate = double.tryParse(val) ?? 0.0;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: arrivalDate,
                              decoration: const InputDecoration(labelText: '배송일'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '배송일을 입력하세요';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                arrivalDate = value!;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: description,
                        decoration: const InputDecoration(labelText: '상품 설명'),
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
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: instructions,
                        decoration: const InputDecoration(labelText: '보관법 및 소비기한'),
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
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _addressController,
                        readOnly: true,
                        onTap: searchAddress,
                        decoration: InputDecoration(
                          labelText: 'Administrative Region',
                          suffixIcon: _addressController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _addressController.clear();
                                      _address = null;
                                    });
                                  },
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        initialValue: memo,
                        decoration: const InputDecoration(labelText: 'Memo'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'memo can not be empty';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          memo = value!;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('메인 이미지'),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _pickMainImage,
                                  child: Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: _mainImagePreview ?? const Center(child: Icon(Icons.add_a_photo)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('추가 이미지'),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _pickAdditionalImages,
                                  child: Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: _additionalImagePreviews.isEmpty
                                        ? const Center(child: Icon(Icons.add_photo_alternate))
                                        : SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(children: _additionalImagePreviews),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_imagesLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 16.0),
                          child: SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    // Show loading dialog with SizedBox.shrink
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return const AlertDialog(
                          content: Row(
                            children: [
                              SizedBox.shrink(),
                              SizedBox(width: 16),
                              Text("상품 저장중..."),
                            ],
                          ),
                        );
                      },
                    );

                    try {
                      // Upload images if selected
                      if (_mainImage != null) {
                        imgUrl = await _productService.uploadImageToFirebaseStorage(_mainImage!);
                      }
                      if (_additionalImages.isNotEmpty) {
                        imgUrls = await _productService.uploadProductImages(_additionalImages);
                      }

                      final isEdit = widget.product != null;
                      final finalProduct = Product(
                        product_id: productId,
                        productName: productName,
                        sellerName: sellerName,
                        category: category,
                        categoryList: categoryList,
                        price: pricePoints.isNotEmpty ? pricePoints[0].price : 0.0,
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
                        deliveryManagerId: deliveryManagerId ?? '',
                        address: _address,
                        arrivalDate: arrivalDate,
                        createdAt: widget.product?.createdAt ?? Timestamp.now(),
                        memo: memo,
                      );

                      if (isEdit) {
                        await _productService.updateProduct(finalProduct);
                      } else {
                        await _productService.addProduct(finalProduct);
                      }

                      // Close loading dialog
                      Navigator.of(context).pop();
                      // Close form dialog
                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isEdit ? '상품 수정이 성공적으로 완료되었습니다' : '상품이 성공적으로 등록되었습니다')),
                      );
                    } catch (e) {
                      // Close loading dialog
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  }
                },
                child: const Text('저장'),
              ),
            ],
          );
        },
      ),
    );
  }
}
