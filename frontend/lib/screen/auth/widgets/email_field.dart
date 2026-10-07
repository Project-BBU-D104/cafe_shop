import 'package:flutter/material.dart';

class EmailField
    extends
        StatelessWidget {
  final TextEditingController controller;

  const EmailField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Email Address",
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w500,
            color: Color(
              0xFF24130C,
            ),
          ),
        ),

        const SizedBox(
          height: 5,
        ),

        TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(
            fontSize: 11,
            color: Color(
              0xFF3D2A23,
            ),
          ),
          decoration: InputDecoration(
            hintText: "cashier@roastbrew.com",
            hintStyle: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),

            prefixIcon: const Icon(
              Icons.alternate_email,
              size: 15,
              color: Color(
                0xFF35180C,
              ),
            ),

            filled: true,
            fillColor: const Color(
              0xFFFFF0EB,
            ),

            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 10,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                20,
              ),
              borderSide: BorderSide.none,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                20,
              ),
              borderSide: BorderSide.none,
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                20,
              ),
              borderSide: const BorderSide(
                color: Color(
                  0xFF35180C,
                ),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
