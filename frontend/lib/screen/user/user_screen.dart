import 'package:flutter/material.dart';
import 'package:frontend/widget/custom_app_bar.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'User Management',
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: const Center(
        child: Text('User Management'),
      ),
    );
  }
}