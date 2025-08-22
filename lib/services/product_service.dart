import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_file/cross_file.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
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

  Future<String> uploadImageToFirebaseStorage(XFile image) async {
    try {
      // 1. Handle web-specific file naming
      String fileName;
      String? mimeType;

      if (kIsWeb) {
        // For web, extract proper extension from MIME type
        mimeType = image.mimeType;
        final extension = mimeType?.split('/').last ?? 'jpg';
        fileName = 'upload_${DateTime.now().millisecondsSinceEpoch}.$extension';
      } else {
        // For mobile, use the original file path
        final extension = image.path.split('.').last;
        fileName = 'upload_${DateTime.now().millisecondsSinceEpoch}.$extension';
      }

      // 2. Create storage reference
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_uploads')
          .child(fileName);

      // 3. Read image bytes
      final bytes = await image.readAsBytes();

      // 4. Determine MIME type
      final metadata = SettableMetadata(
        contentType: mimeType ?? 'image/jpeg', // Default to JPEG if unknown
        customMetadata: {
          'original_name': image.name,
          'uploaded_at': DateTime.now().toIso8601String(),
        },
      );

      // 5. Upload file
      final uploadTask = storageRef.putData(bytes, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  Future<void> addCreatedAtToOldProducts() async {
    final productsRef = FirebaseFirestore.instance.collection('products');

    final snapshot = await productsRef.get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (!data.containsKey('createdAt')) {
        await productsRef.doc(doc.id).update({
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('Updated product: ${doc.id}');
      }
    }

    print('✅ Finished updating old products.');
  }

  Future<List<String>> uploadProductImages(List<XFile> files) async {
    List<String> urls = [];
    for (var file in files) {
      String url = await uploadImageToFirebaseStorage(file);
      urls.add(url);
    }
    return urls;
  }
}
