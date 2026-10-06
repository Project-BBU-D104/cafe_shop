import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LanguageController extends GetxController {
  final box = GetStorage();

  static const String storageKey = "language";

  final locale = const Locale("en", "US").obs;

  @override
  void onInit() {
    super.onInit();

    String? language = box.read(storageKey);

    if (language != null) {
      changeLanguage(language);
    }
  }

  void changeLanguage(String languageCode) {
    Locale newLocale;

    if (languageCode == "en") {
      newLocale = const Locale("en", "US");
    } else {
      newLocale = const Locale("km", "KH");
    }

    locale.value = newLocale;

    Get.updateLocale(newLocale);

    box.write(storageKey, languageCode);
  }
}