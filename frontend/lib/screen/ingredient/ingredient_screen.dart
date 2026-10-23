import 'package:flutter/material.dart';
import 'package:frontend/controllers/ingredient_controller.dart';
import 'package:frontend/screen/ingredient/widget/card_ingredient_widget.dart';
import 'package:frontend/widget/custom_app_bar.dart';
import 'package:frontend/widget/search_widget.dart';
import 'package:get/get.dart';

class IngredientScreen extends StatelessWidget {
  IngredientScreen({super.key});

  final IngredientController ingCtr = Get.put(IngredientController());

  @override
  Widget build(BuildContext context) {
    // Read once: canManage decrypts storage, so don't call it per card.
    final bool canManage = ingCtr.canManage;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Ingredient Management'.tr,
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: RefreshIndicator(
        onRefresh: ingCtr.onGetIngredients,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                if (canManage)
                  SearchWidget(
                    title: 'Search Ingredient',
                  ),
                const SizedBox(height: 12),
                Obx(() {
                  if (!canManage) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'You do not have access to ingredients'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  }

                  if (ingCtr.isLoading.value &&
                      ingCtr.ingredientsList.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (ingCtr.ingredientsList.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No ingredients found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  }

                  if (ingCtr.searchIngredientList.isEmpty) {
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
                    children: ingCtr.searchIngredientList.map((ingredient) {
                      return CardIngredientWidget(
                        ingredient: ingredient,
                        onEdit: canManage
                            ? () {
                                ingCtr.onEditIngredient(context, ingredient['id']);
                              }
                            : null,
                        onDelete: canManage
                            ? () {
                                ingCtr.onDeleteIngredient(ingredient['id'], context);
                              }
                            : null,
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
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () {
                ingCtr.onAddIngredient(context);
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}