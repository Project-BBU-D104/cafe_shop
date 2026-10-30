import 'package:flutter/material.dart';
import 'package:frontend/global.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/main_service/ingredient_service.dart';
import 'package:frontend/services/main_service/inventory_movement_service.dart';
import 'package:frontend/widget/toast_widget.dart';
import 'package:get/get.dart';

class InventoryMovementController extends GetxController {
  final IngredientService _ingredientService = IngredientService();
  final InventoryMovementService _movementService;

  InventoryMovementController({InventoryMovementService? movementService})
      : _movementService = movementService ?? InventoryMovementService();

  final RxList<Map<String, dynamic>> ingredients =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> movements =
      <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> selectedIngredient = Rxn();
  final RxString movementType = 'stock_in'.obs;

  final quantityController = TextEditingController();
  final unitCostController = TextEditingController();
  final notesController = TextEditingController();

  // Last 422 from the API, field => message, shown under the matching form field.
  final RxMap<String, String> serverErrors = <String, String>{}.obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingMovements = false.obs;
  final RxBool isSaving = false.obs;

  /// Only these roles may record movements (same rule as the API).
  bool get canManage {
    final user = storage.lastUserLoginRead['user'];
    final String role = user is Map ? (user['role'] ?? '').toString() : '';

    return const ['owner', 'admin', 'manager'].contains(role);
  }

  /// Archived ingredients cannot move stock.
  List<Map<String, dynamic>> get selectableIngredients => ingredients
      .where((ingredient) => ingredient['is_active'] != false)
      .toList();

  @override
  void onInit() {
    super.onInit();
    onGetIngredients();
    onGetMovements();
  }

  @override
  void onClose() {
    quantityController.dispose();
    unitCostController.dispose();
    notesController.dispose();
    super.onClose();
  }

  Future<void> onGetIngredients() async {
    // Cashiers cannot read ingredients; skip the guaranteed 403.
    if (!canManage) return;

    try {
      isLoading.value = true;

      final resp = await _ingredientService.getIngredients();

      if (resp is Map && resp['data'] is List) {
        ingredients.assignAll(
          (resp['data'] as List).map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );
      } else {
        ingredients.clear();
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

  Future<void> onGetMovements({bool silent = false}) async {
    // Cashiers cannot read the ledger; skip the guaranteed 403.
    if (!canManage) return;

    try {
      isLoadingMovements.value = true;

      final resp = await _movementService.getMovements();

      if (resp is Map && resp['data'] is List) {
        movements.assignAll(
          (resp['data'] as List).map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );
      } else {
        movements.clear();
      }
    } catch (e) {
      // After a save the movement is already recorded; don't alarm the user
      // with a failed reload.
      if (!silent) {
        ToastWidget.show(
          message: 'Failed to load movements: $e',
          type: ToastType.error,
        );
      }
    } finally {
      isLoadingMovements.value = false;
    }
  }

  Future<void> onRefresh() =>
      Future.wait([onGetIngredients(), onGetMovements()]);

  /// Same limits as StoreInventoryMovementRequest: only an adjustment is signed.
  @visibleForTesting
  String? validateQuantity(String type, String text) {
    final value = double.tryParse(text.trim());

    if (value == null) {
      return 'Enter a valid quantity'.tr;
    }
    if (value == 0) {
      return 'Quantity cannot be zero'.tr;
    }
    if (type != 'adjustment' && value < 0) {
      return 'Quantity must be greater than zero'.tr;
    }
    return null;
  }

  @visibleForTesting
  Map<String, dynamic> buildPayload() {
    final quantityText = quantityController.text.trim();
    final unitCostText = unitCostController.text.trim();
    final notes = notesController.text.trim();

    return {
      'type': movementType.value,
      'quantity': double.tryParse(quantityText) ?? quantityText,
      if (unitCostText.isNotEmpty)
        'unit_cost': double.tryParse(unitCostText) ?? unitCostText,
      if (notes.isNotEmpty) 'notes': notes,
    };
  }

  static const _formFields = {'type', 'quantity', 'unit_cost', 'notes'};

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

  Future<void> onSubmit() async {
    final ingredient = selectedIngredient.value;

    if (ingredient == null) {
      ToastWidget.show(
        message: 'Select an ingredient'.tr,
        type: ToastType.warning,
      );
      return;
    }

    serverErrors.clear();

    final quantityError =
        validateQuantity(movementType.value, quantityController.text);
    if (quantityError != null) {
      serverErrors['quantity'] = quantityError;
      return;
    }

    try {
      isSaving.value = true;

      final resp = await _movementService.createMovement(
        ingredient['id'] as int,
        buildPayload(),
      );

      // The resource loads the ingredient after the stock update, so it is fresh.
      final updated = resp is Map && resp['data'] is Map
          ? resp['data']['ingredient']
          : null;

      if (updated is Map) {
        final fresh = Map<String, dynamic>.from(updated);
        selectedIngredient.value = fresh;

        final index = ingredients.indexWhere((i) => i['id'] == fresh['id']);
        if (index != -1) ingredients[index] = fresh;
      }

      quantityController.clear();
      unitCostController.clear();
      notesController.clear();

      await onGetMovements(silent: true);

      ToastWidget.show(
        message: 'Movement recorded successfully'.tr,
        type: ToastType.success,
      );
    } catch (e) {
      _handleSaveError(e);
    } finally {
      isSaving.value = false;
    }
  }
}