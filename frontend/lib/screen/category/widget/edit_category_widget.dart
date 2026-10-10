
import 'package:flutter/material.dart';
import 'package:frontend/constants/constant.dart';
import 'package:frontend/controllers/category_controller.dart';
import 'package:get/get.dart';

class EditCategoryWidget extends StatelessWidget {
  final int categoryId;
  EditCategoryWidget({super.key, required this.categoryId});

  final CategoryController ctr = Get.find<CategoryController>();

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
                    'Add Category'.tr,
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

              // Category Name
              _buildLabel('Category Name'.tr),
              const SizedBox(height: 5),

              TextFormField(
                controller: ctr.cateNameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Enter Category Name'.tr,
                  border: const OutlineInputBorder(),
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

              // Description
              _buildLabel('Description'.tr),
              const SizedBox(height: 5),

              TextFormField(
                controller: ctr.cateDescController,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Enter Description'.tr,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 12),

              // Sort Order
              _buildLabel('Sort Order'.tr),
              const SizedBox(height: 5),

              TextFormField(
                controller: ctr.cateSortOrderController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'Enter Sort Order'.tr,
                  border: const OutlineInputBorder(),
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

              // Active Status
              Obx(
                () => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
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

              const SizedBox(height: 15),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 45,
                child: Obx(
                  () => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: successColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: ctr.isLoading.value
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              FocusScope.of(context).unfocus();
                              ctr.onUpdateCategory(
                                categoryId
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    );
  }
}
