import 'package:flutter/material.dart';
import 'package:frontend/controllers/search_feature_controller.dart';
import 'package:frontend/routes/app_routes.dart';
import 'package:get/get.dart';

class ManageController extends GetxController{

  final searchCtr = Get.put(SearchFeatureController());
  final RxList<Map<String, dynamic>> filteredSections =
      <Map<String, dynamic>>[].obs;

  final List<Map<String, dynamic>> sections = [   
    {
      "title": "Shop Management",
      "items": [
        {
          "title": "Shift Management",
          "subtitle": "Shift Management",
          "icon": Icons.access_time_outlined,
          "route": AppRoutes.shift,
        },
        {
          "title": "Shop",
          "subtitle": "Product Management",
          "icon": Icons.inventory_2_outlined,
          "route": AppRoutes.product,
        },
      ]
    },
    {
      "title": "Product Management",
      "items": [
        {
          "title": "Category",
          "subtitle": "Category Management",
          "icon": Icons.category_outlined,
          "route": AppRoutes.category,
        },
        {
          "title": "Product",
          "subtitle": "Product Management",
          "icon": Icons.inventory_2_outlined,
          "route": AppRoutes.product,
        },
      ]
    },
    {
      "title": "Inventory Management",
      "items": [
        {
          "title": "Inventory Movements",
          "subtitle": "Inventory Movements",
          "icon": Icons.category_outlined,
          "route": AppRoutes.inventoryMovements,
        },
      ]
    },
    {
      "title": "System Configuration Management",
      "items": [
        {
          "title": "User Management",
          "subtitle": "User Management",
          "icon": Icons.person_outlined,
          "route": AppRoutes.user,
        },
        {
          "title": "Settings",
          "subtitle": "System Settings",
          "icon": Icons.settings_outlined,
          "route": AppRoutes.settings,
        }
      ]
    },
  ];

  @override
  void onInit() {
    super.onInit();

    filteredSections.assignAll(sections);

    ever(searchCtr.keyword, (_) {
      _filter();
    });
  }

  void _filter() {
    final keyword = searchCtr.keyword.value.trim().toLowerCase();

    if (keyword.isEmpty) {
      filteredSections.assignAll(sections);
      return;
    }

    final result = sections
        .map((section) {
          final items = (section["items"] as List)
              .where((item) {
                return item["title"]
                        .toString()
                        .toLowerCase()
                        .contains(keyword) ||
                    item["subtitle"]
                        .toString()
                        .toLowerCase()
                        .contains(keyword);
              })
              .toList();

          if (items.isEmpty) return null;

          return {
            "title": section["title"],
            "items": items,
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    filteredSections.assignAll(result);
  }

  void goTo(String route) {
    Get.toNamed(route);
  }
}