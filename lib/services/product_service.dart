// services/product_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ProductService {
  final CollectionReference productsCollection = FirebaseFirestore.instance
      .collection('products');

  // ImgBB API key
  final String imgbbApiKey = 'df668aeecb751b64bc588772056a32df';

  // Get all products
  Stream<List<Product>> getProducts() {
    return productsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Add a product
  Future<void> addProduct(Product product) {
    return productsCollection.doc(product.product_id).set(product.toMap());
  }

  // Update a product
  Future<void> updateProduct(Product product) {
    return productsCollection.doc(product.product_id).update(product.toMap());
  }

  // Delete a product
  Future<void> deleteProduct(String productId) {
    return productsCollection.doc(productId).delete();
  }

  // Upload image to ImgBB - Web compatible version
  Future<String> uploadImageToImgBB(XFile image) async {
    // Read the file as bytes
    final bytes = await image.readAsBytes();

    // Convert to base64
    final base64Image = base64Encode(bytes);

    // Create multipart request
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.imgbb.com/1/upload'),
    );

    // Add API key
    request.fields['key'] = imgbbApiKey;

    // Add image data
    request.fields['image'] = base64Image;

    // Send the request
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    // Check if successful
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return jsonData['data']['url'];
    } else {
      throw Exception('Failed to upload image: ${response.body}');
    }
  }

  // Upload multiple product images
  Future<List<String>> uploadProductImages(List<XFile> files) async {
    List<String> urls = [];
    for (var file in files) {
      String url = await uploadImageToImgBB(file);
      urls.add(url);
    }
    return urls;
  }
}
