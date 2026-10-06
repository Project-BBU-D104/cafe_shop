import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchFeatureController extends GetxController {

  final TextEditingController textController = TextEditingController();

  final RxString keyword = ''.obs;

  @override
  void onInit() {
    super.onInit();

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
    super.onClose();
  }
}