import 'package:flutter/material.dart';
import 'package:frontend/widget/custom_app_bar.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Shop Management',
        showBack: true,
        onBack: () => Navigator.pop(context),

      ),
      body: const Center(
        child: Text('Shop Screen'),
      ),
    );
  }
}