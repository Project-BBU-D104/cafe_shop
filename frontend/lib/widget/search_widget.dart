import 'package:flutter/material.dart' hide SearchController;
import 'package:frontend/constants/constant.dart';
import 'package:get/get.dart';
import 'package:frontend/controllers/search_controller.dart';

class SearchWidget extends StatelessWidget {
  final String title;

  SearchWidget({
    super.key,
    required this.title,
  });

  final ctr = Get.put(SearchController());

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: ctr.textController,

        decoration: InputDecoration(
        hintText: title.tr,

        prefixIcon: const Icon(Icons.search),

      suffixIcon: Obx(() {
        return ctr.keyword.value.isEmpty
            ? const SizedBox()
            : IconButton(
                onPressed: ctr.clear,
                icon: const Icon(Icons.close),
              );
      }),

        border: InputBorder.none,
      ),
    )
  );
  }
}