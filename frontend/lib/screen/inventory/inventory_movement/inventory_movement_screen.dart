import 'package:flutter/material.dart';
import 'package:frontend/controllers/inventory_movement_controller.dart';
import 'package:frontend/utils/date_formatter.dart';
import 'package:frontend/widget/custom_app_bar.dart';
import 'package:get/get.dart';

class InventoryMovementScreen extends StatelessWidget {
  InventoryMovementScreen({super.key});

  final InventoryMovementController ctr =
      Get.put(InventoryMovementController());

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // order_consumption is written by the API only, never from this form.
  static const Map<String, String> _movementTypes = {
    'stock_in': 'Stock in',
    'stock_out': 'Stock out',
    'adjustment': 'Adjustment',
    'waste': 'Waste',
  };

  @override
  Widget build(BuildContext context) {
    final bool canManage = ctr.canManage;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Inventory Movements',
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: canManage ? _buildForm(context) : _buildNoAccess(),
    );
  }

  Widget _buildForm(BuildContext context) {
    return RefreshIndicator(
      onRefresh: ctr.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Ingredient'.tr),
              const SizedBox(height: 5),
              _buildIngredientField(context),

              const SizedBox(height: 12),

              _buildLabel('Movement Type'.tr),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                initialValue: ctr.movementType.value,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.swap_vert),
                ),
                items: _movementTypes.entries
                    .map(
                      (entry) => DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value.tr),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) ctr.movementType.value = value;
                },
              ),

              const SizedBox(height: 12),

              _buildLabel('Quantity'.tr),
              const SizedBox(height: 5),
              _buildTextField(
                errorKey: 'quantity',
                controller: ctr.quantityController,
                hintText: 'Enter quantity'.tr,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                prefixIcon: const Icon(Icons.numbers),
              ),

              const SizedBox(height: 12),

              _buildLabel('Unit Cost (optional)'.tr),
              const SizedBox(height: 5),
              _buildTextField(
                errorKey: 'unit_cost',
                controller: ctr.unitCostController,
                hintText: 'Enter unit cost'.tr,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.attach_money),
                validator: _validateOptionalAmount,
              ),

              const SizedBox(height: 12),

              _buildLabel('Notes (optional)'.tr),
              const SizedBox(height: 5),
              _buildTextField(
                errorKey: 'notes',
                controller: ctr.notesController,
                hintText: 'Enter notes'.tr,
                prefixIcon: const Icon(Icons.notes),
                maxLines: 3,
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 45,
                child: Obx(
                  () => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    onPressed: ctr.isSaving.value
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              FocusScope.of(context).unfocus();
                              ctr.onSubmit();
                            }
                          },
                    child: ctr.isSaving.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Record Movement'.tr,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _buildLabel('Recent Movements'.tr),
              const SizedBox(height: 8),
              _buildMovementList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMovementList() {
    return Obx(() {
      if (ctr.isLoadingMovements.value && ctr.movements.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (ctr.movements.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'No movements yet'.tr,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        );
      }

      // shortcut: first page only (50 rows, 10 shown); add paging when needed.
      return Column(
        children: ctr.movements.take(10).map(_buildMovementRow).toList(),
      );
    });
  }

  Widget _buildMovementRow(Map<String, dynamic> movement) {
    final String type = (movement['type'] ?? '').toString();
    final dynamic ingredient = movement['ingredient'];

    final String name = ingredient is Map && ingredient['name'] != null
        ? ingredient['name'].toString()
        : '#${movement['ingredient_id']}';
    final String unit =
        ingredient is Map ? (ingredient['unit'] ?? '').toString() : '';

    final String signedQuantity = formatQuantity(
      type,
      (movement['quantity'] ?? '').toString(),
    );

    final String notes = (movement['notes'] ?? '').toString();
    final String typeLabel = _movementTypes[type] ?? type.replaceAll('_', ' ');
    final String date = DateFormatter.formatDateTime(
      DateTime.tryParse((movement['created_at'] ?? '').toString())?.toLocal(),
    );

    final MaterialColor tint = _typeColor(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tint.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_typeIcon(type), color: tint.shade700, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: tint.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeLabel.tr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: tint.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          date,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (notes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$signedQuantity $unit'.trim(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: tint.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The API stores outgoing quantities as positive; the sign comes from the type.
  static String formatQuantity(String type, String raw) {
    final value = double.tryParse(raw);
    if (value == null) return raw;

    const outgoing = {'stock_out', 'waste', 'order_consumption'};
    final signed = outgoing.contains(type) ? -value : value;

    return '${signed > 0 ? '+' : ''}${_trimZeros(signed)}';
  }

  /// "3.500" -> "3.5", "10.000" -> "10".
  static String _trimZeros(double value) =>
      value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');

  static MaterialColor _typeColor(String type) => switch (type) {
        'stock_in' => Colors.green,
        'stock_out' => Colors.blue,
        'adjustment' => Colors.orange,
        'waste' => Colors.brown,
        _ => Colors.blueGrey,
      };

  static IconData _typeIcon(String type) => switch (type) {
        'stock_in' => Icons.arrow_downward,
        'stock_out' => Icons.arrow_upward,
        'adjustment' => Icons.tune,
        'waste' => Icons.delete_outline,
        _ => Icons.swap_vert,
      };

  Widget _buildIngredientField(BuildContext context) {
    return Obx(() {
      final ingredient = ctr.selectedIngredient.value;

      return InkWell(
        onTap: () => _pickIngredient(context),
        child: InputDecorator(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.local_cafe_outlined),
            suffixIcon: Icon(Icons.arrow_drop_down),
          ),
          child: Text(
            ingredient == null
                ? 'Select ingredient'.tr
                : '${ingredient['name']} — ${ingredient['current_stock']} ${ingredient['unit']}',
          ),
        ),
      );
    });
  }

  Future<void> _pickIngredient(BuildContext context) async {
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      builder: (_) => _IngredientPicker(ctr: ctr),
    );

    if (picked != null) {
      ctr.selectedIngredient.value = picked;
    }
  }

  Widget _buildNoAccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'You do not have access to inventory movements'.tr,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
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

  // Server stays authoritative on precision (decimal:0,4) and the max.
  String? _validateOptionalAmount(String? value) {
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
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Obx(() => TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
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

class _IngredientPicker extends StatefulWidget {
  const _IngredientPicker({required this.ctr});

  final InventoryMovementController ctr;

  @override
  State<_IngredientPicker> createState() => _IngredientPickerState();
}

class _IngredientPickerState extends State<_IngredientPicker> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _search,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search ingredient'.tr,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Flexible(
              child: Obx(() {
                // Keep the sheet live so it fills in when the load lands.
                if (widget.ctr.isLoading.value &&
                    widget.ctr.ingredients.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final keyword = _search.text.trim().toLowerCase();
                final items = widget.ctr.selectableIngredients.where(
                  (ingredient) {
                    return (ingredient['name'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(keyword);
                  },
                ).toList();

                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('No ingredients found'.tr),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final ingredient = items[index];

                    return ListTile(
                      title: Text((ingredient['name'] ?? '').toString()),
                      subtitle: Text(
                        '${ingredient['current_stock']} ${ingredient['unit']}',
                      ),
                      onTap: () => Navigator.pop(context, ingredient),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}