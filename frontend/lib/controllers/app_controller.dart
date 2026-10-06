import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:frontend/global.dart';

class AppController extends GetxController {
  final isLoading = true.obs;
  final isAuthorized = false.obs;

  @override
  void onInit() {
    super.onInit();
    onInitState();

    if (kDebugMode) {
      print("Init App");
    }
  }

  @override
  void onClose() {
    super.onClose();

    if (kDebugMode) {
      print("Close App");
    }
  }

  Future<void> onInitState() async {
    bool authorized = false;

    if (isLoading.value) {
      await onDelayed(const Duration(milliseconds: 1500));
    }

     
    authorized = false;

    isAuthorized.value = authorized;
    isLoading.value = false;
  }
}