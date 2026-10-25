import 'package:flutter/material.dart';
import 'package:frontend/controllers/product_variant_controller.dart';
import 'package:get/get.dart';

/// One form for adding a recipe ingredient or editing its quantity.
class RecipeFormWidget extends StatelessWidget {
  RecipeFormWidget({
    super.key,
    required this.title,
    required this.variantId,
    this.isEdit = false,
    this.ingredientName = '',
    this.unit = '',
  });

  final String title;
  final int variantId;

  /// Edit only changes the quantity: the ingredient and its unit are fixed.
  final bool isEdit;
  final String ingredientName;
  final String unit;

  final ProductVariantController ctr = Get.find<ProductVariantController>();

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

              Text(
                'Ingredient'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              if (isEdit)
                InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_cafe_outlined),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    ingredientName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                )
              else
                _buildIngredientDropdown(),

              const SizedBox(height: 12),

              Text(
                'Quantity'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              _buildQuantityField(),

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
                              ctr.onSaveRecipeIngredient(
                                variantId,
                                ingredientId: isEdit
                                    ? ctr.recipeIngredientId.value
                                    : null,
                              );
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

  Widget _buildIngredientDropdown() {
    return Obx(() {
      final available = ctr.availableRecipeIngredients(variantId);
      final int? selected = ctr.recipeIngredientId.value;

      return InputDecorator(
        decoration: InputDecoration(
          errorText: ctr.recipeServerErrors['ingredient_id'],
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.local_cafe_outlined),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: available.any((i) => i['id'] == selected) ? selected : null,
            isExpanded: true,
            isDense: true,
            hint: Text('Select ingredient'.tr),
            items: available.map((ingredient) {
              final int id = int.parse('${ingredient['id']}');

              return DropdownMenuItem<int>(
                value: id,
                child: Text('${ingredient['name']} (${ingredient['unit']})'),
              );
            }).toList(),
            onChanged: (value) {
              ctr.recipeIngredientId.value = value;
              ctr.recipeServerErrors.remove('ingredient_id');
            },
          ),
        ),
      );
    });
  }

  Widget _buildQuantityField() {
    return Obx(() {
      // Add mode reads the unit off the picked ingredient; edit mode has it.
      final String suffix = isEdit
          ? unit
          : (ctr.selectedRecipeIngredient?['unit'] ?? '').toString();

      return TextFormField(
        controller: ctr.recipeQuantityController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: 'e.g. 18'.tr,
          // Last 422 message for this field, if the API rejected it.
          errorText: ctr.recipeServerErrors['quantity'],
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.scale_outlined),
          suffixText: suffix.isEmpty ? null : suffix,
        ),
        onChanged: (_) => ctr.recipeServerErrors.remove('quantity'),
        validator: ProductVariantController.validateRecipeQuantity,
      );
    });
  }
}
