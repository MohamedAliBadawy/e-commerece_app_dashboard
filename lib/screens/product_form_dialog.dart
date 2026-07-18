import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final ImagePicker _picker = ImagePicker();

  late String productId;
  late String productName;
  late String sellerName;
  late TextEditingController _sellerNameController;
  late String category;
  late String memo;
  late List<String> categoryList;
  late String instructions;
  late String description;
  late int stock;
  late double deliveryPrice;
  late double supplyPrice;
  late double marginRate;
  late double shippingFee;
  late int baselineTime;
  late String meridiem;
  late String arrivalDate;
  String? imgUrl;
  List<String?> imgUrls = [];
  late List<PricePoint> pricePoints;
  String? deliveryManagerId;

  // New fields from seller edit requests
  late String taxType;
  late String shippingMethod;
  late double returnDeliveryPrice;
  late double freeShippingThreshold;
  late bool noFreeShipping;
  late int maxPackagingQuantity;
  late bool isSingleQuantity;
  late int deliveryMinDays;
  late int deliveryMaxDays;
  List<String> _includedSigungu = [];
  List<String> _excludedEupmyeondong = [];

  final List<bool> _isUploadingImage = [false, false, false, false, false];

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
      instructions = p.instructions;
      description = p.description;
      stock = p.stock;
      deliveryPrice = p.deliveryPrice ?? 0.0;
      supplyPrice = p.supplyPrice;
      marginRate = p.marginRate ?? 0.0;
      shippingFee = p.shippingFee ?? 0.0;
      baselineTime = p.baselineTime;
      meridiem = p.meridiem;
      arrivalDate = p.arrivalDate ?? '';
      imgUrl = p.imgUrl;
      imgUrls = List<String?>.from(p.imgUrls);
      pricePoints = List<PricePoint>.from(p.pricePoints);
      deliveryManagerId = p.deliveryManagerId;

      // Initialize new fields
      taxType = p.taxType;
      shippingMethod = p.shippingMethod ?? '택배배송';
      returnDeliveryPrice = p.returnDeliveryPrice;
      freeShippingThreshold = p.freeShippingThreshold;
      noFreeShipping = p.noFreeShipping;
      maxPackagingQuantity = p.maxPackagingQuantity;
      isSingleQuantity = p.isSingleQuantity;
      deliveryMinDays = p.deliveryMinDays;
      deliveryMaxDays = p.deliveryMaxDays;

      _includedSigungu = [];
      _excludedEupmyeondong = [];
      if (p.address != null) {
        final addrMap = p.address!;
        if (addrMap.containsKey('includedSigungu') &&
            addrMap['includedSigungu'] is List) {
          _includedSigungu = List<String>.from(addrMap['includedSigungu']);
        } else {
          final legacyName = addrMap['address_name']?.toString() ?? '';
          if (legacyName.isNotEmpty) {
            final parts = legacyName.split(' ');
            if (parts.length >= 2) {
              _includedSigungu = ['${parts[0]} ${parts[1]}'];
            } else {
              _includedSigungu = [legacyName];
            }
          }
        }
        if (addrMap.containsKey('excludedEupmyeondong') &&
            addrMap['excludedEupmyeondong'] is List) {
          _excludedEupmyeondong = List<String>.from(
            addrMap['excludedEupmyeondong'],
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
      instructions = '';
      description = '';
      stock = 0;
      deliveryPrice = 0.0;
      supplyPrice = 0.0;
      marginRate = 0.0;
      shippingFee = 0.0;
      baselineTime = 9;
      meridiem = 'AM';
      arrivalDate = '';
      pricePoints = [PricePoint(quantity: 1, price: 0)];
      deliveryManagerId = '';

      // Initialize new fields
      taxType = '과세';
      shippingMethod = '택배배송';
      returnDeliveryPrice = 0.0;
      freeShippingThreshold = 0.0;
      noFreeShipping = false;
      maxPackagingQuantity = 1;
      isSingleQuantity = true;
      deliveryMinDays = 1;
      deliveryMaxDays = 3;
      _includedSigungu = [];
      _excludedEupmyeondong = [];
    }

    _sellerNameController = TextEditingController(text: sellerName);

    while (imgUrls.length < 4) {
      imgUrls.add('');
    }
  }

  @override
  void dispose() {
    _sellerNameController.dispose();
    super.dispose();
  }

  void _addIncludedSigungu() async {
    final kakaoService = KakaoApiService(
      apiKey: '772742afea4cfac8c58ed62cfa7d1777',
    );

    final result = await showDialog(
      context: context,
      builder: (context) => AddressSearchDialog(kakaoService: kakaoService),
    );

    if (!mounted) return;

    if (result != null && result is Map) {
      String? d1;
      String? d2;
      String? d3;
      if (result['address'] != null) {
        d1 = result['address']['region_1depth_name'];
        d2 = result['address']['region_2depth_name'];
        d3 = result['address']['region_3depth_name'];
      }
      if ((d3 == null || d3.isEmpty) && result['road_address'] != null) {
        d1 = result['road_address']['region_1depth_name'];
        d2 = result['road_address']['region_2depth_name'];
        d3 = result['road_address']['region_3depth_name'];
      }
      if (d3 == null || d3.isEmpty) {
        final name = result['address_name']?.toString() ?? '';
        final parts = name.split(' ');
        if (parts.length >= 3) {
          d1 = parts[0];
          d2 = parts[1];
          d3 = parts[2];
        } else if (parts.isNotEmpty) {
          d1 = parts[0];
          if (parts.length >= 2) {
            d2 = parts[1];
          }
        }
      }

      if (d1 != null && d1.isNotEmpty) {
        final newSigungu = (d2 != null && d2.isNotEmpty)
            ? ((d3 != null && d3.isNotEmpty) ? '$d1 $d2 $d3' : '$d1 $d2')
            : d1;
        if (!_includedSigungu.contains(newSigungu)) {
          setState(() {
            _includedSigungu.add(newSigungu);
          });
        }
      }
    }
  }

  void _addExcludedEupmyeondong() async {
    final kakaoService = KakaoApiService(
      apiKey: '772742afea4cfac8c58ed62cfa7d1777',
    );

    final result = await showDialog(
      context: context,
      builder: (context) => AddressSearchDialog(kakaoService: kakaoService),
    );

    if (!mounted) return;

    if (result != null && result is Map) {
      String? d1;
      String? d2;
      String? d3;
      if (result['address'] != null) {
        d1 = result['address']['region_1depth_name'];
        d2 = result['address']['region_2depth_name'];
        d3 = result['address']['region_3depth_name'];
      }
      if ((d3 == null || d3.isEmpty) && result['road_address'] != null) {
        d1 = result['road_address']['region_1depth_name'];
        d2 = result['road_address']['region_2depth_name'];
        d3 = result['road_address']['region_3depth_name'];
      }
      if (d3 == null || d3.isEmpty) {
        final name = result['address_name']?.toString() ?? '';
        final parts = name.split(' ');
        if (parts.length >= 3) {
          d1 = parts[0];
          d2 = parts[1];
          d3 = parts[2];
        }
      }

      if (d3 != null && d3.isNotEmpty) {
        final fullDong =
            (d1 != null && d1.isNotEmpty)
                ? ((d2 != null && d2.isNotEmpty) ? '$d1 $d2 $d3' : '$d1 $d3')
                : d3;
        if (!_excludedEupmyeondong.contains(fullDong)) {
          setState(() {
            _excludedEupmyeondong.add(fullDong);
          });
        }
      }
    }
  }

  Future<void> _pickAndUploadImage(int slotIndex, bool isMain) async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    final overallIndex = isMain ? 0 : slotIndex + 1;
    setState(() {
      _isUploadingImage[overallIndex] = true;
    });

    try {
      final url = await _productService.uploadImageToFirebaseStorage(
        pickedFile,
      );

      if (mounted) {
        setState(() {
          if (isMain) {
            imgUrl = url;
          } else {
            while (imgUrls.length < 4) {
              imgUrls.add('');
            }
            imgUrls[slotIndex] = url;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('업로드 실패: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage[overallIndex] = false;
        });
      }
    }
  }

  void _showImageOptions(int slotIndex, bool isMain) {
    final url =
        isMain
            ? imgUrl
            : (imgUrls.length > slotIndex ? imgUrls[slotIndex] : null);
    final hasImage = url != null && url.isNotEmpty;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.black),
                title: const Text('사진 변경'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(slotIndex, isMain);
                },
              ),
              if (hasImage)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    '사진 삭제',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    setState(() {
                      if (isMain) {
                        imgUrl = null;
                      } else {
                        if (imgUrls.length > slotIndex) {
                          imgUrls[slotIndex] = '';
                        }
                      }
                    });
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _addPricePoint() {
    if (isSingleQuantity || maxPackagingQuantity <= 1) return;
    if (pricePoints.length >= 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('수량 옵션은 최대 5개까지 설정 가능합니다')));
      return;
    }
    if (pricePoints.length >= maxPackagingQuantity) return;
    setState(() {
      pricePoints.insert(
        pricePoints.length - 1,
        PricePoint(quantity: 1, price: 0),
      );
    });
  }

  void _removePricePoint(int index) {
    if (pricePoints.length <= 1 || index == pricePoints.length - 1) return;
    setState(() {
      pricePoints.removeAt(index);
    });
  }

  Widget _buildBrutalistTag({
    required String label,
    required VoidCallback onDelete,
    bool isExclude = false,
  }) {
    final displayLabel = isExclude ? '- $label' : '+ $label';
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1),
      ),
      height: 32,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              displayLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          InkWell(
            onTap: onDelete,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Colors.black, width: 1)),
                color: Colors.black,
              ),
              child: const Text(
                'x',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrutalistAddButton(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.black, width: 1),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.add, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildBrutalistSection({
    required String title,
    required List<String> items,
    required VoidCallback onAdd,
    required Function(int) onDelete,
    bool isExclude = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1),
          ),
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final val = entry.value;
                  final parts = val.split(' ');
                  final displayName =
                      parts.length >= 2
                          ? '${parts[parts.length - 2]} ${parts.last}'
                          : val;
                  return _buildBrutalistTag(
                    label: displayName,
                    onDelete: () => onDelete(index),
                    isExclude: isExclude,
                  );
                }),
                _buildBrutalistAddButton(onAdd),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String label) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black, width: 1),
          left: BorderSide(color: Colors.black, width: 1),
          right: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsyncValue = ref.watch(categoriesFutureProvider);
    final deliveryManagersAsyncValue = ref.watch(
      deliveryManagersFutureProvider,
    );

    return categoriesAsyncValue.when(
      loading:
          () => const Center(
            child: CircularProgressIndicator(color: Colors.black),
          ),
      error:
          (err, stack) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to load categories: $err'),
          ),
      data:
          (categories) => deliveryManagersAsyncValue.when(
            loading:
                () => const Center(
                  child: CircularProgressIndicator(color: Colors.black),
                ),
            error:
                (err, stack) => AlertDialog(
                  title: const Text('Error'),
                  content: Text('Failed to load delivery managers: $err'),
                ),
            data: (deliveryManagers) {
              final hasValidDM = deliveryManagers.any(
                (dm) => dm.userId == deliveryManagerId,
              );
              if (deliveryManagers.isNotEmpty &&
                  (deliveryManagerId == null ||
                      deliveryManagerId!.isEmpty ||
                      !hasValidDM)) {
                deliveryManagerId = deliveryManagers.first.userId;
              }
              final hasValidCategory = categories.any(
                (cat) => cat.name == category || cat.id == category,
              );
              if (categories.isNotEmpty &&
                  (category.isEmpty || !hasValidCategory)) {
                category = categories.first.name;
              }

              return AlertDialog(
                title: Text(
                  widget.product != null ? '상품 수정' : '상품 추가',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                content: SizedBox(
                  width: 700,
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. 판매자명 & 판매자 ID 매칭
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: sellerName,
                                  decoration: const InputDecoration(
                                    labelText: '판매자명',
                                    border: OutlineInputBorder(),
                                  ),
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
                                child: DropdownButtonFormField<String>(
                                  initialValue: deliveryManagerId,
                                  decoration: const InputDecoration(
                                    labelText: '판매자 계정',
                                    border: OutlineInputBorder(),
                                  ),
                                  items:
                                      deliveryManagers.map((dm) {
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

                          // 2. 상품명 & 과세 구분
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: productName,
                                  decoration: const InputDecoration(
                                    labelText: '상품명',
                                    border: OutlineInputBorder(),
                                  ),
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
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children:
                                        [
                                          MapEntry('과세', '과세'),
                                          MapEntry('면세', '면세'),
                                        ].map((entry) {
                                          final isSelected =
                                              taxType == entry.key;
                                          return Expanded(
                                            child: InkWell(
                                              onTap:
                                                  () => setState(
                                                    () => taxType = entry.key,
                                                  ),
                                              child: Container(
                                                alignment: Alignment.center,
                                                color:
                                                    isSelected
                                                        ? Colors.black
                                                        : Colors.white,
                                                child: Text(
                                                  entry.value,
                                                  style: TextStyle(
                                                    color:
                                                        isSelected
                                                            ? Colors.white
                                                            : Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 3. 카테고리 선택
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '카테고리 선택',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  categories.map((cat) {
                                    final isSelected = category == cat.name;
                                    return ChoiceChip(
                                      label: Text(cat.name),
                                      selected: isSelected,
                                      onSelected: (bool selected) {
                                        if (selected) {
                                          setState(() {
                                            category = cat.name;
                                            categoryList = [cat.id];
                                          });
                                        }
                                      },
                                    );
                                  }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 4. 공급가 & 배송방식
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: supplyPrice.toInt().toString(),
                                  decoration: const InputDecoration(
                                    labelText: '공급가 (배송비 미포함)',
                                    prefixText: '₩ ',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    ThousandsSeparatorInputFormatter(),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '공급가를 입력하세요';
                                    }
                                    return null;
                                  },
                                  onChanged: (val) {
                                    setState(() {
                                      supplyPrice =
                                          double.tryParse(
                                            val.replaceAll(',', ''),
                                          ) ??
                                          0.0;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children:
                                        [
                                          MapEntry('택배배송', '택배배송'),
                                          MapEntry('지역배송', '지역배송'),
                                        ].map((entry) {
                                          final isSelected =
                                              shippingMethod == entry.key;
                                          return Expanded(
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  shippingMethod = entry.key;
                                                  if (shippingMethod ==
                                                      '택배배송') {
                                                    _includedSigungu = [];
                                                    _excludedEupmyeondong = [];
                                                  }
                                                });
                                                if (shippingMethod == '지역배송' &&
                                                    _includedSigungu.isEmpty) {
                                                  _addIncludedSigungu();
                                                }
                                              },
                                              child: Container(
                                                alignment: Alignment.center,
                                                color:
                                                    isSelected
                                                        ? Colors.black
                                                        : Colors.white,
                                                child: Text(
                                                  entry.value,
                                                  style: TextStyle(
                                                    color:
                                                        isSelected
                                                            ? Colors.white
                                                            : Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 지역배송 설정 영역
                          if (shippingMethod == '지역배송') ...[
                            _buildBrutalistSection(
                              title: '시, 군, 구 추가',
                              items: _includedSigungu,
                              onAdd: _addIncludedSigungu,
                              onDelete: (index) {
                                setState(() {
                                  _includedSigungu.removeAt(index);
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildBrutalistSection(
                              title: '읍, 면, 동 제거',
                              items: _excludedEupmyeondong,
                              onAdd: _addExcludedEupmyeondong,
                              onDelete: (index) {
                                setState(() {
                                  _excludedEupmyeondong.removeAt(index);
                                });
                              },
                              isExclude: true,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // 5. 배송비 / 도서지역 추가 배송비 / 반품 배송비
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue:
                                      deliveryPrice.toInt().toString(),
                                  decoration: const InputDecoration(
                                    labelText: '배송비',
                                    prefixText: '₩ ',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    ThousandsSeparatorInputFormatter(),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '배송비를 입력하세요';
                                    }
                                    return null;
                                  },
                                  onChanged: (val) {
                                    setState(() {
                                      deliveryPrice =
                                          double.tryParse(
                                            val.replaceAll(',', ''),
                                          ) ??
                                          0.0;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: shippingFee.toInt().toString(),
                                  decoration: const InputDecoration(
                                    labelText: '도서지역 추가 배송비',
                                    prefixText: '₩ ',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    ThousandsSeparatorInputFormatter(),
                                  ],
                                  onSaved: (value) {
                                    shippingFee =
                                        double.tryParse(
                                          value!.replaceAll(',', ''),
                                        ) ??
                                        0.0;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue:
                                      returnDeliveryPrice.toInt().toString(),
                                  decoration: const InputDecoration(
                                    labelText: '반품 배송비',
                                    prefixText: '₩ ',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    ThousandsSeparatorInputFormatter(),
                                  ],
                                  onSaved: (value) {
                                    returnDeliveryPrice =
                                        double.tryParse(
                                          value!.replaceAll(',', ''),
                                        ) ??
                                        0.0;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 6. ~이상 구매 시 무료배송
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  key: ValueKey('threshold_$noFreeShipping'),
                                  initialValue:
                                      freeShippingThreshold.toInt().toString(),
                                  enabled: !noFreeShipping,
                                  decoration: const InputDecoration(
                                    labelText: '무료배송 기준 금액',
                                    prefixText: '₩ ',
                                    suffixText: ' 이상 구매 시 무료',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    ThousandsSeparatorInputFormatter(),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      freeShippingThreshold =
                                          double.tryParse(
                                            val.replaceAll(',', ''),
                                          ) ??
                                          0.0;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      noFreeShipping = !noFreeShipping;
                                    });
                                  },
                                  child: Container(
                                    height: 56,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                      color:
                                          noFreeShipping
                                              ? Colors.black
                                              : Colors.white,
                                    ),
                                    child: Text(
                                      '무료배송 없음',
                                      style: TextStyle(
                                        color:
                                            noFreeShipping
                                                ? Colors.white
                                                : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 7. 1상자 최대 포장수량 & 단일수량
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  key: ValueKey('maxPkg_$isSingleQuantity'),
                                  initialValue: maxPackagingQuantity.toString(),
                                  enabled: !isSingleQuantity,
                                  decoration: const InputDecoration(
                                    labelText: '1상자 최대 포장수량',
                                    suffixText: ' 개',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (val) {
                                    final parsed = int.tryParse(val) ?? 1;
                                    setState(() {
                                      maxPackagingQuantity = parsed;
                                      if (pricePoints.isNotEmpty) {
                                        pricePoints.last.quantity = parsed;
                                      }
                                      pricePoints.removeWhere(
                                        (pt) =>
                                            pt != pricePoints.last &&
                                            pt.quantity >= parsed,
                                      );
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      isSingleQuantity = !isSingleQuantity;
                                      if (isSingleQuantity) {
                                        pricePoints = [
                                          PricePoint(quantity: 1, price: 0),
                                        ];
                                      } else {
                                        pricePoints = [
                                          PricePoint(
                                            quantity: maxPackagingQuantity,
                                            price: 0,
                                          ),
                                        ];
                                      }
                                    });
                                  },
                                  child: Container(
                                    height: 56,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                      color:
                                          isSingleQuantity
                                              ? Colors.black
                                              : Colors.white,
                                    ),
                                    child: Text(
                                      '단일수량',
                                      style: TextStyle(
                                        color:
                                            isSingleQuantity
                                                ? Colors.white
                                                : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 8. 마진율 및 수량별 가격 테이블
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: marginRate.toString(),
                                  decoration: const InputDecoration(
                                    labelText: '마진율 (%)',
                                    suffixText: ' %',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      marginRate = double.tryParse(val) ?? 0.0;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '수량별 판매가 옵션 (자동 계산)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Table(
                            columnWidths: const {
                              0: FlexColumnWidth(1),
                              1: FlexColumnWidth(2),
                            },
                            border: TableBorder.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                ),
                                children: [
                                  Container(
                                    height: 40,
                                    alignment: Alignment.center,
                                    child: const Text(
                                      '수량 입력',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 40,
                                    alignment: Alignment.center,
                                    child: const Text(
                                      '계산된 판매가',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              ...List.generate(pricePoints.length, (index) {
                                final pt = pricePoints[index];
                                final bool isMaxRow =
                                    (index == pricePoints.length - 1) ||
                                    isSingleQuantity;

                                final int qty =
                                    isSingleQuantity
                                        ? 1
                                        : (isMaxRow
                                            ? maxPackagingQuantity
                                            : pt.quantity);
                                pt.quantity = qty;

                                // Calculate using margin formula: ((qty * supplyPrice) + deliveryPrice) / (1 - (marginRate / 100))
                                final double rateFactor =
                                    1 - (marginRate / 100);
                                final double calculatedPrice =
                                    rateFactor > 0
                                        ? ((qty * supplyPrice) +
                                                deliveryPrice) /
                                            rateFactor
                                        : 0.0;

                                pt.price = calculatedPrice;

                                return TableRow(
                                  children: [
                                    TableCell(
                                      verticalAlignment:
                                          TableCellVerticalAlignment.middle,
                                      child: TextFormField(
                                        key: ValueKey(
                                          'qty_${isSingleQuantity}_${isMaxRow}_${index}_$qty',
                                        ),
                                        initialValue: qty.toString(),
                                        textAlign: TextAlign.center,
                                        readOnly: isMaxRow,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        onChanged: (val) {
                                          if (isMaxRow) return;
                                          final parsedQty =
                                              int.tryParse(val) ?? 1;
                                          setState(() {
                                            pricePoints[index].quantity =
                                                parsedQty;
                                          });
                                        },
                                        validator: (val) {
                                          if (isMaxRow) return null;
                                          final parsedQty =
                                              int.tryParse(val ?? '') ?? 0;
                                          if (parsedQty <= 0) return '1 이상';
                                          if (parsedQty >=
                                              maxPackagingQuantity) {
                                            return '최대 포장수량 미만 입력';
                                          }
                                          for (
                                            int i = 0;
                                            i < pricePoints.length;
                                            i++
                                          ) {
                                            if (i != index &&
                                                pricePoints[i].quantity ==
                                                    parsedQty) {
                                              return '중복 수량';
                                            }
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    TableCell(
                                      verticalAlignment:
                                          TableCellVerticalAlignment.middle,
                                      child: Row(
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.0,
                                            ),
                                            child: Text(
                                              '₩',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              NumberFormat(
                                                '#,###',
                                              ).format(calculatedPrice),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (!isMaxRow)
                                            TextButton(
                                              onPressed:
                                                  () =>
                                                      _removePricePoint(index),
                                              child: const Text(
                                                '삭제',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (!isSingleQuantity &&
                              pricePoints.length < 5 &&
                              pricePoints.length < maxPackagingQuantity)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ElevatedButton.icon(
                                onPressed: _addPricePoint,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('수량별 판매가 옵션 추가'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  side: const BorderSide(color: Colors.black),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),

                          // 9. 마감 시간 & 배송 소요 기간
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: baselineTime.toString(),
                                        decoration: const InputDecoration(
                                          labelText: '마감 시간',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return '시간 입력';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) {
                                          baselineTime =
                                              int.tryParse(value!) ?? 9;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    DropdownButton<String>(
                                      value: meridiem,
                                      items:
                                          ['AM', 'PM'].map((String val) {
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
                              const SizedBox(width: 16),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue:
                                            deliveryMinDays.toString(),
                                        decoration: const InputDecoration(
                                          labelText: '배송 최소일',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onSaved: (value) {
                                          deliveryMinDays =
                                              int.tryParse(value!) ?? 1;
                                        },
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                      ),
                                      child: Text('~'),
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue:
                                            deliveryMaxDays.toString(),
                                        decoration: const InputDecoration(
                                          labelText: '배송 최대일',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onSaved: (value) {
                                          deliveryMaxDays =
                                              int.tryParse(value!) ?? 3;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text('일'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 10. 상품설명 / 보관법 및 소비기한 / 안내사항
                          TextFormField(
                            initialValue: description,
                            decoration: const InputDecoration(
                              labelText: '상품 설명',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '상품 설명을 입력하세요';
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
                            decoration: const InputDecoration(
                              labelText: '보관법 및 소비기한',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '보관법 및 소비기한을 입력하세요';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              instructions = value!;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: arrivalDate,
                            decoration: const InputDecoration(
                              labelText: '안내사항',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            onSaved: (value) {
                              arrivalDate = value ?? '';
                            },
                          ),
                          const SizedBox(height: 16),

                          // 11. 메모
                          TextFormField(
                            initialValue: memo,
                            decoration: const InputDecoration(
                              labelText: '관리자 메모',
                              border: OutlineInputBorder(),
                            ),
                            onSaved: (value) {
                              memo = value ?? '';
                            },
                          ),
                          const SizedBox(height: 16),

                          // 12. 이미지 5슬롯 업로드
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '이미지 등록 (첫 번째 이미지가 대표 이미지)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Table(
                            border: TableBorder.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                ),
                                children: const [
                                  TableCell(
                                    child: Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          '대표 이미지',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    child: Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          '추가 이미지 1',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    child: Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          '추가 이미지 2',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    child: Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          '추가 이미지 3',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    child: Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          '추가 이미지 4',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              TableRow(
                                children: List.generate(5, (index) {
                                  final isMain = index == 0;
                                  final url =
                                      isMain
                                          ? imgUrl
                                          : (imgUrls.length > index - 1
                                              ? imgUrls[index - 1]
                                              : null);
                                  final hasImage =
                                      url != null && url.isNotEmpty;
                                  final isUploading = _isUploadingImage[index];

                                  return InkWell(
                                    onTap:
                                        isUploading
                                            ? null
                                            : () {
                                              if (hasImage) {
                                                _showImageOptions(
                                                  isMain ? 0 : index - 1,
                                                  isMain,
                                                );
                                              } else {
                                                _pickAndUploadImage(
                                                  isMain ? 0 : index - 1,
                                                  isMain,
                                                );
                                              }
                                            },
                                    child: Container(
                                      height: 90,
                                      alignment: Alignment.center,
                                      child:
                                          isUploading
                                              ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.black,
                                                    ),
                                              )
                                              : hasImage
                                              ? Image.network(
                                                url,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return const Icon(
                                                    Icons.broken_image,
                                                    size: 24,
                                                    color: Colors.grey,
                                                  );
                                                },
                                              )
                                              : const Icon(
                                                Icons.add_a_photo,
                                                size: 24,
                                                color: Colors.grey,
                                              ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 13. 재고
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: stock.toString(),
                                  decoration: const InputDecoration(
                                    labelText: '재고 수량',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '재고 수량을 입력하세요';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    stock = int.tryParse(value!) ?? 0;
                                  },
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
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();

                        final currentImgUrl = imgUrl;
                        if (currentImgUrl == null || currentImgUrl.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('대표 이미지는 필수 등록 항목입니다.'),
                            ),
                          );
                          return;
                        }

                        if (shippingMethod == '지역배송' &&
                            _includedSigungu.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '지역배송 설정 시 배송 지역을 최소 한 곳 이상 추가해 주세요.',
                              ),
                            ),
                          );
                          return;
                        }

                        // Sort price points by quantity before saving
                        if (pricePoints.length > 1) {
                          pricePoints.sort(
                            (a, b) => a.quantity.compareTo(b.quantity),
                          );
                        }

                        // Show loading dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const AlertDialog(
                              content: Row(
                                children: [
                                  CircularProgressIndicator(
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: 16),
                                  Text("상품 저장중..."),
                                ],
                              ),
                            );
                          },
                        );

                        try {
                          final isEdit = widget.product != null;
                          final finalProduct = Product(
                            product_id: productId,
                            productName: productName,
                            sellerName: sellerName,
                            category: category,
                            categoryList: categoryList,
                            price:
                                pricePoints.isNotEmpty
                                    ? pricePoints[0].price
                                    : 0.0,
                            supplyPrice: supplyPrice,
                            pricePoints: pricePoints,
                            freeShipping: !noFreeShipping,
                            instructions: instructions,
                            description: description,
                            stock: stock,
                            baselineTime: baselineTime,
                            meridiem: meridiem,
                            imgUrl: imgUrl,
                            imgUrls:
                                imgUrls
                                    .where(
                                      (url) => url != null && url.isNotEmpty,
                                    )
                                    .toList(),
                            marginRate: marginRate,
                            deliveryManagerId: deliveryManagerId ?? '',
                            address:
                                shippingMethod == '지역배송'
                                    ? {
                                      'address_name':
                                          _includedSigungu.isEmpty
                                              ? ''
                                              : (_includedSigungu.length == 1
                                                  ? _includedSigungu.first
                                                      .split(' ')
                                                      .last
                                                  : '${_includedSigungu.first.split(' ').last} 외 ${_includedSigungu.length - 1}곳'),
                                      'includedSigungu': _includedSigungu,
                                      'excludedEupmyeondong':
                                          _excludedEupmyeondong,
                                    }
                                    : null,
                            arrivalDate: arrivalDate,
                            createdAt:
                                widget.product?.createdAt ?? Timestamp.now(),
                            memo: memo,
                            taxType: taxType,
                            shippingMethod: shippingMethod,
                            returnDeliveryPrice: returnDeliveryPrice,
                            freeShippingThreshold: freeShippingThreshold,
                            noFreeShipping: noFreeShipping,
                            maxPackagingQuantity: maxPackagingQuantity,
                            isSingleQuantity: isSingleQuantity,
                            deliveryMinDays: deliveryMinDays,
                            deliveryMaxDays: deliveryMaxDays,
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
                            SnackBar(
                              content: Text(
                                isEdit
                                    ? '상품 수정이 성공적으로 완료되었습니다.'
                                    : '상품이 성공적으로 등록되었습니다.',
                              ),
                            ),
                          );
                        } catch (e) {
                          // Close loading dialog
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('저장 실패: ${e.toString()}')),
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
