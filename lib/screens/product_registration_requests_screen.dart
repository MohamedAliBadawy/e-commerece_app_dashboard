import 'package:flutter/material.dart';
import 'product_edit_requests_screen.dart';

class ProductRegistrationRequestsScreen extends StatelessWidget {
  const ProductRegistrationRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProductEditRequestsScreen(isNewProductOnly: true);
  }
}
