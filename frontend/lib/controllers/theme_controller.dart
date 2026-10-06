import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  final isDark = false.obs;

  void toggleTheme() {
    isDark.value = !isDark.value;

    Get.changeThemeMode(
      isDark.value ? ThemeMode.dark : ThemeMode.light,
    );
  }
}