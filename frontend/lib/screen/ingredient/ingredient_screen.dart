import 'package:flutter/material.dart';
import 'package:frontend/widget/custom_app_bar.dart';
import 'package:get/get.dart';

class IngredientScreen extends StatelessWidget {
  const IngredientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Ingredient Management'.tr,
        showBack: true,
        onBack: () => Navigator.pop(context)
      ),
      body: const Center(
        child: Text('Ingredient Management'),
      ),
    );
  }
}