import 'package:flutter/material.dart';
import 'package:frontend/controllers/manage_controller.dart';
import 'package:frontend/widget/card_feature_widget.dart';
import 'package:frontend/widget/search_feature_widget.dart';
import 'package:get/get.dart';

class ManageScreen extends StatelessWidget {
  ManageScreen({super.key});

  final controller = Get.put(ManageController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  SearchFeatureWidget(title: "Search Function".tr,
                    ctr: controller.searchCtr,
                  ),

                  const SizedBox(height: 15),

                  Obx(() {
                    final sections = controller.filteredSections;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var section in sections) ...[
                          Text(
                            section["title"],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: (section["items"] as List).length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _getCrossAxisCount(constraints.maxWidth),
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: _getAspectRatio(constraints.maxWidth),
                            ),
                            itemBuilder: (context, index) {
                              final item = (section["items"] as List)[index];

                              return CardFeatureWidget(
                                title: item["title"],
                                // subtitle: item["subtitle"],
                                icon: item["icon"],
                                onTap: () => controller.goTo(item["route"]),
                              );
                            },
                          ),

                          const SizedBox(height: 15),
                        ],
                      ],
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ✅ RESPONSIVE COLUMNS
  int _getCrossAxisCount(double width) {
    if (width < 600) return 2; // mobile
    if (width < 900) return 3; // tablet
    return 4; // desktop
  }

  // ✅ FIX OVERFLOW BY ADJUSTING HEIGHT
  double _getAspectRatio(double width) {
    if (width < 600) return 1.6;
    if (width < 900) return 1.5;
    return 1.4;
  }
}