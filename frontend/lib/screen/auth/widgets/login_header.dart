import 'package:flutter/material.dart';

class LoginHeader
    extends
        StatelessWidget {
  const LoginHeader({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        // Logo
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Color(
              0xFFFFEEE8,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.coffee_outlined,
            color: Color(
              0xFF35180C,
            ),
            size: 26,
          ),
        ),

        const SizedBox(
          height: 10,
        ),

        // App Name
        const Text(
          "Roast & Brew",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(
              0xFF24130C,
            ),
          ),
        ),

        const SizedBox(
          height: 2,
        ),

        // Subtitle
        Text(
          "Sign in to POS",
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
