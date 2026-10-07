import 'package:flutter/material.dart';
import 'package:frontend/widget/custom_app_bar.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Category Management',
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: const Center(
        child: Text('Category Management'),
      ),
    );
  }
}