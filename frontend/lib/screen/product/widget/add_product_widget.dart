import 'package:flutter/material.dart';
import 'package:frontend/services/main_service/category_service.dart';
import 'package:frontend/services/main_service/product_service.dart';
import 'package:frontend/widget/toast_widget.dart';
import 'package:get/get.dart';

class AddProductWidget extends StatefulWidget {
  const AddProductWidget({super.key, required this.onSaved, this.product});

  final Future<void> Function() onSaved;
  final Map<String, dynamic>? product;

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
    _nameController.text = (widget.product?['name'] ?? '').toString();
    _descriptionController.text =
        (widget.product?['description'] ?? '').toString();
    _categoryId = int.tryParse(
      '${widget.product?['categoryId'] ?? widget.product?['category_id'] ?? ''}',
    );
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
      final productId = int.tryParse('${widget.product?['id'] ?? ''}');
      if (productId == null) {
        await _productService.createProduct({
          ...data,
          'is_available': true,
          'sort_order': 0,
        });
      } else {
        await _productService.updateProduct(productId, data);
      }
      await widget.onSaved();
      if (mounted) Navigator.of(context).pop();
      ToastWidget.show(
        message: productId == null
            ? 'Product added successfully'
            : 'Product updated successfully',
      );
    } catch (e) {
      ToastWidget.show(
        message: 'Failed to ${widget.product == null ? 'add' : 'update'} product: $e',
        type: ToastType.error,
      );
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
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                (widget.product == null ? 'Add Product' : 'Edit Product').tr,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Product Name'.tr),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Product Name is required'.tr
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'.tr),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              if (_loadingCategories)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<int>(
                  value: _categoryId,
                  decoration: InputDecoration(labelText: 'Category'.tr),
                  items: _categories.map((category) {
                    final id = int.tryParse('${category['id']}');
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text('${category['name'] ?? ''}'),
                    );
                  }).where((item) => item.value != null).toList(),
                  onChanged: (value) => setState(() => _categoryId = value),
                  validator: (value) => value == null ? 'Select a category'.tr : null,
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving || _loadingCategories || _categories.isEmpty
                    ? null
                    : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text((widget.product == null ? 'Save Product' : 'Update Product').tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
