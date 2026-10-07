import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchController extends GetxController {

  final TextEditingController textController = TextEditingController();

  final RxString keyword = ''.obs;

  @override
  void onInit() {
    super.onInit();

    debounce(
      keyword,
      (value) {
        keyword.value = value.trim();
      },
      time: const Duration(milliseconds: 500),
    );

    textController.addListener(() {
      keyword.value = textController.text;
    });
  }

  void clear() {
    textController.clear();
    keyword.value = "";
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}