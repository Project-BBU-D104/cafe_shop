import 'package:flutter/material.dart' hide SearchController;
import 'package:frontend/helper/confirm_dialog_helper.dart';
import 'package:frontend/screen/ingredient/widget/ingredient_form_widget.dart';
import 'package:get/get.dart';
import 'package:frontend/services/main_service/ingredient_service.dart';
import 'package:frontend/widget/bottom_sheets.dart';
import 'package:frontend/widget/toast_widget.dart';
import 'package:frontend/controllers/search_controller.dart';
import 'package:frontend/global.dart';
import 'package:frontend/services/api_service.dart';

class IngredientController extends GetxController {

  final IngredientService service = IngredientService();
  final RxList<Map<String, dynamic>> ingredientsList = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final searchIngredientList = <Map<String, dynamic>>[].obs;
  final nameController = TextEditingController();
  final unitController = TextEditingController();
  final currentStockController = TextEditingController();
  final minimumStockController = TextEditingController();
  final costPerUnitController = TextEditingController();
  final isActiveController = true.obs;

  // Last 422 from the API, field => message, shown under the matching form field.
  final RxMap<String, String> serverErrors = <String, String>{}.obs;

  Worker? _searchWorker;

  /// Only these roles may add or change ingredients (same rule as the API).
  bool get canManage {
    final user = storage.lastUserLoginRead['user'];
    final String role = user is Map ? (user['role'] ?? '').toString() : '';

    return const ['owner', 'admin', 'manager'].contains(role);
  }

  @override
  void onInit() {
    super.onInit();
    onGetIngredients();

    final search = Get.put(SearchController());

    // Shared search box: drop any leftover keyword from another screen.
    search.clear();

    _searchWorker = ever(
      search.keyword,
      (keyword) {
        onSearchIngredient(keyword);
      }
    );
  }

  @override
  void onClose() {
    _searchWorker?.dispose();
    nameController.dispose();
    unitController.dispose();
    currentStockController.dispose();
    minimumStockController.dispose();
    costPerUnitController.dispose();
    super.onClose();
  }

  void onClear(){
    // Clear form
    nameController.clear();
    unitController.clear();
    currentStockController.clear();
    minimumStockController.clear();
    costPerUnitController.clear();
    isActiveController.value = true;
    serverErrors.clear();
  }

  Future<void> onGetIngredients() async {
    // Cashiers cannot read ingredients; skip the guaranteed 403.
    if (!canManage) return;

    try {
      isLoading.value = true;

      final resp = await service.getIngredients();

      if (resp is Map && resp['data'] is List) {
      final List<dynamic> data = resp['data'];

      ingredientsList.assignAll(
        data.map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );

      // Keep the active search keyword applied to the fresh list.
      onSearchIngredient(Get.put(SearchController()).keyword.value);

      } else {
        ingredientsList.clear();
        searchIngredientList.clear();
      }
    } catch (e) {
      ToastWidget.show(
        message: 'Failed to load ingredients: $e',
        type: ToastType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void onAddIngredient(BuildContext context) {
    // The edit sheet fills the same controllers; start from a blank form.
    onClear();

    AppBottomSheets.show(
      context,
      child: IngredientFormWidget(
        title: 'Add Ingredient',
        onSave: onSaveIngredient,
      ),
    );
  }

  void onSearchIngredient(String keyword){
    final search = keyword.trim().toLowerCase();

    if (search.isEmpty) {
      searchIngredientList.value = ingredientsList;
      return;
    }

    searchIngredientList.value = ingredientsList.where((ingredient) {
      return (ingredient["name"] ?? "").toString().toLowerCase().contains(search);
    }).toList();
  }

  Map<String, dynamic> _buildPayload({bool includeStock = true}) {
    final stockText = currentStockController.text.trim();
    final minText = minimumStockController.text.trim();
    final costText = costPerUnitController.text.trim();

    return {
      'name': nameController.text.trim(),
      'unit': unitController.text.trim(),
      // Empty means zero, so clearing a field actually resets it on update.
      if (includeStock) 'current_stock': stockText.isEmpty ? '0' : stockText,
      'minimum_stock': minText.isEmpty ? '0' : minText,
      'cost_per_unit': costText.isEmpty ? '0' : costText,
      'is_active': isActiveController.value,
    };
  }

  static const _formFields = {
    'name',
    'unit',
    'current_stock',
    'minimum_stock',
    'cost_per_unit',
    'is_active',
  };

  void _handleSaveError(Object e) {
    if (e is ValidationException) {
      // Show each message under its own field instead of a generic toast.
      serverErrors.assignAll(
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
      if (!e.errors.keys.any(_formFields.contains)) {
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

  // The user can dismiss the sheet while a request runs; a blind Get.back()
  // would then pop this screen instead.
  void _closeSheet() {
    if (Get.routing.route is ModalBottomSheetRoute) {
      Get.back();
    }
  }

  Future<void> onSaveIngredient() async{

    try{
      isLoading.value = true;
      serverErrors.clear();

      await service.createIngredient(_buildPayload());

      await onGetIngredients();

      onClear();
      _closeSheet();

      ToastWidget.show(
        message: 'Ingredient saved successfully',
        type: ToastType.success,
      );
    }catch(e){
      _handleSaveError(e);
    }finally{
      isLoading.value = false;
    }
  }

  Future<void> onEditIngredient(
    BuildContext context,
    int ingredientId,
  ) async {
    try {

      isLoading.value = true;

      final response = await service.getIngredientById(ingredientId);

      dynamic ingredient = response;

      if (response is Map && response['data'] != null) {
        ingredient = response['data'];
      }

      if (ingredient is List && ingredient.isNotEmpty) {
        ingredient = ingredient.first;
      }

      if (ingredient is! Map) {
        throw Exception('Invalid ingredient response: $response');
      }

      // Fill the edit form.
      nameController.text =
          (ingredient['name'] ?? '').toString();

      unitController.text =
          (ingredient['unit'] ?? '').toString();

      minimumStockController.text =
          (ingredient['minimum_stock'] ?? ingredient['minimumStock'] ?? '')
              .toString();

      costPerUnitController.text =
          (ingredient['cost_per_unit'] ?? ingredient['costPerUnit'] ?? '')
              .toString();

      final active = ingredient['is_active'] ?? ingredient['isActive'];

      isActiveController.value =
          active == true ||
          active == 1 ||
          active == '1' ||
          active == 'true';

      serverErrors.clear();

      if (!context.mounted) return;

      AppBottomSheets.show(
        context,
        child: IngredientFormWidget(
          title: 'Edit Ingredient',
          // Stock changes go through inventory movements, not this form.
          showCurrentStock: false,
          onSave: () => onUpdateIngredient(ingredientId),
        ),
      );
    } catch (e) {
      ToastWidget.show(
        message: 'Failed to open edit ingredient: $e',
        type: ToastType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onUpdateIngredient(int ingredientId) async {
    try {
      isLoading.value = true;
      serverErrors.clear();

      await service.updateIngredient(
        ingredientId,
        _buildPayload(includeStock: false),
      );

      // Refresh
      await onGetIngredients();
      onClear();
      _closeSheet();

      ToastWidget.show(
        message: 'Ingredient updated successfully',
        type: ToastType.success,
      );
    } catch (e) {
      _handleSaveError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onDeleteIngredient(int ingredientId, BuildContext context) async{
   showConfirmDialog(
      context: context,
      message: "Do you want to delete this ingredient?".tr,
      onConfirm: () async {
        try{
          await service.deleteIngredient(ingredientId);

          // Refresh ingredient list
          await onGetIngredients();

          ToastWidget.show(
            message: "Ingredient deleted successfully".tr,
            type: ToastType.success,
          );
        }catch(e){
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
}