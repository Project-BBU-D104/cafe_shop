import 'package:flutter/material.dart';
import 'package:frontend/controllers/category_controller.dart';
import 'package:frontend/screen/category/widget/card_category_widget.dart';
import 'package:frontend/widget/custom_app_bar.dart';
import 'package:frontend/widget/search_widget.dart';
import 'package:get/get.dart';

class CategoryScreen extends StatelessWidget {
  CategoryScreen({super.key});

  final cateCtr = Get.put(CategoryController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Category Management',
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Column(
              children: [
                SearchWidget(
                  title: 'Search Category',
                ),
                
                SizedBox(height: 12),
                
                CardCategoryWidget(
                  name: 'Coffee',
                  description: 'All coffee products',
                  sortOrder: 1,
                  isActive: true,
                  onEdit: () {
                    print('Edit Coffee');
                  },
                  onDelete: () {
                    print('Delete Coffee');
                  },
                ),
                CardCategoryWidget(
                  name: 'Coffee',
                  description: 'All coffee products',
                  sortOrder: 1,
                  isActive: true,
                  onEdit: () {
                    print('Edit Coffee');
                  },
                  onDelete: () {
                    print('Delete Coffee');
                  },
                ),
                CardCategoryWidget(
                  name: 'Coffee',
                  description: 'All coffee products',
                  sortOrder: 1,
                  isActive: true,
                  onEdit: () {
                    print('Edit Coffee');
                  },
                  onDelete: () {
                    print('Delete Coffee');
                  },
                ),
                CardCategoryWidget(
                  name: 'Coffee',
                  description: 'All coffee products',
                  sortOrder: 1,
                  isActive: true,
                  onEdit: () {
                    print('Edit Coffee');
                  },
                  onDelete: () {
                    print('Delete Coffee');
                  },
                ),
                CardCategoryWidget(
                  name: 'Coffee',
                  description: 'All coffee products',
                  sortOrder: 1,
                  isActive: true,
                  onEdit: () {
                    print('Edit Coffee');
                  },
                  onDelete: () {
                    print('Delete Coffee');
                  },
                ),
                CardCategoryWidget(
                  name: 'Coffee',
                  description: 'All coffee products',
                  sortOrder: 1,
                  isActive: true,
                  onEdit: () {
                    print('Edit Coffee');
                  },
                  onDelete: () {
                    print('Delete Coffee');
                  },
                ),
                CardCategoryWidget(
                  name: 'Coffee',
                  description: 'All coffee products',
                  sortOrder: 1,
                  isActive: true,
                  onEdit: () {
                    print('Edit Coffee');
                  },
                  onDelete: () {
                    print('Delete Coffee');
                  },
                ),
                CardCategoryWidget(
                  name: 'Coffee',
                  description: 'All coffee products',
                  sortOrder: 1,
                  isActive: true,
                  onEdit: () {
                    print('Edit Coffee');
                  },
                  onDelete: () {
                    print('Delete Coffee');
                  },
                ),
                CardCategoryWidget(
                  name: 'Coffee',
                  description: 'All coffee products',
                  sortOrder: 1,
                  isActive: true,
                  onEdit: () {
                    print('Edit Coffee');
                  },
                  onDelete: () {
                    print('Delete Coffee');
                  },
                ),
                CardCategoryWidget(
                  name: 'Coffee',
                  description: 'All coffee products',
                  sortOrder: 1,
                  isActive: true,
                  onEdit: () {
                    print('Edit Coffee');
                  },
                  onDelete: () {
                    print('Delete Coffee');
                  },
                ),
              ]
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add)
      ),
    );
  }
}