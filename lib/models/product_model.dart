// models/product_model.dart
class Product {
  final String product_id;
  final String productName;
  final String sellerName;
  final String instructions;
  final String category;
  final int stock;
  final int baselineTime;
  final int price;
  final bool freeShipping;
  final String meridiem;
  final String? imgUrl;
  final List<String?> imgUrls;

  Product({
    required this.product_id,
    required this.productName,
    required this.sellerName,
    required this.category,
    required this.price,
    required this.freeShipping,
    required this.instructions,
    required this.stock,
    required this.baselineTime,
    required this.meridiem,
    required this.imgUrl,
    required this.imgUrls,
  });

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      product_id: map['product_id'] ?? id,
      productName: map['productName'] ?? '',
      instructions: map['instructions'] ?? '',
      stock: map['stock'] ?? 0,
      baselineTime: map['baselineTime'] ?? 0,
      meridiem: map['meridiem'] ?? 'AM',
      imgUrl: map['imgUrl'],
      imgUrls: List<String?>.from(map['imgUrls'] ?? []),
      sellerName: map['sellerName'] ?? '',
      category: map['category'] ?? '',
      price: map['price'] ?? 0,
      freeShipping: map['freeShipping'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': product_id,
      'productName': productName,
      'instructions': instructions,
      'stock': stock,
      'baselineTime': baselineTime,
      'meridiem': meridiem,
      'imgUrl': imgUrl,
      'imgUrls': imgUrls,
      'sellerName': sellerName,
      'category': category,
      'price': price,
      'freeShipping': freeShipping,
    };
  }
}
