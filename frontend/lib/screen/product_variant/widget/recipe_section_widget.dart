import 'package:flutter/material.dart';
import 'package:frontend/controllers/product_variant_controller.dart';
import 'package:get/get.dart';

/// Collapsible recipe list for one variant; only built for roles that may edit.
class RecipeSectionWidget extends StatelessWidget {
  RecipeSectionWidget({super.key, required this.variantId});

  final int variantId;
  final ProductVariantController ctr = Get.find<ProductVariantController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool expanded = ctr.isRecipeExpanded(variantId);
      final List<Map<String, dynamic>> rows = ctr.recipeFor(variantId);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 20),
          InkWell(
            onTap: () => ctr.onToggleRecipe(variantId),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Recipe'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            if (ctr.isRecipeLoading(variantId))
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No ingredients bound yet'.tr,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              )
            else
              ...rows.map((row) => _buildRow(context, row)),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => ctr.onAddRecipeIngredient(context, variantId),
                icon: const Icon(Icons.add, size: 18),
                label: Text('Add ingredient'.tr),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildRow(BuildContext context, Map<String, dynamic> row) {
    final ingredient = row['ingredient'];
    final String name = ingredient is Map
        ? (ingredient['name'] ?? '').toString()
        : 'Ingredient ${row['ingredient_id']}';
    final String unit = (row['unit'] ?? '').toString();
    final String quantity = _trimZeros((row['quantity'] ?? '').toString());
    final int? ingredientId = int.tryParse(
      (row['ingredient_id'] ?? '').toString(),
    );

    return InkWell(
      onTap: () => ctr.onEditRecipeIngredient(context, variantId, row),
      child: Padding(
        padding: const EdgeInsets.only(left: 26),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$quantity $unit',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.red,
              ),
              visualDensity: VisualDensity.compact,
              tooltip: 'Remove'.tr,
              onPressed: ingredientId == null
                  ? null
                  : () => ctr.onRemoveRecipeIngredient(
                      context,
                      variantId,
                      ingredientId,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// "150.000" -> "150", "0.500" -> "0.5" (the API sends decimals as strings).
  String _trimZeros(String value) {
    if (!value.contains('.')) return value;

    return value
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
