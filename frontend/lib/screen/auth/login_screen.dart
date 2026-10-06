import 'package:flutter/material.dart';
import 'package:frontend/controllers/login_controller.dart';
import 'package:get/get.dart';

class LoginScreen extends StatelessWidget {
    LoginScreen({super.key});

  final loginCtr = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Column(
          children: [
            Text("Login Screen"),

            ElevatedButton(
              onPressed: () {
                loginCtr.login();
              },
              child: Text("Login"),
            )
          ],
        )
      ),
    );
  }
}