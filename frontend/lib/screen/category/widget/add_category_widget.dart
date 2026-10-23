import 'package:flutter/material.dart';
import 'package:frontend/controllers/category_controller.dart';
import 'package:get/get.dart';

class AddCategoryWidget extends StatelessWidget {
  AddCategoryWidget({super.key});

  final CategoryController ctr = Get.find<CategoryController>();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Category'.tr,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Create a category for your products.'.tr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close'.tr,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              _buildLabel(context, 'Category Name'.tr),
              const SizedBox(height: 5),

              TextFormField(
                controller: ctr.cateNameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Enter Category Name'.tr,
                  border: _categoryInputBorder(context),
                  enabledBorder: _categoryInputBorder(context),
                  focusedBorder: _categoryInputBorder(context, focused: true),
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Category Name is required'.tr;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              _buildLabel(context, 'Description'.tr),
              const SizedBox(height: 5),

              TextFormField(
                controller: ctr.cateDescController,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Enter Description'.tr,
                  border: _categoryInputBorder(context),
                  enabledBorder: _categoryInputBorder(context),
                  focusedBorder: _categoryInputBorder(context, focused: true),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 12),

              _buildLabel(context, 'Sort Order'.tr),
              const SizedBox(height: 5),

              TextFormField(
                controller: ctr.cateSortOrderController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'Enter Sort Order'.tr,
                  border: _categoryInputBorder(context),
                  enabledBorder: _categoryInputBorder(context),
                  focusedBorder: _categoryInputBorder(context, focused: true),
                  prefixIcon: const Icon(Icons.sort),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return null; // Empty defaults to 0
                  }

                  final number = int.tryParse(text);

                  if (number == null || number < 0) {
                    return 'Enter a valid non-negative number'.tr;
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              Obx(
                () => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Text('Active'.tr),
                    subtitle: Text(
                      ctr.isActiveController.value
                          ? 'Category is active'.tr
                          : 'Category is inactive'.tr,
                    ),
                    value: ctr.isActiveController.value,
                    onChanged: (value) {
                      ctr.isActiveController.value = value;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 45,
                child: Obx(
                  () => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: const Color(0xFF102A43),
                      backgroundColor: const Color(0xFF90CAF9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: ctr.isLoading.value
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              FocusScope.of(context).unfocus();
                              ctr.onSaveCategory();
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

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  OutlineInputBorder _categoryInputBorder(
    BuildContext context, {
    bool focused = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: focused ? colorScheme.primary : colorScheme.outlineVariant,
        width: focused ? 1.5 : 1,
      ),
    );
  }
}
