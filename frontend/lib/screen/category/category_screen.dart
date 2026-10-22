import 'package:flutter/material.dart';
import 'package:frontend/controllers/category_controller.dart';
import 'package:frontend/screen/category/category_management_theme.dart';
import 'package:frontend/screen/category/widget/card_category_widget.dart';
import 'package:frontend/widget/custom_app_bar.dart';
import 'package:frontend/widget/search_widget.dart';
import 'package:get/get.dart';

class CategoryScreen extends StatelessWidget {
  CategoryScreen({super.key});

  final CategoryController cateCtr = Get.put(CategoryController());

  @override
  Widget build(BuildContext context) {
    return CategoryManagementTheme(
      child: Builder(
        builder: (categoryContext) => Scaffold(
          appBar: CustomAppBar(
            title: 'Category Management',
            showBack: true,
            onBack: () => Navigator.pop(categoryContext),
          ),
          body: RefreshIndicator(
            onRefresh: cateCtr.onGetCategories,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    SearchWidget(title: 'Search Category'),
                    const SizedBox(height: 12),
                    Obx(() {
                      if (cateCtr.isLoading.value &&
                          cateCtr.categoriesList.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (cateCtr.categoriesList.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Obx(() {
                              final error = cateCtr.errorMessage.value;
                              return Text(
                                error ?? 'No categories found',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: error == null
                                      ? Colors.grey
                                      : Colors.red,
                                ),
                              );
                            }),
                          ),
                        );
                      }

                      if (cateCtr.searchCategoryList.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'Search not found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: cateCtr.searchCategoryList.map((category) {
                          return CardCategoryWidget(
                            category: category,
                            onTap: () =>
                                _showCategoryDetails(categoryContext, category),
                            onEdit: () {
                              cateCtr.onEditCategory(
                                categoryContext,
                                category['id'],
                              );
                            },
                            onDelete: () {
                              cateCtr.onDeleteCategory(
                                category['id'],
                                categoryContext,
                              );
                            },
                          );
                        }).toList(),
                      );
                    }),
                    const SizedBox(height: 70),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              cateCtr.onAddCategory(categoryContext);
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  void _showCategoryDetails(
    BuildContext context,
    Map<String, dynamic> category,
  ) {
    final name = (category['name'] ?? '').toString();
    final description = (category['description'] ?? '').toString();
    final isActive = category['is_active'] == true;
    final sortOrder = category['sort_order'] ?? 0;
    final createdAt = category['created_at']?.toString();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Category'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(context, 'Category Name'.tr, name),
            _detailRow(
              context,
              'Description'.tr,
              description.isEmpty ? '-' : description,
            ),
            _detailRow(
              context,
              'Status'.tr,
              isActive ? 'Active'.tr : 'Inactive'.tr,
            ),
            _detailRow(context, 'Sort Order'.tr, sortOrder.toString()),
            if (createdAt != null) _detailRow(context, 'Created'.tr, createdAt),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
