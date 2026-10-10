
import 'package:flutter/material.dart';
import 'package:frontend/controllers/category_controller.dart';
import 'package:frontend/screen/category/widget/card_category_widget.dart';
import 'package:frontend/widget/custom_app_bar.dart';
import 'package:frontend/widget/search_widget.dart';
import 'package:get/get.dart';

class CategoryScreen extends StatelessWidget {
  CategoryScreen({super.key});

  final CategoryController cateCtr = Get.put(CategoryController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Category Management',
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: RefreshIndicator(
        onRefresh: cateCtr.onGetCategories,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                SearchWidget(
                  title: 'Search Category',
                ),
                const SizedBox(height: 12),
                Obx(() {
                  if (cateCtr.isLoading.value &&
                      cateCtr.categoriesList.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (cateCtr.categoriesList.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No categories found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
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
                        onEdit: () {
                          cateCtr.onEditCategory(context,category['id']);
                        },
                        onDelete: () {
                          cateCtr.onDeleteCategory(category['id'], context);
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
          cateCtr.onAddCategory(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
