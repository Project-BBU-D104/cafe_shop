import 'package:flutter/material.dart' hide SearchController;
import 'package:frontend/helper/confirm_dialog_helper.dart';
import 'package:frontend/screen/product_variant/widget/edit_product_variant_widget.dart';
import 'package:get/get.dart';
import 'package:frontend/screen/product_variant/widget/add_product_variant_widget.dart';
import 'package:frontend/screen/product_variant/widget/select_product_widget.dart';
import 'package:frontend/services/main_service/product_service.dart';
import 'package:frontend/services/main_service/product_variant_service.dart';
import 'package:frontend/widget/bottom_sheets.dart';
import 'package:frontend/widget/toast_widget.dart';
import 'package:frontend/controllers/search_controller.dart';
import 'package:frontend/global.dart';
import 'package:frontend/utils/helper.dart';

class ProductVariantController extends GetxController {

  final ProductVariantService service = ProductVariantService();
  final ProductService productService = ProductService();

  // Product the variants belong to; set from Get.arguments when tapped from
  // the product list, otherwise picked via the fallback sheet.
  final Rxn<Map<String, dynamic>> product = Rxn<Map<String, dynamic>>();

  final RxList<Map<String, dynamic>> variantsList = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> productsForSelect = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final searchVariantList = <Map<String, dynamic>>[].obs;
  final variantNameController = TextEditingController();
  final variantPriceController = TextEditingController();
  final isDefaultController = false.obs;
  final isAvailableController = true.obs;

  int? get productId => int.tryParse((product.value?['id'] ?? '').toString());

  /// Only these roles may add or change variants (same rule as the API).
  bool get canManage {
    final user = storage.lastUserLoginRead['user'];
    final String role = user is Map ? (user['role'] ?? '').toString() : '';

    return const ['owner', 'admin', 'manager'].contains(role);
  }

  @override
  void onClose() {
    variantNameController.dispose();
    variantPriceController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    if (args is Map && args['id'] != null) {
      product.value = Map<String, dynamic>.from(args);
    }

    final search = Get.put(SearchController());

    // Shared search box: drop any leftover keyword from another screen.
    search.clear();

    ever(
      search.keyword,
      (keyword) {
        onSearchVariant(keyword);
      }
    );

    if (product.value != null) {
      onGetVariants();
    }
  }

  void onClearForm() {
    // Clear form
    variantNameController.clear();
    variantPriceController.clear();
    isDefaultController.value = false;
    isAvailableController.value = true;
  }

  // The user can dismiss the sheet while a request runs; a blind Get.back()
  // would then pop this screen instead.
  void _closeSheet() {
    if (Get.routing.route is ModalBottomSheetRoute) {
      Get.back();
    }
  }

  Future<void> onGetVariants() async {
    final int? id = productId;

    if (id == null) return;

    try {
      isLoading.value = true;

      final resp = await service.getVariants(id);

      if (resp is Map && resp['data'] is List) {
        final List<dynamic> data = resp['data'];

        variantsList.assignAll(
          data.map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );

        // Keep the active search keyword applied to the fresh list.
        onSearchVariant(Get.put(SearchController()).keyword.value);
      } else {
        variantsList.clear();
        searchVariantList.clear();
      }
    } catch (e) {
      ToastWidget.show(
        message: 'Failed to load variants: $e',
        type: ToastType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void onAddVariant(BuildContext context) {
    onClearForm();

    AppBottomSheets.show(
      context,
      child: AddProductVariantWidget(),
    );
  }

  void onSearchVariant(String keyword) {
    final search = keyword.trim().toLowerCase();

    if (search.isEmpty) {
      searchVariantList.value = variantsList;
      return;
    }

    searchVariantList.value = variantsList.where((variant) {
      return (variant["name"] ?? "").toString().toLowerCase().contains(search);
    }).toList();
  }

  Future<void> onSaveVariant() async {
    final int? id = productId;

    if (id == null) return;

    final String name = variantNameController.text.trim();
    final double price = double.tryParse(variantPriceController.text.trim()) ?? 0;
    final bool isDefault = isDefaultController.value;
    final bool isAvailable = isAvailableController.value;

    try {
      isLoading.value = true;

      final Map<String, dynamic> data = {
        'name': name,
        'price': price,
        'is_default': isDefault,
        'is_available': isAvailable,
      };

      await service.createVariant(id, data);

      await onGetVariants();

      onClearForm();
      _closeSheet();

      ToastWidget.show(
        message: 'Variant saved successfully',
        type: ToastType.success,
      );
    } catch (e) {
      ToastWidget.show(
        message: e.toString(),
        type: ToastType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onEditVariant(
    BuildContext context,
    int variantId,
  ) async {
    final int? id = productId;

    if (id == null) return;

    // A second tap while the fetch runs would stack two edit sheets.
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      final response = await service.getVariantById(id, variantId);

      dynamic variant = response;

      if (response is Map && response['data'] != null) {
        variant = response['data'];
      }

      if (variant is List && variant.isNotEmpty) {
        variant = variant.first;
      }

      if (variant is! Map) {
        throw Exception('Invalid variant response: $response');
      }

      // Fill the edit form.
      variantNameController.text =
          (variant['name'] ?? '').toString();

      // Price already arrives as a "4.50" string; toString keeps num readable.
      variantPriceController.text =
          (variant['price'] ?? '').toString();

      isDefaultController.value =
          asBool(variant['is_default'] ?? variant['isDefault']);

      isAvailableController.value =
          asBool(variant['is_available'] ?? variant['isAvailable']);

      if (!context.mounted) return;

      AppBottomSheets.show(
        context,
        child: EditProductVariantWidget(
          variantId: variantId,
        ),
      );
    } catch (e) {
      ToastWidget.show(
        message: 'Failed to open edit variant: $e',
        type: ToastType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onUpdateVariant(int variantId) async {
    final int? id = productId;

    final String name = variantNameController.text.trim();
    final double? price = double.tryParse(variantPriceController.text.trim());

    if (id == null) return;

    // Validate variant fields.
    if (name.isEmpty) {
      ToastWidget.show(
        message: 'Variant name is required',
        type: ToastType.error,
      );
      return;
    }

    if (price == null || price < 0) {
      ToastWidget.show(
        message: 'Please enter a valid price',
        type: ToastType.error,
      );
      return;
    }

    try {
      isLoading.value = true;

      // Data to send to the API.
      final Map<String, dynamic> data = {
        'name': name,
        'price': price,
        'is_default': isDefaultController.value,
        'is_available': isAvailableController.value,
      };

      // Update the existing variant.
      await service.updateVariant(id, variantId, data);

      // Refresh
      await onGetVariants();
      onClearForm();
      _closeSheet();

      ToastWidget.show(
        message: 'Variant updated successfully',
        type: ToastType.success,
      );
    } catch (e) {
      ToastWidget.show(
        message: 'Failed to update variant: $e',
        type: ToastType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onDeleteVariant(int variantId, BuildContext context) async {
    showConfirmDialog(
      context: context,
      message: "Do you want to delete this variant?".tr,
      onConfirm: () async {
        final int? id = productId;

        if (id == null) return;

        try {
          await service.deleteVariant(id, variantId);

          // Refresh variant list
          await onGetVariants();

          ToastWidget.show(
            message: "Variant deleted successfully".tr,
            type: ToastType.success,
          );
        } catch (e) {
          ToastWidget.show(
            message: e.toString(),
            type: ToastType.error,
          );
        }
      },
      onCancel: () {
        // Do nothing
      },
    );
  }

  Future<void> onSelectProduct(BuildContext context) async {
    // A second tap while the fetch runs would stack two sheets.
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      final resp = await productService.getProducts();

      if (resp is Map && resp['data'] is List) {
        final List<dynamic> data = resp['data'];

        productsForSelect.assignAll(
          data.map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );
      } else {
        productsForSelect.clear();
      }

      if (!context.mounted) return;

      AppBottomSheets.show(
        context,
        child: SelectProductWidget(),
      );
    } catch (e) {
      ToastWidget.show(
        message: 'Failed to load products: $e',
        type: ToastType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void onProductSelected(Map<String, dynamic> selected) {
    Get.back();

    product.value = selected;

    // Reset the shared search box so the new product's variants show unfiltered.
    Get.put(SearchController()).clear();

    onGetVariants();
  }
}
