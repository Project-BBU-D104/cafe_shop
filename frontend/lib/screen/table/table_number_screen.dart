import 'package:flutter/material.dart';
import 'package:frontend/widget/custom_app_bar.dart';
import 'package:get/get.dart';

class TableNumberScreen extends StatelessWidget {
  const TableNumberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Table Management".tr,
        showBack: true,
        onBack: () => Get.back(),
      ),
    );
  }
}