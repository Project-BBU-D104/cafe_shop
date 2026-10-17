import 'package:flutter/material.dart';
import 'package:frontend/controllers/product_variant_controller.dart';
import 'package:get/get.dart';

class EditProductVariantWidget extends StatelessWidget {
  final int variantId;
  EditProductVariantWidget({super.key, required this.variantId});

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
                    'Edit Variant'.tr,
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

              // Variant Name
              _buildLabel('Variant Name'.tr),
              const SizedBox(height: 5),

              TextFormField(
                controller: ctr.variantNameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Enter Variant Name'.tr,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.coffee_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Variant Name is required'.tr;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Price
              _buildLabel('Price'.tr),
              const SizedBox(height: 5),

              TextFormField(
                controller: ctr.variantPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'Enter Price'.tr,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return 'Price is required'.tr;
                  }

                  final number = double.tryParse(text);

                  if (number == null || number < 0) {
                    return 'Enter a valid non-negative number'.tr;
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Availability Status
              Obx(
                () => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Available'.tr),
                  value: ctr.isAvailableController.value,
                  onChanged: (value) {
                    ctr.isAvailableController.value = value;
                  },
                ),
              ),

              // Default Status
              Obx(
                () => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Default'.tr),
                  value: ctr.isDefaultController.value,
                  onChanged: (value) {
                    ctr.isDefaultController.value = value;
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
                              ctr.onUpdateVariant(
                                variantId
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
