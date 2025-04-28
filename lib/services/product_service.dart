import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ProductService {
  final CollectionReference productsCollection = FirebaseFirestore.instance
      .collection('products');

  final String imgbbApiKey = 'df668aeecb751b64bc588772056a32df';

  Future<void> addProduct(Product product) {
    return productsCollection.doc(product.product_id).set(product.toMap());
  }

  Future<void> updateProduct(Product product) {
    return productsCollection.doc(product.product_id).update(product.toMap());
  }

  Future<void> deleteProduct(String productId) {
    return productsCollection.doc(productId).delete();
  }

  Future<String> uploadImageToImgBB(XFile image) async {
    final bytes = await image.readAsBytes();

    final base64Image = base64Encode(bytes);

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.imgbb.com/1/upload'),
    );

    request.fields['key'] = imgbbApiKey;

    request.fields['image'] = base64Image;

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return jsonData['data']['url'];
    } else {
      throw Exception('Failed to upload image: ${response.body}');
    }
  }

  Future<List<String>> uploadProductImages(List<XFile> files) async {
    List<String> urls = [];
    for (var file in files) {
      String url = await uploadImageToImgBB(file);
      urls.add(url);
    }
    return urls;
  }
}
