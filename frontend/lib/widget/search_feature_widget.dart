import 'package:flutter/material.dart';
import 'package:frontend/constants/constant.dart';
import 'package:get/get.dart';
import 'package:frontend/controllers/search_feature_controller.dart';

class SearchFeatureWidget extends StatelessWidget {
  final String title;
  final SearchFeatureController ctr;

  const SearchFeatureWidget({
    super.key,
    required this.title,
    required this.ctr,
  });
 

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: whiteColor, // background color
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: TextField(
        controller: ctr.textController,

        decoration: InputDecoration(
          hintText: title.tr,

          prefixIcon: const Icon(
            Icons.search,
          ),

          suffixIcon: Obx(() {
            return ctr.keyword.value.isEmpty
                ? const SizedBox()
                : IconButton(
                    onPressed: ctr.clear,
                    icon: const Icon(Icons.close),
                  );
          }),

          border: InputBorder.none,

          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
          ),
        ),
      ),
    );
  }
}