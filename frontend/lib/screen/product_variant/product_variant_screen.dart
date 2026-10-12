import 'package:flutter/material.dart';
import 'package:frontend/widget/custom_app_bar.dart';
import 'package:get/get.dart';

class ProductVariantScreen extends StatelessWidget {
  const ProductVariantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Product Variant Management'.tr,
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: const Center(
        child: Text('Product Variant Management'),
      ),
    );
  }
}