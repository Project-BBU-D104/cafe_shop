import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:get/get.dart';

class LoginController extends GetxController{

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  final isLoading = false.obs;


  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      Get.snackbar(
        "Error",
        "Please enter email and password",
      );
      return;
    }

    try {
      isLoading.value = true;

      final result = await _authService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
 
      Get.offNamed('/home');
    } catch (e) { 
      Get.snackbar(
        "Login Failed",
        e.toString(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
  
}