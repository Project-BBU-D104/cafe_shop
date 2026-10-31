import 'package:flutter/material.dart';
import 'package:frontend/controllers/cart_controller.dart';
import 'package:frontend/widget/custom_app_bar.dart';
import 'package:frontend/widget/toast_widget.dart';
import 'package:get/get.dart';

class CartScreen extends StatelessWidget {
  CartScreen({super.key});

  final CartController cart = Get.isRegistered<CartController>()
      ? Get.find<CartController>()
      : Get.put(CartController(), permanent: true);

  static const Map<String, String> _orderTypes = {
    'dine_in': 'Dine in',
    'takeaway': 'Takeaway',
    'delivery': 'Delivery',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Cart'),
      body: Obx(() {
        if (cart.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Your cart is empty'.tr),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  // The catalog is underneath this screen in the flow.
                  onPressed: () => Get.back(id: 1),
                  icon: const Icon(Icons.storefront),
                  label: Text('Browse products'.tr),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: cart.items.length,
                itemBuilder: (context, index) {
                  final line = cart.items.values.elementAt(index);
                  final int variantId = line['product_variant_id'] as int;
                  final int quantity = line['quantity'] as int;
                  final double unitPrice =
                      double.tryParse((line['unit_price'] ?? '').toString()) ??
                          0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(
                        '${line['product_name']}'
                        '${(line['variant_name'] ?? '').toString().isEmpty ? '' : ' — ${line['variant_name']}'}',
                      ),
                      subtitle: Text('\$${line['unit_price']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => cart.decrease(variantId),
                          ),
                          Text('$quantity'),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => cart.increase(variantId),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => cart.remove(variantId),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${(unitPrice * quantity).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            _CheckoutPanel(cart: cart, orderTypes: _orderTypes),
          ],
        );
      }),
    );
  }
}

class _CheckoutPanel extends StatelessWidget {
  const _CheckoutPanel({required this.cart, required this.orderTypes});

  final CartController cart;
  final Map<String, String> orderTypes;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<String>(
                  segments: orderTypes.entries
                      .map(
                        (entry) => ButtonSegment(
                          value: entry.key,
                          label: Text(entry.value.tr),
                        ),
                      )
                      .toList(),
                  selected: {cart.orderType.value},
                  onSelectionChanged: (selection) =>
                      cart.orderType.value = selection.first,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cart.discountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Discount (optional)'.tr,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: const Icon(Icons.percent),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: cart.notesController,
                  decoration: InputDecoration(
                    hintText: 'Notes (optional)'.tr,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: const Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '\$${cart.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Tax and total are calculated by the server.'.tr,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: cart.isCheckingOut.value
                        ? null
                        : () => _onCreateOrder(context),
                    child: cart.isCheckingOut.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Create Order'.tr,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Future<void> _onCreateOrder(BuildContext context) async {
    final String discount = cart.discountController.text.trim();

    if (discount.isNotEmpty &&
        (double.tryParse(discount) == null || double.parse(discount) < 0)) {
      ToastWidget.show(
        message: 'Discount must be a number >= 0'.tr,
        type: ToastType.error,
      );
      return;
    }

    final int? id = await cart.checkout();

    if (id == null) return; // checkout already toasted the failure

    ToastWidget.show(
      message: 'Order #$id created',
      type: ToastType.success,
    );

    // Drop catalog + cart so Back from the detail returns to the order list.
    Get.until((route) => route.isFirst, id: 1);
    Get.toNamed('/orders/$id', arguments: {'id': id}, id: 1);
  }
}
