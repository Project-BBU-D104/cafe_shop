import 'package:flutter/material.dart';

class ApiStatus extends StatelessWidget {
  const ApiStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFF9A4D21),
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 5),

        Text(
          "Laravel API Connected  ·  v1.2",
          style: TextStyle(
            fontSize: 8,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}