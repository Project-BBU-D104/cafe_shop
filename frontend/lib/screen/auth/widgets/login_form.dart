import 'package:flutter/material.dart';
import 'package:frontend/controllers/login_controller.dart';
import 'package:frontend/screen/auth/widgets/email_field.dart';
import 'package:frontend/screen/auth/widgets/password_field.dart';
import 'package:frontend/screen/auth/widgets/sign_in_button.dart';

class LoginForm
    extends
        StatelessWidget {
  final LoginController loginCtr;

  const LoginForm({
    super.key,
    required this.loginCtr,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        14,
        14,
        14,
        13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          7,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.03,
            ),
            blurRadius: 8,
            offset: const Offset(
              0,
              2,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmailField(
            controller: loginCtr.emailController,
          ),

          const SizedBox(
            height: 11,
          ),

          PasswordField(
            controller: loginCtr.passwordController,
          ),

          const SizedBox(
            height: 14,
          ),

          SignInButton(
            loginCtr: loginCtr,
          ),
        ],
      ),
    );
  }
}
