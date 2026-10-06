import 'package:flutter/material.dart';
import 'package:frontend/controllers/home_controller.dart';
import 'package:frontend/widget/card_feature_widget.dart';
import 'package:get/get.dart';
class QuickActionWidget extends StatelessWidget {
  QuickActionWidget({super.key});

  final ctr = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    int crossAxisCount = width < 500 ? 2 : 4;

    double aspectRatio;

    if (width < 360) {
      aspectRatio = 1.1;
    } else if (width < 450) {
      aspectRatio = 1.3;
    } 
    else {
      aspectRatio = 1.2;
    }
    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Quick Action".tr,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10,),
          GridView.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            shrinkWrap: true,
            childAspectRatio: aspectRatio,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              CardFeatureWidget(
                onTap: (){
                  // ctr.gotoSale();
                },
                icon: Icons.shopping_cart_outlined,
                title: "Sale",
                
              ),
              CardFeatureWidget(
                onTap: (){
                  ctr.gotoCategory();
                },
                icon: Icons.category_outlined,
                title: "Category",
              ),
              CardFeatureWidget(
                onTap: (){
                  ctr.gotoProduct();
                },
                icon: Icons.inventory_2_outlined,
                title: "Product",
              ),
              CardFeatureWidget(
                onTap: (){
                  // ctr.gotoSupplier();
                },
                icon: Icons.local_shipping_outlined,
                title: "Supplier",
              ),
               
            ],
          )
        ],
      )
    );
  }
}