import 'package:flutter/material.dart';
import 'package:frontend/controllers/ingredient_controller.dart';
import 'package:get/get.dart';

/// One form for adding and editing ingredients, shown in a bottom sheet.
class IngredientFormWidget extends StatelessWidget {
  IngredientFormWidget({
    super.key,
    required this.title,
    required this.onSave,
    this.showCurrentStock = true,
  });

  final String title;
  final Future<void> Function() onSave;

  /// New ingredients set their opening stock here. Later stock changes go
  /// through the inventory-movement endpoint so the ledger stays accurate.
  final bool showCurrentStock;

  final IngredientController ctr = Get.find<IngredientController>();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title.tr,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              _buildLabel('Ingredient Name'.tr),
              const SizedBox(height: 5),
              _buildTextField(
                errorKey: 'name',
                controller: ctr.nameController,
                hintText: 'Enter Ingredient Name'.tr,
                prefixIcon: const Icon(Icons.local_cafe_outlined),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingredient Name is required'.tr;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              _buildLabel('Unit'.tr),
              const SizedBox(height: 5),
              _buildTextField(
                errorKey: 'unit',
                controller: ctr.unitController,
                hintText: 'e.g. kg, L, pcs'.tr,
                prefixIcon: const Icon(Icons.straighten),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Unit is required'.tr;
                  }
                  if (text.length > 32) {
                    return 'Unit is too long'.tr;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              if (showCurrentStock) ...[
                _buildLabel('Current Stock'.tr),
                const SizedBox(height: 5),
                _buildTextField(
                  errorKey: 'current_stock',
                  controller: ctr.currentStockController,
                  hintText: 'Enter Current Stock'.tr,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: const Icon(Icons.inventory_outlined),
                  validator: _validateAmount,
                ),
                const SizedBox(height: 12),
              ],

              _buildLabel('Minimum Stock'.tr),
              const SizedBox(height: 5),
              _buildTextField(
                errorKey: 'minimum_stock',
                controller: ctr.minimumStockController,
                hintText: 'Enter Minimum Stock'.tr,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.warning_amber_rounded),
                validator: _validateAmount,
              ),

              const SizedBox(height: 12),

              _buildLabel('Cost per Unit'.tr),
              const SizedBox(height: 5),
              _buildTextField(
                errorKey: 'cost_per_unit',
                controller: ctr.costPerUnitController,
                hintText: 'Enter Cost per Unit'.tr,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.attach_money),
                validator: _validateAmount,
              ),

              const SizedBox(height: 12),

              // Active Status
              Obx(
                () => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Active'.tr),
                  subtitle: Text(
                    ctr.isActiveController.value
                        ? 'Ingredient is active'.tr
                        : 'Ingredient is inactive'.tr,
                  ),
                  value: ctr.isActiveController.value,
                  onChanged: (value) {
                    ctr.isActiveController.value = value;
                  },
                ),
              ),

              const SizedBox(height: 15),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 45,
                child: Obx(
                  () => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    onPressed: ctr.isLoading.value
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              FocusScope.of(context).unfocus();
                              onSave();
                            }
                          },
                    child: ctr.isLoading.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save'.tr,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    );
  }

  // Optional amount: server stays authoritative on precision (decimal:0,3 / 0,4).
  String? _validateAmount(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    final number = double.tryParse(text);

    if (number == null || number < 0) {
      return 'Enter a valid non-negative number'.tr;
    }

    return null;
  }

  Widget _buildTextField({
    required String errorKey,
    required TextEditingController controller,
    required String hintText,
    required Widget prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Obx(() => TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: hintText,
            // Last 422 message for this field, if the API rejected it.
            errorText: ctr.serverErrors[errorKey],
            border: const OutlineInputBorder(),
            prefixIcon: prefixIcon,
          ),
          onChanged: (_) => ctr.serverErrors.remove(errorKey),
          validator: validator,
        ));
  }
}