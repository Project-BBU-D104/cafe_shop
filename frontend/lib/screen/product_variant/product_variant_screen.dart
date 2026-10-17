import 'package:flutter/material.dart';
import 'package:frontend/controllers/product_variant_controller.dart';
import 'package:frontend/screen/product_variant/widget/card_product_variant_widget.dart';
import 'package:frontend/widget/custom_app_bar.dart';
import 'package:frontend/widget/search_widget.dart';
import 'package:get/get.dart';

class ProductVariantScreen extends StatelessWidget {
  ProductVariantScreen({super.key});

  final ProductVariantController ctr = Get.put(ProductVariantController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final String productName =
          (ctr.product.value?['name'] ?? '').toString();

      return Scaffold(
        appBar: CustomAppBar(
          title: 'Variants — ${productName.isEmpty ? 'Product' : productName}',
          showBack: true,
          onBack: () => Navigator.pop(context),
        ),
        body: ctr.product.value == null
            ? Center(
                child: ElevatedButton.icon(
                  onPressed: () => ctr.onSelectProduct(context),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: Text('Select Product'.tr),
                ),
              )
            : RefreshIndicator(
                onRefresh: ctr.onGetVariants,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        SearchWidget(
                          title: 'Search Variant',
                        ),
                        const SizedBox(height: 12),
                        Obx(() {
                          if (ctr.isLoading.value &&
                              ctr.variantsList.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (ctr.variantsList.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'No variants found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            );
                          }

                          if (ctr.searchVariantList.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'Search not found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            );
                          }

                          final bool canManage = ctr.canManage;

                          return Column(
                            children: ctr.searchVariantList.map((variant) {
                              // Read-only roles get no menu: the API rejects writes.
                              return CardProductVariantWidget(
                                variant: variant,
                                onEdit: canManage
                                    ? () => ctr.onEditVariant(
                                          context,
                                          variant['id'],
                                        )
                                    : null,
                                onDelete: canManage
                                    ? () => ctr.onDeleteVariant(
                                          variant['id'],
                                          context,
                                        )
                                    : null,
                              );
                            }).toList(),
                          );
                        }),
                        const SizedBox(height: 70),
                      ],
                    ),
                  ),
                ),
              ),
        floatingActionButton: (ctr.product.value == null || !ctr.canManage)
            ? const SizedBox.shrink()
            : FloatingActionButton(
                onPressed: () {
                  ctr.onAddVariant(context);
                },
                child: const Icon(Icons.add),
              ),
      );
    });
  }
}
