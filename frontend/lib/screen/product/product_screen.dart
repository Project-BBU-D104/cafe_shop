import 'package:flutter/material.dart';
import 'package:frontend/controllers/product_controller.dart';
import 'package:frontend/screen/product/widget/add_product_widget.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => AddProductWidget(onSaved: ctr.onGetProductList),
        ),
        icon: const Icon(Icons.add_rounded),
        label: Text('Add Product'.tr),
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
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: ctr.products.length,
            itemBuilder: (context, index) {
              final product = ctr.products[index];

              final bool isAvailable =
                  asBool(product['isAvailable'] ?? product['is_available']);

              return ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text((product['name'] ?? '').toString()),
                subtitle: Text(isAvailable ? 'Available' : 'Unavailable'),
                trailing: PopupMenuButton<String>(
                  tooltip: 'Product actions'.tr,
                  onSelected: (action) {
                    if (action == 'edit') {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) => AddProductWidget(
                          product: product,
                          onSaved: ctr.onGetProductList,
                        ),
                      );
                    } else if (action == 'delete') {
                      ctr.onDeleteProduct(context, product);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 20),
                          const SizedBox(width: 10),
                          Text('Edit Product'.tr),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          const SizedBox(width: 10),
                          Text(
                            'Delete Product'.tr,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
