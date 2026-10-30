import 'package:flutter/material.dart';
import 'package:frontend/controllers/inventory_movement_controller.dart';
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
      onRefresh: ctr.onGetIngredients,
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
            ],
          ),
        ),
      ),
    );
  }

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