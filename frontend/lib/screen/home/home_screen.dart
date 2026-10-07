import 'package:flutter/material.dart';
import 'package:frontend/constants/constant.dart';
import 'package:frontend/controllers/home_controller.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Desktop / Tablet
            if (!isMobile)
              Obx(() {
                return NavigationRail(
                  backgroundColor: titleColor,
                  selectedIndex: controller.selectedIndex.value,
                  onDestinationSelected: controller.onTabChanged,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home),
                      label: Text('Home'.tr),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.shopping_bag_outlined),
                      selectedIcon: const Icon(Icons.shopping_bag),
                      label: Text('Manage'.tr),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.receipt_long_outlined),
                      selectedIcon: const Icon(Icons.receipt_long),
                      label: Text('Report'.tr),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.person_2_outlined),
                      selectedIcon: const Icon(Icons.person_2),
                      label: Text('Profile'.tr),
                    ),
                  ],
                );
              }),

            // Page content
            Expanded(
              child: PageView(
                controller: controller.pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: controller.onPageChanged,
                children: controller.tabPages,
              ),
            ),
          ],
        ),
      ),

      // Mobile only
      bottomNavigationBar: isMobile
          ? Obx(() {
              return NavigationBar(
                height: 60,
                backgroundColor: titleColor,
                selectedIndex: controller.selectedIndex.value,
                onDestinationSelected: controller.onTabChanged,
                labelBehavior:
                    NavigationDestinationLabelBehavior.alwaysHide,
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home),
                    label: 'Home'.tr,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.shopping_bag_outlined),
                    selectedIcon: const Icon(Icons.shopping_bag),
                    label: 'Manage'.tr,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.receipt_long_outlined),
                    selectedIcon: const Icon(Icons.receipt_long),
                    label: 'Report'.tr,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_2_outlined),
                    selectedIcon: const Icon(Icons.person_2),
                    label: 'Profile'.tr,
                  ),
                ],
              );
            })
          : null,
    );
  }
}