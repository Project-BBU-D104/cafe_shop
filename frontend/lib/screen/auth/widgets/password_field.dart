import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController controller;

  const PasswordField({
    super.key,
    required this.controller,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Security Passcode",
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: Color(0xFF24130C),
              ),
            ),

            GestureDetector(
              onTap: () {
                // Forgot password
              },
              child: const Text(
                "Forgot?",
                style: TextStyle(
                  fontSize: 8,
                  color: Color(0xFF35180C),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),

        // Password
        TextField(
          controller: widget.controller,
          obscureText: obscurePassword,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF3D2A23),
            letterSpacing: 2,
          ),
          decoration: InputDecoration(
            hintText: "Password",
            hintStyle: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              letterSpacing: 0,
            ),

            prefixIcon: const Icon(
              Icons.lock_outline,
              size: 15,
              color: Color(0xFF35180C),
            ),

            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  obscurePassword = !obscurePassword;
                });
              },
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 15,
                color: const Color(0xFF35180C),
              ),
            ),

            filled: true,
            fillColor: const Color(0xFFFFF0EB),

            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 10,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(
                color: Color(0xFF35180C),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}