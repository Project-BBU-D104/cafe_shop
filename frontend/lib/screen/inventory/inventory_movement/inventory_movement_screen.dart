import 'package:flutter/material.dart';
import 'package:frontend/widget/custom_app_bar.dart';

class InventoryMovementScreen extends StatelessWidget {
  const InventoryMovementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  CustomAppBar(
        title: 'Inventory Movements',
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: const Center(
        child: Text('Inventory Movements'),
      ),
    );
  }
}