import 'package:flutter/material.dart';
import 'product_edit_requests_screen.dart';

class ProductModificationRequestsScreen extends StatelessWidget {
  const ProductModificationRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProductEditRequestsScreen(isNewProductOnly: false);
  }
}
