import 'package:flutter/material.dart';
import 'package:frontend/widget/custom_app_bar.dart';

class ShiftScreen extends StatelessWidget {
  const ShiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Shift Management',
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: const Center(
        child: Text('Shift Management Screen'),
      )
    );
  }
}