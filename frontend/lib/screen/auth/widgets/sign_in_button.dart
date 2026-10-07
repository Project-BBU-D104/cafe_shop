import 'package:flutter/material.dart';
import 'package:frontend/controllers/login_controller.dart';
import 'package:get/get.dart';

class SignInButton
    extends
        StatelessWidget {
  final LoginController loginCtr;

  const SignInButton({
    super.key,
    required this.loginCtr,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 30,
        child: ElevatedButton(
          onPressed: loginCtr.isLoading.value
              ? null
              : loginCtr.login,

          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(
              0xFF35180C,
            ),
            disabledBackgroundColor:
                const Color(
                  0xFF35180C,
                ).withValues(
                  alpha: 0.6,
                ),
            foregroundColor: Colors.white,
            elevation: 0,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                18,
              ),
            ),
          ),

          child: loginCtr.isLoading.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  "Sign In",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
