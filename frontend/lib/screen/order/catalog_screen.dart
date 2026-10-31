import 'package:flutter/material.dart';
import 'package:frontend/controllers/cart_controller.dart';
import 'package:frontend/routes/app_routes.dart';
import 'package:frontend/widget/custom_app_bar.dart';
import 'package:frontend/widget/toast_widget.dart';
import 'package:get/get.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  // Shared POS cart: registered permanent in HomeScreen; put is the fallback
  // if the screen is ever reached without the shell.
  final CartController cart = Get.isRegistered<CartController>()
      ? Get.find<CartController>()
      : Get.put(CartController(), permanent: true);

  @override
  void initState() {
    super.initState();

    if (cart.products.isEmpty && !cart.isLoadingProducts.value) {
      cart.loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'New Order',
        actions: [
          Obx(() => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Badge(
                  isLabelVisible: cart.itemCount > 0,
                  label: Text('${cart.itemCount}'),
                  child: IconButton(
                    tooltip: 'Cart',
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () => Get.toNamed(AppRoutes.cart, id: 1),
                  ),
                ),
              )),
        ],
      ),
      body: Obx(() {
        if (cart.isLoadingProducts.value && cart.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (cart.catalogError.value != null && cart.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(cart.catalogError.value!,
                      textAlign: TextAlign.center),
                ),
                ElevatedButton(
                  onPressed: cart.loadProducts,
                  child: Text('Retry'.tr),
                ),
              ],
            ),
          );
        }

        if (cart.products.isEmpty) {
          return Center(child: Text('No products available'.tr));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: cart.products.length,
          itemBuilder: (context, index) {
            final product = cart.products[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.local_cafe),
                title: Text((product['name'] ?? '').toString()),
                subtitle: (product['description'] ?? '').toString().isEmpty
                    ? null
                    : Text(
                        (product['description'] ?? '').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () => _openVariants(context, product),
              ),
            );
          },
        );
      }),
    );
  }

  Future<void> _openVariants(
      BuildContext context, Map<String, dynamic> product) async {
    final int? productId = int.tryParse((product['id'] ?? '').toString());

    if (productId == null) return;

    // Fetch before the sheet so its first frame already has data or a spinner.
    await cart.loadVariants(productId);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _VariantSheet(cart: cart, product: product),
    );
  }
}

class _VariantSheet extends StatefulWidget {
  const _VariantSheet({required this.cart, required this.product});

  final CartController cart;
  final Map<String, dynamic> product;

  @override
  State<_VariantSheet> createState() => _VariantSheetState();
}

class _VariantSheetState extends State<_VariantSheet> {
  final Map<int, int> _quantities = {};

  int _quantityOf(int id) => _quantities[id] ?? 1;

  @override
  Widget build(BuildContext context) {
    final int productId =
        int.tryParse((widget.product['id'] ?? '').toString()) ?? 0;
    final String productName = (widget.product['name'] ?? '').toString();

    return SafeArea(
      child: Obx(() {
        if (widget.cart.loadingVariantIds.contains(productId)) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final variants = widget.cart.variantsFor(productId);

        if (variants.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(child: Text('No available variants'.tr)),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                productName,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: variants.length,
                itemBuilder: (context, index) {
                  final variant = variants[index];
                  final int variantId =
                      int.tryParse((variant['id'] ?? '').toString()) ?? 0;

                  return ListTile(
                    title: Text((variant['name'] ?? '').toString()),
                    subtitle: Text('\$${variant['price']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _quantityOf(variantId) <= 1
                              ? null
                              : () => setState(
                                  () => _quantities[variantId] = _quantityOf(variantId) - 1),
                        ),
                        Text('${_quantityOf(variantId)}'),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => setState(() =>
                              _quantities[variantId] = _quantityOf(variantId) + 1),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            for (int i = 0; i < _quantityOf(variantId); i++) {
                              widget.cart.addVariant(productName, variant);
                            }

                            ToastWidget.show(
                              message:
                                  '${variant['name']} added to cart',
                              type: ToastType.success,
                            );

                            Navigator.pop(context);
                          },
                          child: Text('Add'.tr),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
