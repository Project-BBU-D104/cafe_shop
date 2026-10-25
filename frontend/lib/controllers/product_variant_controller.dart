import 'package:flutter/material.dart' hide SearchController;
import 'package:frontend/helper/confirm_dialog_helper.dart';
import 'package:frontend/screen/product_variant/widget/edit_product_variant_widget.dart';
import 'package:get/get.dart';
import 'package:frontend/screen/product_variant/widget/add_product_variant_widget.dart';
import 'package:frontend/screen/product_variant/widget/select_product_widget.dart';
import 'package:frontend/screen/product_variant/widget/recipe_form_widget.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/main_service/ingredient_service.dart';
import 'package:frontend/services/main_service/product_ingredient_service.dart';
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

  // Recipe rows per variant; loaded the first time its section is expanded.
  final ProductIngredientService recipeService = ProductIngredientService();
  final RxMap<int, List<Map<String, dynamic>>> recipes =
      <int, List<Map<String, dynamic>>>{}.obs;
  final RxList<int> expandedRecipeIds = <int>[].obs;
  final RxList<int> loadingRecipeIds = <int>[].obs;
  final RxList<Map<String, dynamic>> ingredientsForRecipe =
      <Map<String, dynamic>>[].obs;
  final RxnInt recipeIngredientId = RxnInt();
  final recipeQuantityController = TextEditingController();
  final RxMap<String, String> recipeServerErrors = <String, String>{}.obs;

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
    recipeQuantityController.dispose();
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

  // --- Recipe (product ingredients) ---------------------------------------

  bool isRecipeExpanded(int variantId) => expandedRecipeIds.contains(variantId);

  bool isRecipeLoading(int variantId) => loadingRecipeIds.contains(variantId);

  List<Map<String, dynamic>> recipeFor(int variantId) =>
      recipes[variantId] ?? const [];

  /// Active ingredients that are not bound to this variant yet.
  List<Map<String, dynamic>> availableRecipeIngredients(int variantId) {
    final bound = recipeFor(variantId)
        .map((row) => (row['ingredient_id'] ?? '').toString())
        .toSet();

    return ingredientsForRecipe.where((ingredient) {
      return asBool(ingredient['is_active'] ?? true) &&
          !bound.contains((ingredient['id'] ?? '').toString());
    }).toList();
  }

  Map<String, dynamic>? get selectedRecipeIngredient {
    final int? id = recipeIngredientId.value;

    if (id == null) return null;

    for (final ingredient in ingredientsForRecipe) {
      if ((ingredient['id'] ?? '').toString() == id.toString()) {
        return ingredient;
      }
    }

    return null;
  }

  /// Positive quantity with at most 3 decimals, mirroring the API rule.
  static String? validateRecipeQuantity(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return 'Quantity is required';

    final number = double.tryParse(text);

    if (number == null || number <= 0) {
      return 'Enter a quantity greater than 0';
    }

    final decimals = text.contains('.') ? text.split('.').last.length : 0;

    if (decimals > 3) return 'Use at most 3 decimal places';

    return null;
  }

  @visibleForTesting
  Map<String, dynamic> buildRecipePayload() {
    final unit = (selectedRecipeIngredient?['unit'] ?? '').toString();

    return {
      'ingredient_id': recipeIngredientId.value,
      'quantity': recipeQuantityController.text.trim(),
      // The API pins the unit to the ingredient's unit; send the same value.
      if (unit.isNotEmpty) 'unit': unit,
    };
  }

  Future<void> onToggleRecipe(int variantId) async {
    if (expandedRecipeIds.contains(variantId)) {
      expandedRecipeIds.remove(variantId);
      return;
    }

    expandedRecipeIds.add(variantId);

    if (!recipes.containsKey(variantId)) {
      await onGetRecipe(variantId);
    }
  }

  Future<void> onGetRecipe(int variantId) async {
    try {
      loadingRecipeIds.add(variantId);

      final resp = await recipeService.getRecipe(variantId);

      final List<dynamic> data =
          resp is Map && resp['data'] is List ? resp['data'] as List : [];

      recipes[variantId] = data
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();
    } catch (e) {
      // Collapse so the section doesn't claim "no ingredients"; the next tap
      // retries, because recipes still has no entry for this variant.
      expandedRecipeIds.remove(variantId);

      ToastWidget.show(
        message: 'Failed to load recipe: $e',
        type: ToastType.error,
      );
    } finally {
      loadingRecipeIds.remove(variantId);
    }
  }

  Future<void> onAddRecipeIngredient(
    BuildContext context,
    int variantId,
  ) async {
    // A second tap while the fetch runs would stack two sheets.
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      if (ingredientsForRecipe.isEmpty) {
        final resp = await IngredientService().getIngredients();

        if (resp is Map && resp['data'] is List) {
          ingredientsForRecipe.assignAll(
            (resp['data'] as List).map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item as Map),
            ),
          );
        }
      }

      if (availableRecipeIngredients(variantId).isEmpty) {
        ToastWidget.show(
          message: 'No ingredients left to add',
          type: ToastType.error,
        );
        return;
      }

      recipeServerErrors.clear();
      recipeIngredientId.value = null;
      recipeQuantityController.clear();

      if (!context.mounted) return;

      AppBottomSheets.show(
        context,
        child: RecipeFormWidget(
          title: 'Add Ingredient',
          variantId: variantId,
        ),
      );
    } catch (e) {
      ToastWidget.show(
        message: 'Failed to load ingredients: $e',
        type: ToastType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void onEditRecipeIngredient(
    BuildContext context,
    int variantId,
    Map<String, dynamic> row,
  ) {
    final ingredient = row['ingredient'];

    recipeServerErrors.clear();
    recipeIngredientId.value =
        int.tryParse((row['ingredient_id'] ?? '').toString());
    recipeQuantityController.text = (row['quantity'] ?? '').toString();

    AppBottomSheets.show(
      context,
      child: RecipeFormWidget(
        title: 'Edit Quantity',
        variantId: variantId,
        isEdit: true,
        ingredientName: ingredient is Map
            ? (ingredient['name'] ?? '').toString()
            : 'Ingredient',
        unit: (row['unit'] ?? '').toString(),
      ),
    );
  }

  Future<void> onSaveRecipeIngredient(
    int variantId, {
    int? ingredientId,
  }) async {
    final String? quantityError =
        validateRecipeQuantity(recipeQuantityController.text);

    if (quantityError != null) {
      recipeServerErrors['quantity'] = quantityError;
      return;
    }

    if (ingredientId == null && recipeIngredientId.value == null) {
      recipeServerErrors['ingredient_id'] = 'Select an ingredient';
      return;
    }

    try {
      isLoading.value = true;
      recipeServerErrors.clear();

      if (ingredientId == null) {
        await recipeService.addIngredient(variantId, buildRecipePayload());
      } else {
        await recipeService.updateQuantity(variantId, ingredientId, {
          'quantity': recipeQuantityController.text.trim(),
        });
      }

      await onGetRecipe(variantId);
      _closeSheet();

      ToastWidget.show(
        message: ingredientId == null
            ? 'Ingredient added to recipe'
            : 'Quantity updated',
        type: ToastType.success,
      );
    } catch (e) {
      handleRecipeError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onRemoveRecipeIngredient(
    BuildContext context,
    int variantId,
    int ingredientId,
  ) async {
    showConfirmDialog(
      context: context,
      message: 'Remove this ingredient from the recipe?',
      onConfirm: () async {
        try {
          await recipeService.removeIngredient(variantId, ingredientId);
          await onGetRecipe(variantId);

          ToastWidget.show(
            message: 'Ingredient removed from recipe',
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

  // Fields the form can display an error under.
  static const _recipeFields = {'ingredient_id', 'quantity'};

  @visibleForTesting
  void handleRecipeError(Object e) {
    if (e is ValidationException) {
      // Show each message under its own field instead of a generic toast.
      recipeServerErrors.assignAll(
        e.errors.map(
          (field, messages) => MapEntry(
            field,
            messages is List && messages.isNotEmpty
                ? messages.first.toString()
                : messages.toString(),
          ),
        ),
      );

      // Nothing maps to a visible field — fall back so the user isn't stuck.
      if (!e.errors.keys.any(_recipeFields.contains)) {
        ToastWidget.show(
          message: e.message,
          type: ToastType.error,
        );
      }
      return;
    }

    ToastWidget.show(
      message: e.toString(),
      type: ToastType.error,
    );
  }
}
