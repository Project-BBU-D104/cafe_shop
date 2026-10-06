import 'package:flutter/material.dart';
import 'package:frontend/constants/constant.dart';
import 'package:frontend/controllers/theme_controller.dart';
import 'package:frontend/widget/dailog_select_language_widget.dart';
import 'package:get/get.dart';

class SettingWidget extends StatelessWidget {
  SettingWidget({super.key});

   final themeController = Get.put(ThemeController());

  @override
  Widget build(BuildContext context) {
    return Card(
      color: titleColor,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.settings_outlined),
                SizedBox(width: 10,),
                Text("App Preferences".tr, style: TextStyle(fontWeight: FontWeight.bold),),
              ],
            ),
            Divider(),
            // Obx(
            //   () => cardInfo(
            //     active: themeController.isDark.value,
            //     icon: Icons.dark_mode_outlined,
            //     title: "Dark Mode".tr,
            //     onSwitch: (value) {
            //       themeController.toggleTheme();
            //     },
            //   ),
            // ),
            SizedBox(height: 5,),
            cardInfo(
              icon: Icons.language_outlined,
              title: "Language".tr,
              onTap: () {
                Get.dialog(
                  const DialogSelectLanguageWidget(),
                );
              },
            ),
            SizedBox(height: 5,),
            cardInfo(
              active: true,
              icon: Icons.lock_outlined,
              title: "Push Notifications".tr,
            ),
          ],
        ),
      )
    );
  }
}

Widget cardInfo({
  required IconData icon,
  required String title,
  bool? active,
  VoidCallback? onTap,
  Function(bool value)? onSwitch,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(Get.context!).iconTheme.color,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Theme.of(Get.context!).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // SWITCH MODE
          if (active != null && onSwitch != null)
            Switch(
              value: active,
              onChanged: onSwitch,
            )
          else if (active == null)
            const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}