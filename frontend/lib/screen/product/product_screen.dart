import 'package:flutter/material.dart';
import 'package:frontend/widget/custom_app_bar.dart';

class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Product Management',
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: const Center(
        child: Text('Product Management'),
      ),
    );
  }
}