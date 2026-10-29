import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                      icon: const Icon(Icons.home_rounded),
                      selectedIcon: const Icon(Icons.home),
                      label: Text('Home'.tr),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.shopping_bag_rounded),
                      selectedIcon: const Icon(Icons.shopping_bag),
                      label: Text('Manage'.tr),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.shopping_cart_rounded),
                      selectedIcon: const Icon(Icons.shopping_cart),
                      label: Text('Order'.tr),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.receipt_long_rounded),
                      selectedIcon: const Icon(Icons.receipt_long),
                      label: Text('Report'.tr),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.person_2_rounded),
                      selectedIcon: const Icon(Icons.person_2),
                      label: Text('Profile'.tr),
                    ),
                  ],
                );
              }),

            // Page content
            Expanded(
              child: PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) {
                  if (didPop) return;
                  final nested = Get.nestedKey(1)?.currentState;
                  if (nested != null && nested.canPop()) {
                    nested.pop();
                  } else {
                    SystemNavigator.pop();
                  }
                },
                // The observer keeps Get.arguments and Get.routing aware of
                // in-shell pushes; GetX only watches the root navigator.
                child: Navigator(
                  key: Get.nestedKey(1),
                  observers: [GetObserver(null, Get.routing)],
                  onGenerateRoute: _onGenerateRoute,
                ),
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
                    icon: const Icon(Icons.shopping_cart_outlined),
                    selectedIcon: const Icon(Icons.shopping_cart),
                    label: 'Order'.tr,
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

  Widget _tabPages() {
    return PageView(
      controller: controller.pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: controller.onPageChanged,
      children: controller.tabPages,
    );
  }

  // Pushed pages render inside this navigator, so the NavigationRail stays put.
  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    // Build from the matched GetPage so its bindings are not dropped.
    final page = Get.routeTree.matchRoute(settings.name ?? '/').route;
    return GetPageRoute(
      settings: settings,
      page: page?.page ?? _tabPages,
      binding: page?.binding,
      bindings: page?.bindings,
    );
  }
}