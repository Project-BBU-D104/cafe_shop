import 'package:flutter/material.dart';
import 'package:frontend/global.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:get/get.dart';

class LoginController extends GetxController{

  final emailController = TextEditingController(text:"owner@example.com");
  final passwordController = TextEditingController(text:"password123");

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

      final token = result["token"]?.toString();
      if (token == null || token.isEmpty) {
        throw StateError("The login response did not include an access token.");
      }

      await storage.lastUserLoginWrite(
        data: {
          "token": token,
          "token_type": "Bearer Token",
          "user": result["user"],
        },
      );

      if (storage.lastUserLoginRead["token"] != token) {
        throw StateError("Could not save the login session.");
      }

      await storage.appStartUpWrite(route: "/home");
  
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