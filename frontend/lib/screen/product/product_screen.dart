import 'package:flutter/material.dart';
import 'package:frontend/controllers/product_controller.dart';
import 'package:frontend/routes/app_routes.dart';
import 'package:frontend/utils/helper.dart';
import 'package:frontend/widget/custom_app_bar.dart';
import 'package:get/get.dart';

class ProductScreen extends StatelessWidget {
  ProductScreen({super.key});

  final ProductController ctr = Get.put(ProductController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Product Management',
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: RefreshIndicator(
        onRefresh: ctr.onGetProductList,
        child: Obx(() {
          if (ctr.isLoading.value && ctr.products.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (ctr.products.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No products found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: ctr.products.length,
            itemBuilder: (context, index) {
              final product = ctr.products[index];

              final bool isAvailable =
                  asBool(product['isAvailable'] ?? product['is_available']);

              return ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text((product['name'] ?? '').toString()),
                subtitle: Text(isAvailable ? 'Available' : 'Unavailable'),
                onTap: () {
                  Get.toNamed(
                    AppRoutes.productVariant,
                    arguments: product,
                  );
                },
              );
            },
          );
        }),
      ),
    );
  }
}
