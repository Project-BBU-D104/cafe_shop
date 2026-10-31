import 'package:flutter/material.dart';
import 'package:frontend/services/main_service/order_service.dart';
import 'package:frontend/services/main_service/product_service.dart';
import 'package:frontend/services/main_service/product_variant_service.dart';
import 'package:frontend/utils/helper.dart';
import 'package:frontend/widget/toast_widget.dart';
import 'package:get/get.dart';

/// POS cart + catalog state. Registered once (permanent) in HomeScreen so the
/// cart survives tab switches and pushes to catalog/cart screens.
class CartController extends GetxController {
  final OrderService service = OrderService();
  final ProductService productService = ProductService();
  final ProductVariantService variantService = ProductVariantService();

  // --- Catalog -------------------------------------------------------------

  final RxList<Map<String, dynamic>> products = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingProducts = false.obs;
  final RxnString catalogError = RxnString();

  // Variants per product, fetched once per product per session.
  final RxMap<int, List<Map<String, dynamic>>> variantsCache =
      <int, List<Map<String, dynamic>>>{}.obs;
  final RxList<int> loadingVariantIds = <int>[].obs;

  Future<void> loadProducts() async {
    try {
      isLoadingProducts.value = true;
      catalogError.value = null;

      final resp = await productService.getAvailableProducts();

      if (resp is Map && resp['data'] is List) {
        products.assignAll(
          (resp['data'] as List).map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );
      } else {
        products.clear();
      }
    } catch (e) {
      catalogError.value = e.toString();
    } finally {
      isLoadingProducts.value = false;
    }
  }

  List<Map<String, dynamic>> variantsFor(int productId) =>
      variantsCache[productId] ?? const [];

  Future<void> loadVariants(int productId) async {
    if (variantsCache.containsKey(productId)) return;

    try {
      loadingVariantIds.add(productId);

      final resp = await variantService.getVariants(productId);

      final List<dynamic> data =
          resp is Map && resp['data'] is List ? resp['data'] as List : [];

      variantsCache[productId] = data
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .where((variant) => asBool(variant['is_available']))
          .toList();
    } catch (e) {
      // No cache entry, so the next tap retries.
      ToastWidget.show(
        message: 'Failed to load variants: $e',
        type: ToastType.error,
      );
    } finally {
      loadingVariantIds.remove(productId);
    }
  }

  // --- Cart ------------------------------------------------------------------

  /// Lines keyed by product_variant_id.
  final RxMap<int, Map<String, dynamic>> items = <int, Map<String, dynamic>>{}.obs;

  final RxString orderType = 'dine_in'.obs;
  final TextEditingController discountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final RxBool isCheckingOut = false.obs;

  @override
  void onClose() {
    discountController.dispose();
    notesController.dispose();
    super.onClose();
  }

  /// Prices arrive as decimal strings ("2.50").
  void addVariant(String productName, Map<String, dynamic> variant) {
    final int? id = int.tryParse((variant['id'] ?? '').toString());

    if (id == null) return;

    final existing = items[id];

    if (existing != null) {
      items[id] = {
        ...existing,
        'quantity': (existing['quantity'] as int) + 1,
      };
      return;
    }

    items[id] = {
      'product_variant_id': id,
      'product_name': productName,
      'variant_name': (variant['name'] ?? '').toString(),
      'unit_price': (variant['price'] ?? '0').toString(),
      'quantity': 1,
    };
  }

  void increase(int variantId) {
    final line = items[variantId];

    if (line == null) return;

    items[variantId] = {...line, 'quantity': (line['quantity'] as int) + 1};
  }

  /// Drops the line when the last unit is removed.
  void decrease(int variantId) {
    final line = items[variantId];

    if (line == null) return;

    final int quantity = (line['quantity'] as int) - 1;

    if (quantity <= 0) {
      items.remove(variantId);
    } else {
      items[variantId] = {...line, 'quantity': quantity};
    }
  }

  void remove(int variantId) => items.remove(variantId);

  void clear() {
    items.clear();
    orderType.value = 'dine_in';
    discountController.clear();
    notesController.clear();
  }

  int get itemCount =>
      items.values.fold(0, (sum, line) => sum + line['quantity'] as int);

  double get subtotal => items.values.fold(
        0,
        (sum, line) =>
            sum +
            (double.tryParse((line['unit_price'] ?? '').toString()) ?? 0) *
                (line['quantity'] as int),
      );

  @visibleForTesting
  Map<String, dynamic> buildOrderPayload() {
    final String discount = discountController.text.trim();
    final String notes = notesController.text.trim();

    return {
      'type': orderType.value,
      'items': items.values
          .map(
            (line) => {
              'product_variant_id': line['product_variant_id'],
              'quantity': line['quantity'],
            },
          )
          .toList(),
      if (discount.isNotEmpty) 'discount_amount': discount,
      if (notes.isNotEmpty) 'notes': notes,
      // payment_method deliberately omitted: payment is recorded via /pay.
    };
  }

  /// Creates the order, clears the cart, returns the new order id (null on error).
  Future<int?> checkout() async {
    if (isCheckingOut.value || items.isEmpty) return null;

    try {
      isCheckingOut.value = true;

      final resp = await service.createOrder(buildOrderPayload());

      final int? id = resp is Map && resp['data'] is Map
          ? int.tryParse((resp['data']['id'] ?? '').toString())
          : null;

      if (id == null) throw Exception('Order created but no id returned');

      clear();

      return id;
    } catch (e) {
      ToastWidget.show(
        message: e.toString(),
        type: ToastType.error,
      );

      return null;
    } finally {
      isCheckingOut.value = false;
    }
  }
}
