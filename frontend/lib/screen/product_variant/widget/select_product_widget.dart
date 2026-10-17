import 'package:flutter/material.dart';
import 'package:frontend/controllers/product_variant_controller.dart';
import 'package:frontend/utils/helper.dart';
import 'package:get/get.dart';

class SelectProductWidget extends StatelessWidget {
  SelectProductWidget({super.key});

  final ProductVariantController ctr = Get.find<ProductVariantController>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Product'.tr,
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

          Obx(() {
            if (ctr.isLoading.value && ctr.productsForSelect.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (ctr.productsForSelect.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No products found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            }

            return SizedBox(
              // shortcut: fixed 400dp list height, overflows on landscape phones;
              // clamp to viewport if landscape/tablet use matters.
              height: 400,
              child: ListView.builder(
                itemCount: ctr.productsForSelect.length,
                itemBuilder: (context, index) {
                  final product = ctr.productsForSelect[index];

                  final bool isAvailable =
                      asBool(product['isAvailable'] ?? product['is_available']);

                  return ListTile(
                    title: Text((product['name'] ?? '').toString()),
                    subtitle: Text(isAvailable ? 'Available' : 'Unavailable'),
                    onTap: () => ctr.onProductSelected(product),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
