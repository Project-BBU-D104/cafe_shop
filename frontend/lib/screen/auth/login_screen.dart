import 'package:flutter/material.dart';
import 'package:frontend/controllers/login_controller.dart';
import 'package:get/get.dart';

class LoginScreen extends StatelessWidget {
    LoginScreen({super.key});

  final loginCtr = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Center(
            child: Column( children: [
              Text("Login"),
          
              TextField(
                controller: loginCtr.emailController,
                decoration: InputDecoration(
                  hintText: "john@example.com",
                ),
              ),
          
              TextField(
                controller: loginCtr.passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Password",
                ),
              ),
          
              Obx(
                ()=> ElevatedButton(
                  onPressed: loginCtr.isLoading.value ? null : loginCtr.login,
                  child: loginCtr.isLoading.value ? CircularProgressIndicator() : Text("Login"),
                ),
              )
            ],
          )
                ),
        )),
    );
  }
}