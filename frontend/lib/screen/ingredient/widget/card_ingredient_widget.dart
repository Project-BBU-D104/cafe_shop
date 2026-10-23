
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CardIngredientWidget extends StatelessWidget {
  final Map<String, dynamic> ingredient;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CardIngredientWidget({
    super.key,
    required this.ingredient,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String name =
        (ingredient['name'] ?? '').toString();

    final String unit =
        (ingredient['unit'] ?? '').toString();

    final String currentStock =
        (ingredient['current_stock'] ?? ingredient['currentStock'] ?? '0')
            .toString();

    final String minimumStock =
        (ingredient['minimum_stock'] ?? ingredient['minimumStock'] ?? '0')
            .toString();

    final dynamic costValue =
        ingredient['cost_per_unit'] ?? ingredient['costPerUnit'];

    final dynamic activeValue =
        ingredient['isActive'] ?? ingredient['is_active'];

    final bool isActive =
        activeValue == true ||
        activeValue == 1 ||
        activeValue == '1' ||
        activeValue == 'true';

    final dynamic lowValue =
        ingredient['is_low_stock'] ?? ingredient['isLowStock'];

    final bool isLowStock =
        lowValue == true ||
        lowValue == 1 ||
        lowValue == '1' ||
        lowValue == 'true';

    final bool canEdit = onEdit != null || onDelete != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEE8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: const Color(0xff35180C),
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Unnamed ingredient' : name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Stock: $currentStock $unit (min $minimumStock $unit)',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isActive ? 'Active'.tr : 'Inactive'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                      if (isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Low stock'.tr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      Text(
                        costValue == null || costValue.toString().isEmpty
                            ? 'No cost set'
                            : 'Cost: $costValue / $unit',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (canEdit)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit?.call();
                  } else if (value == 'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 20),
                          const SizedBox(width: 10),
                          Text('Edit'.tr),
                        ],
                      ),
                    ),
                  if (onDelete != null)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Delete'.tr,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
