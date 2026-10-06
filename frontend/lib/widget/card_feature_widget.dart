import 'package:flutter/material.dart';
import 'package:frontend/constants/constant.dart';
import 'package:get/get.dart';

class CardFeatureWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const CardFeatureWidget({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: titleColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black12,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Icon(icon, size: 28),

            const SizedBox(height: 8),

            Text(
              title.tr,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 4),

            if(subtitle != null && subtitle!.isNotEmpty)
            Text(
              subtitle?.tr ?? '',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}