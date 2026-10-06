import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:frontend/constants/constant.dart';
import 'package:frontend/controllers/language_controller.dart';
import 'package:get/get.dart';

class DialogSelectLanguageWidget extends StatelessWidget {
  const DialogSelectLanguageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    return Dialog(
      backgroundColor: titleColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Obx(
        () => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.language_rounded,
                size: 50,
                color: Colors.blue,
              ),

              const SizedBox(height: 12),

               Text(
                "Select Language".tr,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Choose your preferred language".tr,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 25),

              _languageTile(
                countryCode: "KH",
                title: "ខ្មែរ",
                subtitle: "Khmer",
                selected:
                    languageController.locale.value.languageCode == "km",
                onTap: () {
                  languageController.changeLanguage("km");
                  Get.back();
                },
              ),

              const SizedBox(height: 15),

              _languageTile(
                countryCode: "US",
                title: "English",
                subtitle: "United States",
                selected:
                    languageController.locale.value.languageCode == "en",
                onTap: () {
                  languageController.changeLanguage("en");
                  Get.back();
                },
              ),
 
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageTile({
    required String countryCode,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? Colors.blue.shade50
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Colors.blue
                : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CountryFlag.fromCountryCode(
              countryCode,
              width: 46,
              height: 34,
              shape: RoundedRectangle(6),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: selected
                  ? const CircleAvatar(
                      radius: 13,
                      backgroundColor: Colors.blue,
                      child: Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.white,
                      ),
                    )
                  : const SizedBox(
                      width: 26,
                      height: 26,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}