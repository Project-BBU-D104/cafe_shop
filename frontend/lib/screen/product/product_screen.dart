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

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                          child: const Icon(Icons.inventory_2_outlined),
                        ),
                        title: Text(
                          (product['name'] ?? '').toString(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                isAvailable ? Icons.check_circle : Icons.pause_circle,
                                size: 16,
                                color: isAvailable ? Colors.green.shade700 : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(isAvailable ? 'Available'.tr : 'Unavailable'.tr),
                            ],
                          ),
                        ),
                        onTap: () => Get.toNamed(
                          AppRoutes.productVariant,
                          arguments: product,
                        ),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FilledButton.icon(
                            onPressed: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (_) => AddProductWidget(
                                product: product,
                                onSaved: ctr.onGetProductList,
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: Text('Edit'.tr),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => ctr.onDeleteProduct(context, product),
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.error,
                            ),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: Text('Delete'.tr),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
