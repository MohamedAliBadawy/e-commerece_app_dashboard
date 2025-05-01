// screens/product_management.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app_dashboard/models/category_model.dart';
import 'package:ecommerce_app_dashboard/services/category_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

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
            'Product Management',
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
              SizedBox(width: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Add Product'),
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
                child: Text('Edit'),
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
                child: Text('Delete'),
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
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildTableHeader('Image', 1),
                        _buildTableHeader('Product name', 2),
                        _buildTableHeader('Descriptions', 2),
                        _buildTableHeader('Stock', 1),
                        _buildTableHeader('Baseline time', 1),
                        _buildTableHeader('Seller', 1),
                        _buildTableHeader('Price', 1),
                        _buildTableHeader('', 1),
                      ],
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
                        return ListView.builder(
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = Product.fromMap(
                              products[index].data() as Map<String, dynamic>,
                            );
                            return _buildProductRow(product);
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
                      '${pp.quantity} qty = \$${pp.price}',
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
    int price = 0;
    bool freeShipping = true;
    String instructions = '';
    int stock = 0;
    int baselineTime = 0;
    String meridiem = 'AM';
    String? imgUrl;
    List<String?> imgUrls = [];
    List<PricePoint> pricePoints = [PricePoint(quantity: 1, price: 0)];

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
              title: Text('Add New Product'),
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
                                decoration: InputDecoration(
                                  labelText: 'Product Name',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter product name';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  productName = value!;
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Seller Name',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter seller name';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  sellerName = value!;
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
                                    'Quantity-Based Pricing',
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
                                                  labelText: 'Quantity',
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
                                                initialValue:
                                                    pricePoints[index].price
                                                        .toString(),
                                                decoration: InputDecoration(
                                                  labelText: 'Price',
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                onChanged: (value) {
                                                  setDialogState(() {
                                                    pricePoints[index].price =
                                                        int.tryParse(value) ??
                                                        0;
                                                  });
                                                },
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
                                    label: Text('Add Price Point'),
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
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(labelText: 'Stock'),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter stock';
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
                                        labelText: 'Baseline Time',
                                        hintText: 'Enter 1-12',
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
                                          return 'Please enter time';
                                        }

                                        final number = int.tryParse(value);
                                        if (number == null) {
                                          return 'Please enter a valid number';
                                        }

                                        if (number < 1 || number > 12) {
                                          return 'Please enter between 1 and 12';
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
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Instructions',
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter instructions';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            instructions = value!;
                          },
                        ),
                        SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Main Image'),
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
                                  Text('Additional Images'),
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
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('Save'),
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
                                        Text("Saving product..."),
                                      ],
                                    ),
                                  );
                                },
                              );

                              try {
                                // Upload main image if selected
                                if (_mainImage != null) {
                                  imgUrl = await _productService
                                      .uploadImageToImgBB(_mainImage!);
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
                                  pricePoints: pricePoints,
                                  freeShipping: freeShipping,
                                  instructions: instructions,
                                  stock: stock,
                                  baselineTime: baselineTime,
                                  meridiem: meridiem,
                                  imgUrl: imgUrl,
                                  imgUrls: imgUrls,
                                );

                                // Save to Firestore
                                await _productService.addProduct(newProduct);

                                // Close loading dialog
                                Navigator.of(context).pop();

                                // Close form dialog
                                Navigator.of(context).pop();

                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Product added successfully'),
                                  ),
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
    int price = product.price;
    List<PricePoint> pricePoints = product.pricePoints;

    bool freeShipping = product.freeShipping;
    String instructions = product.instructions;
    int stock = product.stock;
    int baselineTime = product.baselineTime;
    String meridiem = product.meridiem;
    String? imgUrl = product.imgUrl;
    List<String?> imgUrls = List.from(product.imgUrls);

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
                                initialValue: productName,
                                decoration: InputDecoration(
                                  labelText: 'Product Name',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter product name';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  productName = value!;
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: sellerName,
                                decoration: InputDecoration(
                                  labelText: 'Seller Name',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter seller name';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  sellerName = value!;
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
                                    'Quantity-Based Pricing',
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
                                                  labelText: 'Quantity',
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
                                                initialValue:
                                                    pricePoints[index].price
                                                        .toString(),
                                                decoration: InputDecoration(
                                                  labelText: 'Price',
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                onChanged: (value) {
                                                  setDialogState(() {
                                                    pricePoints[index].price =
                                                        int.tryParse(value) ??
                                                        0;
                                                  });
                                                },
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
                                    label: Text('Add Price Point'),
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
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: stock.toString(),
                                decoration: InputDecoration(labelText: 'Stock'),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter stock';
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
                                        labelText: 'Baseline Time',
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter time';
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
                        TextFormField(
                          initialValue: instructions,
                          decoration: InputDecoration(
                            labelText: 'Instructions',
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter instructions';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            instructions = value!;
                          },
                        ),
                        SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Main Image'),
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
                                  Text('Additional Images'),
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
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('Save Changes'),
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
                                        Text("Updating product..."),
                                      ],
                                    ),
                                  );
                                },
                              );

                              try {
                                // Upload main image if a new one was selected
                                if (_mainImage != null) {
                                  imgUrl = await _productService
                                      .uploadImageToImgBB(_mainImage!);
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
                                  category: category,
                                  price: price,
                                  pricePoints: pricePoints,
                                  freeShipping: freeShipping,
                                  instructions: instructions,
                                  stock: stock,
                                  baselineTime: baselineTime,
                                  meridiem: meridiem,
                                  imgUrl: imgUrl,
                                  imgUrls: imgUrls,
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
                                    content: Text(
                                      'Product updated successfully',
                                    ),
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
          title: Text('Confirm Delete'),
          content: Text(
            _selectedProducts.length == 1
                ? 'Are you sure you want to delete this product?'
                : 'Are you sure you want to delete ${_selectedProducts.length} products?',
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Delete'),
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
                          Text("Deleting products..."),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Products deleted successfully')),
                  );
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
