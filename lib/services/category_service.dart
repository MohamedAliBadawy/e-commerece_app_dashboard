import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  final CollectionReference categoriesCollection = FirebaseFirestore.instance
      .collection('categories');

  // Get all categories
  Stream<List<Category>> getCategories() {
    return categoriesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // Create a map with the document data
        Map<String, dynamic> data = {...doc.data() as Map<String, dynamic>};

        // Add the document ID to the map
        data['id'] = doc.id;

        return Category.fromMap(data);
      }).toList();
    });
  }

  // Add this method to CategoryService
  Future<List<Category>> getCategoriesOnce() async {
    final snapshot = await categoriesCollection.get();
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return Category.fromMap(data);
    }).toList();
  }

  // Add a new category
  Future<void> addCategory(Category category) {
    // Generate a new document with auto-ID
    final doc = categoriesCollection.doc();
    category.id = doc.id; // Update the category with the new ID
    return doc.set(category.toMap());
  }

  // Update a category
  Future<void> updateCategory(Category category) {
    return categoriesCollection.doc(category.id).update(category.toMap());
  }

  // Delete a category
  Future<void> deleteCategory(String categoryId) {
    return categoriesCollection.doc(categoryId).delete();
  }
}
