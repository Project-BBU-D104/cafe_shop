import 'package:flutter/material.dart';
import 'package:frontend/services/main_service/category_service.dart';
import 'package:frontend/services/main_service/product_service.dart';
import 'package:frontend/widget/toast_widget.dart';
import 'package:get/get.dart';

class AddProductWidget extends StatefulWidget {
  const AddProductWidget({super.key, required this.onSaved});

  final Future<void> Function() onSaved;

  @override
  State<AddProductWidget> createState() => _AddProductWidgetState();
}

class _AddProductWidgetState extends State<AddProductWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryService = CategoryService();
  final _productService = ProductService();
  List<Map<String, dynamic>> _categories = [];
  int? _categoryId;
  bool _loadingCategories = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _categoryService.getCategories();
      final data = response is Map ? response['data'] : null;
      if (data is List) {
        _categories = data
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    } catch (_) {
      if (mounted) {
        ToastWidget.show(message: 'Failed to load categories', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'category_id': _categoryId,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
      };
      await _productService.createProduct({
        ...data,
        'is_available': true,
        'sort_order': 0,
      });
      await widget.onSaved();
      if (mounted) Navigator.of(context).pop();
      ToastWidget.show(message: 'Product added successfully');
    } catch (e) {
      ToastWidget.show(message: 'Failed to add product: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
    );
    final fieldFill = const Color(0xFFFFF8F2);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  Padding(
                    padding: EdgeInsets.zero,
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE9D8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.coffee_outlined,
                            color: Color(0xFF8B5E3C),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Product'.tr,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF34271F),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Create a product for your coffee shop.'.tr,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close'.tr,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _nameField(border, focusedBorder, fieldFill),
                            const SizedBox(height: 12),
                            _categoryField(border, focusedBorder, fieldFill),
                            const SizedBox(height: 12),
                            _fieldLabel(context, 'Description'.tr),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _descriptionController,
                              minLines: 3,
                              maxLines: 4,
                              textInputAction: TextInputAction.newline,
                              decoration: _decoration(
                                hint: 'Add details about this product'.tr,
                                border: border,
                                focusedBorder: focusedBorder,
                                fill: fieldFill,
                                icon: Icons.notes_rounded,
                              ).copyWith(alignLabelWithHint: true),
                            ),
                          ],
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: const Color(0xFF102A43),
                          backgroundColor: const Color(0xFF90CAF9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed:
                            _saving || _loadingCategories || _categories.isEmpty
                            ? null
                            : _save,
                        child: _saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                          'Save Product'.tr,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
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

  Widget _nameField(
    OutlineInputBorder border,
    OutlineInputBorder focusedBorder,
    Color fill,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(context, 'Product Name'.tr),
        const SizedBox(height: 6),
        TextFormField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          decoration: _decoration(
            hint: 'Enter product name'.tr,
            border: border,
            focusedBorder: focusedBorder,
            fill: fill,
            icon: Icons.inventory_2_outlined,
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Product Name is required'.tr
              : null,
        ),
      ],
    );
  }

  Widget _categoryField(
    OutlineInputBorder border,
    OutlineInputBorder focusedBorder,
    Color fill,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(context, 'Category'.tr),
        const SizedBox(height: 6),
        if (_loadingCategories)
          const SizedBox(
            height: 56,
            child: Center(child: CircularProgressIndicator()),
          )
        else
          DropdownButtonFormField<int>(
            value: _categoryId,
            isExpanded: true,
            decoration: _decoration(
              hint: 'Select a category'.tr,
              border: border,
              focusedBorder: focusedBorder,
              fill: fill,
              icon: Icons.category_outlined,
            ),
            items: _categories.map((category) {
              final id = int.tryParse('${category['id']}');
              return DropdownMenuItem<int>(
                value: id,
                child: Text(
                  '${category['name'] ?? ''}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).where((item) => item.value != null).toList(),
            onChanged: (value) => setState(() => _categoryId = value),
            validator: (value) =>
                value == null ? 'Select a category'.tr : null,
          ),
      ],
    );
  }

  Widget _fieldLabel(BuildContext context, String text) => Text(
    text,
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: const Color(0xFF34271F),
    ),
  );

  InputDecoration _decoration({
    required String hint,
    required OutlineInputBorder border,
    required OutlineInputBorder focusedBorder,
    required Color fill,
    required IconData icon,
  }) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 20),
    filled: true,
    fillColor: fill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border,
    enabledBorder: border,
    focusedBorder: focusedBorder,
  );
}
