import 'package:flutter/material.dart';
import 'package:frontend/controllers/login_controller.dart';
import 'package:frontend/screen/auth/widgets/api_status.dart';
import 'package:frontend/screen/auth/widgets/login_form.dart';
import 'package:frontend/screen/auth/widgets/login_header.dart';
import 'package:get/get.dart';

class LoginScreen
    extends
        StatelessWidget {
  LoginScreen({
    super.key,
  });

  final loginCtr = Get.put(
    LoginController(),
  );

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFFFF9F7,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    const LoginHeader(),

                    const SizedBox(
                      height: 18,
                    ),

                    LoginForm(
                      loginCtr: loginCtr,
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    const ApiStatus(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
